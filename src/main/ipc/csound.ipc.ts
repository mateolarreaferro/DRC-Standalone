import { IpcMain, type WebContents } from 'electron'
import { execFile, spawn, type ChildProcess } from 'child_process'
import { promisify } from 'util'
import { writeFileSync, existsSync, mkdirSync, readFileSync, unlinkSync } from 'fs'
import { join } from 'path'
import { app } from 'electron'
import { normalizeNamedInstruments } from '../csound/normalize'
import { Log } from '../util/log'
import { withCsoundPath } from '../util/csound-path'
import { getCsoundEnvironment, refreshCsoundEnvironment } from '../util/csound-version'
import { buildRealtimeIoFlags, csoundLimiterCliFlag, describeAudioRouting, readAudioIoConfig } from '../csound/audio-flags'
import { getConfigValue, setConfigValue } from '../util/config'
import { AUDIO_INPUT_KEY, AUDIO_INPUT_OFF, AUDIO_OUTPUT_KEY, MIDI_INPUT_KEY } from './config-keys'
import { listAudioDevices, resolveStoredOutputIndex } from '../util/audio-devices'
import {
  compileCheckPath,
  needsHoldScoreShortening,
  runCsoundCompileCheck,
} from '../csound/compile-check'
import {
  csoundOutputIndicatesRealtimeReady,
  prepareCsdForRealtimePlay,
} from '../csound/csd-playback'
import {
  prepareCsdForOfflineRender,
  renderOutputWasSilent,
} from '../../shared/csd-offline-prepare'
import { ensureCsoundLimiterCsOptions } from '../../shared/csd-realtime-options'

const execFileAsync = promisify(execFile)

let playProcess: ChildProcess | null = null
let playKilledBySignal = false
/** True once realtime csound has finished its initial score and accepts stdin events. */
let playReady = false

/** Best-effort note-offs + score end before killing realtime csound (avoids layered tails). */
function flushRealtimeNotes(stdin: NodeJS.WritableStream | null | undefined): void {
  if (!stdin || (stdin as NodeJS.WritableStream & { destroyed?: boolean }).destroyed) return
  try {
    for (let midi = 0; midi < 128; midi++) {
      const tag = `1.${midi.toString().padStart(3, '0')}`
      stdin.write(`i -${tag} 0 0\n`)
    }
    stdin.write('i -1 0 0\n')
    stdin.write('i -99 0 0\n')
    stdin.write('e\n')
  } catch { /* ignore */ }
}

/** Orphan csound processes (from crashed stops) can lock macOS Core Audio system-wide. */
export async function killOrphanDrcCsoundProcesses(): Promise<void> {
  if (process.platform === 'win32') return
  const drcTemp = join(app.getPath('temp'), 'drc')
  try {
    await execFileAsync('pkill', ['-9', '-f', drcTemp])
  } catch {
    /* no matching processes */
  }
  for (const name of ['realtime-play.csd', 'current.csd', 'offline-render.csd', 'compile-check.csd']) {
    try {
      await execFileAsync('pkill', ['-9', '-f', join(drcTemp, name)])
    } catch {
      /* no matching processes */
    }
  }
}

/** Kill the running csound/afplay process and wait until the OS releases the audio device. */
function stopPlayProcess(): Promise<void> {
  return new Promise((resolve) => {
    const finish = () => {
      void killOrphanDrcCsoundProcesses().finally(() => setTimeout(resolve, 150))
    }
    if (!playProcess) {
      playReady = false
      finish()
      return
    }
    const proc = playProcess
    const stdin = proc.stdin
    playKilledBySignal = true
    playReady = false
    playProcess = null

    flushRealtimeNotes(stdin)

    let settled = false
    const done = () => {
      if (settled) return
      settled = true
      clearTimeout(forceKill)
      clearTimeout(hardCap)
      finish()
    }

    proc.once('close', done)
    proc.once('error', done)

    const forceKill = setTimeout(() => {
      try {
        proc.kill('SIGKILL')
      } catch {
        /* ignore */
      }
    }, 80)

    const hardCap = setTimeout(done, 2000)

    try {
      proc.kill('SIGKILL')
    } catch {
      done()
    }
  })
}

