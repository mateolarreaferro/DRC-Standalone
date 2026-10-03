import { useMemo, type CSSProperties } from 'react'
import type { Artifact } from '../../stores/artifactStore'
import { primaryContent } from '../../stores/artifactStore'

interface Props {
  artifact: Artifact
}

export default function WebAppPreview({ artifact }: Props) {
  const srcDoc = useMemo(() => primaryContent(artifact), [artifact])
  return (
    <div style={styles.container}>
      <iframe
        srcDoc={srcDoc}
        style={styles.iframe}
        sandbox="allow-scripts allow-same-origin allow-forms allow-modals allow-popups"
        allow="autoplay; microphone; clipboard-write"
        title={artifact.title}
      />
    </div>
  )
}

const styles: Record<string, CSSProperties> = {
  container: { flex: 1, minHeight: 0, display: 'flex' },
  iframe: { flex: 1, border: 'none', background: '#111' },
}
