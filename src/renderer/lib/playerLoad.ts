import type { Artifact } from '../stores/artifactStore'
import { primaryContent } from '../stores/artifactStore'

/** Extract playable orchestra text from any Dr.C artifact type. */
export function csdFromArtifact(artifact: Artifact): string | null {
  if (artifact.type === 'csd' || artifact.type === 'vst') {
    const content = primaryContent(artifact)
    return content.includes('<CsoundSynthesizer>') ? content : null
  }
  if (artifact.type === 'webapp') {
    const csdFile = artifact.files.find((f) => f.name === 'main.csd' && f.language === 'csd')
    if (csdFile?.content.includes('<CsoundSynthesizer>')) return csdFile.content
  }
  return null
}

/** Active artifact first, else the most recent CSD-capable artifact in the session. */
export function resolveAgentCsd(artifacts: Artifact[], activeId: string | null): { csd: string; title: string } | null {
  const active = activeId ? artifacts.find((a) => a.id === activeId) : null
  if (active) {
    const csd = csdFromArtifact(active)
    if (csd) return { csd, title: active.title }
  }
  for (let i = artifacts.length - 1; i >= 0; i--) {
    const csd = csdFromArtifact(artifacts[i])
    if (csd) return { csd, title: artifacts[i].title }
  }
  return null
}