/** Drop saved dac/adc indices that no longer match csound --devices (wrong backend = silent output). */
async function ensureAudioDevicesValid(): Promise<Awaited<ReturnType<typeof listAudioDevices>>> {
  const devs = await listAudioDevices().catch(() => ({ outputs: [], inputs: [], midiInputs: [] }))
  const out = getConfigValue(AUDIO_OUTPUT_KEY) ?? ''
  const inp = getConfigValue(AUDIO_INPUT_KEY) ?? ''
  const midi = getConfigValue(MIDI_INPUT_KEY) ?? ''
  const resolvedOut = resolveStoredOutputIndex(out, devs.outputs)
  if (resolvedOut !== out) {
    setConfigValue(AUDIO_OUTPUT_KEY, resolvedOut)
    const from = out || 'Auto'
    const toLabel =
      resolvedOut === ''
        ? 'Auto (physical output)'
        : (() => {
            const toDev = devs.outputs.find((d) => String(d.index) === resolvedOut)
            return toDev ? `${toDev.name} (${toDev.id})` : resolvedOut
          })()
    Log.warn(`Audio output ${from} → ${toLabel}`)
  }
  if (/^\d+$/.test(inp) && !devs.inputs.some((d) => String(d.index) === inp)) {
    setConfigValue(AUDIO_INPUT_KEY, AUDIO_INPUT_OFF)
    Log.warn(`Cleared stale audio input index ${inp} — device not in csound list`)
  }
  if (/^\d+$/.test(midi) && !devs.midiInputs.some((d) => String(d.index) === midi)) {
    setConfigValue(MIDI_INPUT_KEY, '')
  }
  return devs
}

function stripAnsi(s: string): string {
  // eslint-disable-next-line no-control-regex
  return s.replace(/\x1b\[[0-9;]*m/g, '')
}

function emitCsoundOutput(
  sender: WebContents,
  stream: 'stdout' | 'stderr' | 'info',
  raw: string,
): void {
  if (!raw) return
  for (const line of stripAnsi(raw).split('\n')) {
    const text = line.trimEnd()
    if (!text.trim()) continue
    sender.send('csound:output', { stream, text })
  }
}

function getTempDir(): string {
  const dir = join(app.getPath('temp'), 'drc')
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true })
  return dir
}

function getPreviewWavPath(): string {
  return join(getTempDir(), 'preview.wav')
}

