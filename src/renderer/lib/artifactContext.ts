import { useArtifactStore, primaryContent, type ArtifactType } from '../stores/artifactStore'

// One short line per type, so the model keeps the right output format.
const FORMAT_HINT: Record<ArtifactType, string> = {
  csd: 'Emit the full updated <CsoundSynthesizer>…</CsoundSynthesizer>.',
  webapp: 'Describe the change; the host re-converts from orchestra CSD. Do not emit HTML.',
  vst: 'Keep the <Cabbage>…</Cabbage> section and emit the full updated document.',
}

// Wrap a follow-up so the model edits the artifact CURRENTLY OPEN in the panel,
// not whatever happens to be last in the chat. We embed the active artifact's
// exact current content as the base to modify. This is what makes "open an
// older version (or hand-edit the code), then ask for a change" target that
// version — relying on conversation history alone always edited the newest one.
export function wrapWithArtifactContext(userText: string): string {
  const active = useArtifactStore.getState().getActive()
  if (!active) return userText
  return (
    `Modify the artifact currently open in the panel, shown below. Apply the change to THIS exact version, ` +
    `not to any earlier or later version from the conversation. ${FORMAT_HINT[active.type]}\n\n` +
    `<current-artifact type="${active.type}">\n${primaryContent(active)}\n</current-artifact>\n\n` +
    userText
  )
}
