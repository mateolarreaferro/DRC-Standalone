import { primaryContent, type Artifact } from '../stores/artifactStore'
import { usePlaybackStore } from '../stores/playbackStore'
import { useSessionStore } from '../stores/sessionStore'
import { prepareCsdForOfflineRender } from '../../shared/csd-offline-prepare'
import { prepareCsdForWebappCompile } from '../../shared/csd-webapp-prepare'

export interface PlayArtifactOptions {
  /** False when replaying after an auto-fix (no second auto-fix). */
  allowAutofix?: boolean
}

// One auto-fix attempt per artifact — prevents compile→fix→play→fail→fix loops.
const autofixAttempts = new Map<string, number>()
const AUTOFIX_LIMIT = 1

/** Prepare CSD for offline WAV render (strips realtime flags, injects demo score if needed). */
export function prepareCsdForWavRender(csd: string): string {
  return prepareCsdForOfflineRender(csd)
}

export function resetAutofix(sessionID: string | null): void {
  if (sessionID) autofixAttempts.clear()
  const session = useSessionStore.getState()
  session.setLastFailure(null)
  session.setPendingAutofixArtifactId(null)
}

export async function compileCheckCsd(
  csd: string,
): Promise<{ ok: boolean; error?: string }> {
  if (!window.api?.csound) return { ok: true }
  try {
    const { path } = await window.api.csound.writeCsd(prepareCsdForWavRender(csd))
    const res = await window.api.csound.compile(path)
    return res.success ? { ok: true } : { ok: false, error: String(res.error ?? 'compile failed') }
  } catch (err: any) {
    return { ok: false, error: String(err?.message ?? err) }
  }
}

export async function compileCheckWebappCsd(
  csd: string,
): Promise<{ ok: boolean; error?: string }> {
  if (!window.api?.csound) return { ok: true }
  try {
    const { path } = await window.api.csound.writeCsd(prepareCsdForWebappCompile(csd))
    const res = await window.api.csound.compile(path)
    return res.success ? { ok: true } : { ok: false, error: String(res.error ?? 'compile failed') }
  } catch (err: any) {
    return { ok: false, error: String(err?.message ?? err) }
  }
}

export async function playArtifact(
  artifact: Artifact,
  opts: PlayArtifactOptions = {},
): Promise<void> {
  const allowAutofix = opts.allowAutofix !== false
  if (!window.api?.csound) return
  if (artifact.type === 'webapp') return
  const store = usePlaybackStore.getState()
  store.set({ artifactId: artifact.id, status: 'compiling', message: 'Rendering with Csound…' })

  try {
    const { path } = await window.api.csound.writeCsd(prepareCsdForWavRender(primaryContent(artifact)))
    const compile = await window.api.csound.compile(path)
    if (!compile.success) {
      const errMsg = String(compile.error ?? '').slice(0, 300)
      usePlaybackStore.getState().set({
        status: 'error',
        message: `Compile error: ${errMsg}`,
      })
      useSessionStore.getState().setLastFailure({
        errorRaw: errMsg,
        brokenCsd: primaryContent(artifact),
        kind: 'compile',
        artifactId: artifact.id,
      })
      if (allowAutofix) void requestAutofix(artifact, errMsg, 'compile')
      return
    }

    usePlaybackStore.getState().set({ status: 'playing', message: 'Playing your sound…' })

    const res = await window.api.csound.play(path)

    const current = usePlaybackStore.getState()
    if (current.artifactId !== artifact.id) return

    if (res.success) {
      const failure = useSessionStore.getState().lastFailure
      const fixedCsd = primaryContent(artifact)
      if (failure && fixedCsd && fixedCsd !== failure.brokenCsd) {
        useSessionStore.getState().sendFeedback('accepted_fix', {
          errorRaw: failure.errorRaw,
          brokenCsd: failure.brokenCsd,
          fixedCsd,
          kind: failure.kind,
        })
        useSessionStore.getState().setLastFailure(null)
        useSessionStore.getState().setPendingAutofixArtifactId(null)
      }
      usePlaybackStore.getState().clear()
    } else {
      const errMsg = String(res.error ?? '').slice(0, 300)
      usePlaybackStore.getState().set({
        status: 'error',
        message: `Error: ${errMsg.slice(0, 160)}`,
      })
      useSessionStore.getState().setLastFailure({
        errorRaw: errMsg,
        brokenCsd: primaryContent(artifact),
        kind: 'runtime',
        artifactId: artifact.id,
      })
      if (allowAutofix) void requestAutofix(artifact, errMsg, 'runtime')
    }
  } catch (err: any) {
    const current = usePlaybackStore.getState()
    if (current.artifactId !== artifact.id) return
    usePlaybackStore.getState().set({
      status: 'error',
      message: `Error: ${err.message}`,
    })
  }
}