/** macOS agent playback: offline render → afplay (follows system output device). */
function playWavViaAfplay(
  sender: WebContents,
  csdPath: string,
): Promise<{ success: boolean; output?: string; error?: string }> {
  const wavPath = getPreviewWavPath()
  let renderPath = csdPath
  let cleanupRender = false
  try {
    const raw = readFileSync(csdPath, 'utf-8')
    const prepared = prepareCsdForOfflineRender(raw)
    renderPath = join(getTempDir(), 'offline-render.csd')
    writeFileSync(renderPath, prepared, 'utf-8')
    cleanupRender = true
    if (prepared !== raw) {
      emitCsoundOutput(sender, 'info', 'Preview: sanitized CsOptions + demo score for offline render')
    }
  } catch {
    /* use original path */
  }

  const renderArgs = ['-o', wavPath, '-W', '-d', '-m0', csoundLimiterCliFlag(), renderPath]
  emitCsoundOutput(sender, 'info', 'Playback: render to WAV, then afplay (macOS system audio)')
  emitCsoundOutput(sender, 'info', `▶ csound ${renderArgs.join(' ')}`)

  const cleanup = () => {
    if (!cleanupRender) return
    try {
      unlinkSync(renderPath)
    } catch {
      /* ignore */
    }
  }

  return execFileAsync('csound', renderArgs, { timeout: 120000, env: withCsoundPath() })
    .then(({ stdout, stderr }) => {
      const combined = `${stdout}\n${stderr}`.trim()
      if (combined) emitCsoundOutput(sender, 'stderr', combined)
      cleanup()
      if (!existsSync(wavPath)) {
        const msg = extractCsoundError(combined) || 'Csound did not produce a WAV file'
        emitCsoundOutput(sender, 'stderr', msg)
        return { success: false, error: msg }
      }
      if (renderOutputWasSilent(combined)) {
        const msg =
          'Silent render — no notes fired. The CSD may be Player-shaped (f 0 hold) without a demo score. Try Play on the artifact again or open Player.'
        emitCsoundOutput(sender, 'stderr', msg)
        return { success: false, error: msg }
      }
      emitCsoundOutput(sender, 'info', '▶ afplay (your current macOS output — speakers, USB DAC, headphones…)')
      return new Promise<{ success: boolean; output?: string; error?: string }>((resolve) => {
        playKilledBySignal = false
        playProcess = spawn('afplay', [wavPath])
        playProcess.on('close', (code, signal) => {
          playProcess = null
          if (signal || playKilledBySignal) {
            emitCsoundOutput(sender, 'info', '■ Playback stopped.')
            resolve({ success: true, output: 'Stopped.' })
            return
          }
          if (code === 0 || code === null) {
            emitCsoundOutput(sender, 'info', '■ Playback finished.')
            resolve({ success: true, output: 'Playback finished.' })
            return
          }
          const msg = `afplay exited with code ${code}`
          emitCsoundOutput(sender, 'stderr', msg)
          resolve({ success: false, error: msg })
        })
        playProcess.on('error', (err) => {
          playProcess = null
          emitCsoundOutput(sender, 'stderr', err.message)
          resolve({ success: false, error: err.message })
        })
      })
    })
    .catch((err: any) => {
      cleanup()
      if (err.code === 'ENOENT') {
        const msg = 'Csound not found. Install Csound and make sure it\'s on your PATH.'
        emitCsoundOutput(sender, 'stderr', msg)
        return { success: false, error: msg }
      }
      const raw = err.stderr || err.message || 'Render failed'
      emitCsoundOutput(sender, 'stderr', raw)
      return { success: false, error: extractCsoundError(raw) || raw }
    })
}

/** Live csound with MIDI/knob stdin — used by the Player page. */
async function playRealtimeCsound(
  sender: WebContents,
  csdPath: string,
): Promise<{ success: boolean; output?: string; error?: string }> {
  await killOrphanDrcCsoundProcesses()

  let playPath = csdPath
  let cleanupPlay = false
  const cfg = readAudioIoConfig()
  try {
    const raw = readFileSync(csdPath, 'utf-8')
    const prepared = prepareCsdForRealtimePlay(raw, cfg)
    playPath = join(getTempDir(), 'realtime-play.csd')
    writeFileSync(playPath, prepared, 'utf-8')
    cleanupPlay = true
    if (prepared !== raw) {
      emitCsoundOutput(sender, 'info', 'Play: sanitized CsOptions + realtime hold score (keyboard-driven)')
    }
  } catch {
    /* use original path */
  }

  const devs = await listAudioDevices().catch(() => ({ outputs: [], inputs: [], midiInputs: [] }))
  const deviceCtx = { outputs: devs.outputs, inputs: devs.inputs }
  const playerIo = { webMidiOnly: true }
  const ioFlags = buildRealtimeIoFlags(playPath, cfg, deviceCtx, playerIo)
  const playArgs = [...ioFlags, '-d', '-m0', '-Lstdin', playPath]
  emitCsoundOutput(sender, 'info', describeAudioRouting(playPath, cfg, deviceCtx, playerIo))
  emitCsoundOutput(sender, 'info', `▶ csound ${playArgs.join(' ')}`)

  return new Promise((resolve) => {
    playKilledBySignal = false
    playReady = false
    let settled = false
    let stderr = ''

    const cleanupTemp = () => {
      if (!cleanupPlay) return
      try {
        unlinkSync(playPath)
      } catch {
        /* ignore */
      }
      cleanupPlay = false
    }

    const finishStart = (ok: boolean, err?: string) => {
      if (settled) return
      settled = true
      playReady = ok
      if (ok) {
        emitCsoundOutput(sender, 'info', '▶ Realtime audio ready — keyboard and knobs are live.')
        resolve({ success: true, output: 'Realtime engine running.' })
      } else {
        playReady = false
        cleanupTemp()
        resolve({ success: false, error: err ?? 'Failed to start realtime audio' })
      }
    }

    Log.info(`csound play io flags: ${ioFlags.join(' ')}`)
    playProcess = spawn('csound', playArgs, {
      stdio: ['pipe', 'pipe', 'pipe'],
      env: withCsoundPath(),
    })

    const maybeReady = () => {
      if (settled || !playProcess) return
      if (csoundOutputIndicatesRealtimeReady(stderr)) {
        finishStart(true)
      }
    }

    playProcess.stderr?.on('data', (d) => {
      const chunk = d.toString()
      stderr += chunk
      emitCsoundOutput(sender, 'stderr', chunk)
      maybeReady()
      for (const line of chunk.split('\n')) {
        const trimmed = line.trim()
        if (!trimmed) continue
        if (/INIT ERROR|PERF ERROR|error:|unknown opcode|unquoted|Unknown opcode|not a valid score/i.test(trimmed)) {
          Log.warn(`csound> ${trimmed}`)
        }
      }
    })
    playProcess.stdout?.on('data', (d) => {
      const text = d.toString()
      emitCsoundOutput(sender, 'stdout', text)
      stderr += text
      maybeReady()
      for (const line of text.split('\n')) {
        const t = line.trim()
        if (t && /error|instr\s+100/i.test(t)) Log.info(`csound> ${t}`)
      }
    })

    playProcess.stdin?.on('error', (err) => {
      Log.warn(`csound stdin error: ${err.message}`)
    })

    // Only mark ready once csound reports dac/scoreless — never blindly at 2.5s.
    const readyTimer = setTimeout(() => {
      if (!settled && playProcess && !playProcess.killed && csoundOutputIndicatesRealtimeReady(stderr)) {
        finishStart(true)
      }
    }, 1500)

    const readyPoll = setInterval(() => {
      if (settled || !playProcess || playProcess.killed) {
        clearInterval(readyPoll)
        return
      }
      if (csoundOutputIndicatesRealtimeReady(stderr)) {
        clearInterval(readyPoll)
        finishStart(true)
      }
    }, 250)

    const failTimer = setTimeout(() => {
      if (!settled) {
        playKilledBySignal = true
        playProcess?.kill('SIGKILL')
        finishStart(
          false,
          'Csound did not start realtime audio in time — check Settings → Audio or open Csound console for device errors.',
        )
      }
    }, 30_000)

    playProcess.on('close', (code, signal) => {
      clearTimeout(readyTimer)
      clearInterval(readyPoll)
      clearTimeout(failTimer)
      playProcess = null
      playReady = false
      cleanupTemp()
      if (!settled) {
        const msg = extractCsoundError(stderr) || (signal ? 'Csound stopped' : `Csound exited (${code})`)
        finishStart(false, msg)
        return
      }
      if (signal || playKilledBySignal) {
        emitCsoundOutput(sender, 'info', '■ Playback stopped.')
        return
      }
      const msg = extractCsoundError(stderr)
      if (msg) emitCsoundOutput(sender, 'stderr', msg)
      else if (code === 0 || code === null) emitCsoundOutput(sender, 'info', '■ Playback finished.')
      else emitCsoundOutput(sender, 'info', `■ Playback ended (exit ${code}).`)
    })

    playProcess.on('error', (err) => {
      clearTimeout(readyTimer)
      clearInterval(readyPoll)
      clearTimeout(failTimer)
      playProcess = null
      playReady = false
      if ((err as NodeJS.ErrnoException).code === 'ENOENT') {
        finishStart(false, 'Csound not found. Install Csound and make sure it\'s on your PATH.')
      } else {
        finishStart(false, err.message)
      }
    })
  })
}