export async function stopPlayback(): Promise<void> {
  await window.api?.csound?.stop()
  usePlaybackStore.getState().clear()
}

async function requestAutofix(
  artifact: Artifact,
  errMsg: string,
  kind: 'compile' | 'runtime' = 'compile',
): Promise<void> {
  if (!window.api?.session) return
  const session = useSessionStore.getState()
  if (session.isStreaming) return

  const attempts = autofixAttempts.get(artifact.id) ?? 0
  if (attempts >= AUTOFIX_LIMIT) return
  autofixAttempts.set(artifact.id, attempts + 1)

  session.setPendingAutofixArtifactId(artifact.id)

  usePlaybackStore.getState().set({
    artifactId: artifact.id,
    status: 'compiling',
    message: kind === 'runtime' ? 'Auto-fixing runtime error…' : 'Auto-fixing compile error…',
  })

  const broken = primaryContent(artifact)
  const bellHzTrap =
    /\biFreq\s*=\s*p4\b/i.test(broken) &&
    !/\bcpsmidinn\s*\(\s*p4\s*\)/i.test(broken) &&
    /\b(bell|chime|shimmer|giBellIdx|giFcRatio)\b/i.test(broken)
  const bellHint = bellHzTrap
    ? ' Hint: this bell patch reads p4 as Hz — score p4 must be 300–900 (A4≈440), not MIDI 60–72 (that sounds like sub-bass). Prefer `iFreq = cpsmidinn(p4)` or copy golden `fm_bell_starter.csd`.'
    : ''

  const hint = kind === 'runtime'
    ? `Hint: INIT/PERF errors usually come from rate mismatches at init time. Common traps: \`i(kVar)\` on a k-var that's only written inside the instrument body (reads 0 at init); passing a k-rate ftable index to \`table\` instead of \`tablekt\`; expseg endpoints of 0; unknown opcodes; or silent output from unscheduled instruments / missing \`out\`.${bellHint}`
    : `Hint: "Unable to find opcode entry for '<opcode>' with matching argument types" means wrong-rate args — often \`foscili\` needs SIX args \`(xamp, kcps, xcar, xmod, kndx, ifn)\`, not three. For envelopes use \`linsegr\` with \`p3\`, not \`expseg\` with \`p3 *\` math. Never schedule \`i 99\` without defining \`instr 99\`.${bellHint}`

  const prompt =
    `The CSD you just wrote failed to ${kind === 'runtime' ? 'run' : 'compile'}. Fix it and emit the full corrected <CsoundSynthesizer>…</CsoundSynthesizer> block (one short sentence, then the CSD).\n\n` +
    `${kind === 'runtime' ? 'Runtime' : 'Compiler'} error: ${errMsg}\n\n` +
    hint

  session.addMessage({
    id: `msg_${Date.now()}`,
    role: 'user',
    content: kind === 'runtime' ? 'Fix the runtime error' : 'Fix the compile error',
    timestamp: Date.now(),
  })
  session.setStreaming(true)

  try {
    let activeSid = session.sessionID
    if (!activeSid) {
      const created = await window.api.session.create(session.agentMode)
      activeSid = created.id
      session.setSessionID(activeSid)
    }
    await window.api.session.send(activeSid, prompt)
  } catch (err: any) {
    session.setPendingAutofixArtifactId(null)
    session.addMessage({
      id: `msg_${Date.now()}_e`,
      role: 'assistant',
      content: `Auto-fix failed: ${err.message}`,
      timestamp: Date.now(),
    })
    session.setStreaming(false)
  }
}

/** User message immediately before an assistant turn is an auto-fix request. */
export function isAutofixUserMessage(content: string): boolean {
  return /^Fix the (compile|runtime) error$/i.test(content.trim())
}