// Csound's stderr is noisy: it prints an ANSI-colored banner (rtaudio module,
// version, device list, sr/kr/ksmps, PortAudio revision) before any real error.
// This function extracts the meaningful error line — if any — so we don't
// surface "rtaudio: PortAudio module enabled …" as the error message.
function extractCsoundError(raw: string): string {
  const stripped = raw.replace(/\x1b\[[0-9;]*m/g, '')
  const lines = stripped.split('\n').map((l) => l.trim()).filter(Boolean)
  if (!lines.length) return ''

  const isBanner = (l: string) =>
    /^rtaudio[:\s]/i.test(l) ||
    /^auhal[:\s]/i.test(l) ||
    /^rtmidi[:\s]/i.test(l) ||
    /^--Csound version/i.test(l) ||
    /^\[commit:/i.test(l) ||
    /^libsndfile/i.test(l) ||
    /^PortAudio[:\s]/i.test(l) ||
    /^PortMIDI/i.test(l) ||
    /^using callback interface/i.test(l) ||
    /^audio buffered in/i.test(l) ||
    /^writing \d+ sample blks/i.test(l) ||
    /^\d+:\s*dac\d+/i.test(l) ||
    /^\d+:\s*adc\d+/i.test(l) ||
    /^sr\s*=/i.test(l) ||
    /^0dBFS level/i.test(l) ||
    /^SECTION \d+/i.test(l) ||
    /^end of score/i.test(l) ||
    /^Elapsed time/i.test(l) ||
    /^overall amps/i.test(l) ||
    /^overall samples out of range/i.test(l) ||
    /^\d+\s+errors in performance/i.test(l) ||
    /^closing device/i.test(l) ||
    /^\d+\s+\d+ sample blks/i.test(l) ||
    /^Score finished/i.test(l) ||
    /^Stopping on parser failure/i.test(l) ||
    /^selected (input|output)/i.test(l) ||
    /^real time midi input disabled/i.test(l) ||
    /^UnifiedCSD/i.test(l) ||
    /^scoreless operation/i.test(l) ||
    /^orchname:/i.test(l) ||
    // Score-time markers and benign note-lifecycle info
    /^B\s+[\d.]+/i.test(l) ||
    /note deleted/i.test(l) ||
    /^new alloc for instr/i.test(l) ||
    /^instr\s+\d+:/i.test(l) ||
    /^removed instr/i.test(l) ||
    /^Seeding from current time/i.test(l) ||
    /^ftable\s+\d+:/i.test(l) ||
    /^Score: end of/i.test(l)

  // Prefer the concrete error line (e.g. "error: Unable to find opcode entry…")
  // over generic summaries so the user sees the actionable cause. We also pull
  // the "Line: NN" hint right after the error when csound provides it.
  const errorLines = lines.filter((l) => /error|cannot|unexpected|failed|syntax|undefined/i.test(l) && !isBanner(l))
  if (errorLines.length) {
    const msg = errorLines.slice(0, 3).join(' | ')
    const lineHint = stripped.match(/Line:\s*(\d+)/i)
    return lineHint ? `${msg} (line ${lineHint[1]})` : msg
  }

  // Performance-level red flags — only reported if no concrete error line exists.
  // Silent output with "overall amps: 0.0" almost always means no notes fired.
  const perfErrMatch = stripped.match(/(\d+)\s+errors in performance/i)
  if (perfErrMatch && parseInt(perfErrMatch[1], 10) > 0) {
    const noteDeleted = stripped.match(/note deleted\.\s*([^\n]+)/i)
    const detail = noteDeleted ? ` — ${noteDeleted[1].trim()}` : ''
    return `${perfErrMatch[1]} error${perfErrMatch[1] === '1' ? '' : 's'} during performance${detail}`
  }
  if (/overall amps:\s+0\.00000\s+0\.00000/i.test(stripped)) {
    return 'Silent output — no instrument events fired (check score numbers match instr definitions)'
  }

  const warnLines = lines.filter((l) => /!!|WARNING/.test(l) && !isBanner(l))
  if (warnLines.length) return warnLines.slice(0, 2).join(' | ')

  return ''
}

export function handleCsoundIPC(ipcMain: IpcMain): void {
  void refreshCsoundEnvironment()
  void killOrphanDrcCsoundProcesses()
  app.on('before-quit', () => {
    void killOrphanDrcCsoundProcesses()
  })

  ipcMain.handle('csound:getEnvironment', async () => {
    const env = await refreshCsoundEnvironment()
    return env
  })

  // Write CSD content to temp file, return the path.
  // Rewrites named instruments (instr Bell, i "Bell" ...) to numbered ones because
  // Csound 6.18 can't resolve named-instrument score events. Preserves source CSD
  // in the renderer; only the on-disk copy passed to the csound binary is normalized.
  //
  // Also unfolds single-line <CsOptions>-odac -d</CsOptions> into multi-line form.
  // Csound 6.18 has a parser bug where a one-liner with multiple flags reports
  // "Invalid arguments in <CsOptions>: <CsInstruments>" under --syntax-check-only,
  // which would otherwise abort the Player's compile step before play. Our adapt
  // template emits the one-liner; users may bring CSDs that do too.
  ipcMain.handle('csound:writeCsd', async (_event, content: string) => {
    const tmpPath = join(getTempDir(), 'current.csd')
    const { csd: namedFixed } = normalizeNamedInstruments(content)
    const withLimiter = ensureCsoundLimiterCsOptions(namedFixed)
    const normalized = withLimiter.replace(
      /<CsOptions>([^\n<]*)<\/CsOptions>/i,
      (_, body: string) => `<CsOptions>\n${body.trim()}\n</CsOptions>`,
    )
    writeFileSync(tmpPath, normalized, 'utf-8')
    return { path: tmpPath }
  })

  ipcMain.handle('csound:compile', async (event, csdPath: string) => {
    // Full performance dry-run (-n): catches INIT/PERF errors that
    // --syntax-check-only misses. Player realtime CSDs hold for hours via
    // `f 0 36000` — shorten that score so compile finishes in seconds.
    let checkPath = csdPath
    let cleanupCheck = false
    try {
      const raw = readFileSync(csdPath, 'utf-8')
      checkPath = compileCheckPath(csdPath, getTempDir())
      cleanupCheck = true
      if (needsHoldScoreShortening(raw)) {
        emitCsoundOutput(event.sender, 'info', 'Compile: using 1s hold score (Player realtime CSD)')
      }
    } catch {
      /* use original path */
    }

    emitCsoundOutput(event.sender, 'info', `▶ csound -n -d -m0 ${checkPath}`)
    try {
      const { stdout, stderr, code } = await runCsoundCompileCheck(checkPath, 15_000)
      const combined = (stdout + '\n' + stderr).trim()
      if (combined) emitCsoundOutput(event.sender, 'stderr', combined)
      const perfErr = combined.match(/(\d+)\s+errors in performance/i)
      if (perfErr && parseInt(perfErr[1], 10) > 0) {
        const msg = extractCsoundError(combined) || `${perfErr[1]} performance error(s)`
        return { success: false, error: msg }
      }
      if (/INIT ERROR|Parsing failed|syntax error|too many arguments/i.test(combined)) {
        const msg = extractCsoundError(combined) || 'Csound performance check failed'
        return { success: false, error: msg }
      }
      if (code !== 0 && code !== null) {
        const msg = extractCsoundError(combined) || `Csound exited with code ${code}`
        return { success: false, error: msg }
      }
      return { success: true, output: combined || 'Performance check passed.' }
    } catch (err: any) {
      if (err.code === 'ENOENT') {
        const msg = 'Csound not found. Install Csound and make sure it\'s on your PATH.'
        emitCsoundOutput(event.sender, 'stderr', msg)
        return { success: false, error: msg }
      }
      if (err.code === 'ETIMEDOUT') {
        const msg =
          'Compile check timed out. The CSD may have an extremely long score — try reloading, or open Terminal → Csound to inspect output.'
        emitCsoundOutput(event.sender, 'stderr', msg)
        return { success: false, error: msg }
      }
      const raw = (err.stdout || '') + '\n' + (err.stderr || err.message || 'Unknown error')
      emitCsoundOutput(event.sender, 'stderr', raw)
      return { success: false, error: extractCsoundError(raw) || raw }
    } finally {
      if (cleanupCheck) {
        try {
          unlinkSync(checkPath)
        } catch {
          /* ignore */
        }
      }
    }
  })

  ipcMain.handle('csound:render', async (_event, csdPath: string, opts?: { output?: string }) => {
    const outputPath = opts?.output || join(getTempDir(), 'output.wav')
    try {
      const { stdout, stderr } = await execFileAsync('csound', ['-o', outputPath, csdPath], { timeout: 30000, env: withCsoundPath() })
      return { success: true, output: `Rendered to ${outputPath}\n${(stdout + '\n' + stderr).trim()}` }
    } catch (err: any) {
      if (err.code === 'ENOENT') {
        return { success: false, error: 'Csound not found. Install Csound and make sure it\'s on your PATH.' }
      }
      // Csound often exits non-zero but still produces output
      if (existsSync(outputPath)) {
        return { success: true, output: `Rendered to ${outputPath} (with warnings)` }
      }
      return { success: false, error: extractCsoundError(err.stderr || '') || err.message }
    }
  })

  ipcMain.handle('csound:play', async (event, csdPath: string, opts?: { realtime?: boolean }) => {
    await stopPlayProcess()

    // Agent playback: render WAV + afplay → macOS system output (headphones, USB DAC, etc.).
    // Player page: realtime csound with live MIDI/knobs.
    const useRealtime = opts?.realtime === true || process.platform !== 'darwin'
    if (useRealtime) {
      await ensureAudioDevicesValid()
      return playRealtimeCsound(event.sender, csdPath)
    }
    return playWavViaAfplay(event.sender, csdPath)
  })

  // Write a raw score line to the running csound stdin (enabled by -Lstdin in
  // csound:play). Caller is responsible for a valid score line — we only append
  // a newline if missing. No-op if nothing is playing.
  ipcMain.handle('csound:event', async (_event, line: string) => {
    if (!playProcess?.stdin || playProcess.stdin.destroyed || !playReady) {
      return { success: false, error: playProcess ? 'Audio engine starting…' : 'Not playing' }
    }
    const ln = line.endsWith('\n') ? line : line + '\n'
    try {
      playProcess.stdin.write(ln)
      return { success: true }
    } catch (err: any) {
      return { success: false, error: err.message }
    }
  })

  // Update a named control channel via the channel-writer helper (instr 100)
  // that the PLAYER_TEMPLATE bakes into every adapted CSD. Csound score lines
  // allow string p-fields when double-quoted, so:
  //     i 100 0 0 "frequency" 880
  // fires once, calls chnset inside instr 100, and updates the channel the
  // voice instrument reads via chnget.
  ipcMain.handle('csound:setChannel', async (_event, name: string, value: number) => {
    if (!playProcess) {
      Log.warn(`setChannel(${name}=${value}) — no play process`)
      return { success: false, error: 'Not playing' }
    }
    if (!playReady || !playProcess.stdin || playProcess.stdin.destroyed) {
      Log.warn(`setChannel(${name}=${value}) — engine not ready`)
      return { success: false, error: 'Audio engine starting…' }
    }
    const safe = String(name).replace(/[^a-zA-Z0-9_]/g, '')
    if (!safe) return { success: false, error: 'Invalid channel name' }
    const num = Number.isFinite(value) ? value : 0
    const line = `i 100 0 0 "${safe}" ${num}\n`
    try {
      const ok = playProcess.stdin.write(line)
      Log.info(`setChannel ${safe}=${num} → stdin.write ok=${ok}`)
      return { success: true }
    } catch (err: any) {
      Log.warn(`setChannel write failed: ${err.message}`)
      return { success: false, error: err.message }
    }
  })

  ipcMain.handle('csound:stop', async () => {
    await stopPlayProcess()
    return { success: true }
  })

  ipcMain.handle('csound:saveConsoleLog', async (_event, text: string) => {
    const stamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)
    const path = join(app.getPath('desktop'), `drc-csound-${stamp}.log`)
    writeFileSync(path, text.endsWith('\n') ? text : `${text}\n`, 'utf-8')
    return { path }
  })

}
