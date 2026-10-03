import type { ArtifactType } from '../stores/artifactStore'

export interface DetectionStart {
  type: ArtifactType
  startIdx: number
  fenced: boolean
}

export interface DetectionResult {
  type: ArtifactType
  code: string
  range: [number, number]
  complete: boolean
}

// Find the first position where an artifact starts in the (possibly partial) content.
// Precedence: web-app > vst > csd. Fenced blocks are preferred over bare markers
// because models often wrap with ```html even when asked not to.
export function findStart(content: string): DetectionStart | null {
  const fenceMatch = content.match(/```(?:html|HTML)\s*\n/)
  const docMatch = content.match(/<!DOCTYPE\s+html\s*>/i)
  const cabMatch = content.match(/<Cabbage>/i)
  const csdMatch = content.match(/<CsoundSynthesizer>/i)

  const candidates: DetectionStart[] = []
  if (fenceMatch && fenceMatch.index !== undefined) {
    candidates.push({ type: 'webapp', startIdx: fenceMatch.index, fenced: true })
  }
  if (docMatch && docMatch.index !== undefined) {
    candidates.push({ type: 'webapp', startIdx: docMatch.index, fenced: false })
  }
  if (cabMatch && cabMatch.index !== undefined) {
    const csdIdx = csdMatch?.index ?? cabMatch.index
    candidates.push({ type: 'vst', startIdx: Math.min(cabMatch.index, csdIdx), fenced: false })
  } else if (csdMatch && csdMatch.index !== undefined) {
    candidates.push({ type: 'csd', startIdx: csdMatch.index, fenced: false })
  }

  if (!candidates.length) return null

  // Prefer webapp when the response is a conversion (DOCTYPE present anywhere
  // outranks a leading CSD block — the model may have restated prior source).
  const hasWebapp = candidates.find((c) => c.type === 'webapp')
  if (hasWebapp) return hasWebapp
  return candidates.sort((a, b) => a.startIdx - b.startIdx)[0]
}

// Given a detected start, extract the artifact code and its [start, end] range
// in the original content. If the closing marker is missing (still streaming),
// returns the partial content with complete=false.
export function extract(content: string, start: DetectionStart): DetectionResult {
  if (start.fenced) {
    // Fenced web-app: ```html\n<body>\n```
    const afterFenceIdx = content.indexOf('\n', start.startIdx) + 1
    const body = content.slice(afterFenceIdx)
    const closeRel = body.search(/\n```/)
    if (closeRel >= 0) {
      return {
        type: 'webapp',
        code: body.slice(0, closeRel).trim(),
        range: [start.startIdx, afterFenceIdx + closeRel + 4],
        complete: true,
      }
    }
    return {
      type: 'webapp',
      code: body.trim(),
      range: [start.startIdx, content.length],
      complete: false,
    }
  }

  const tail = content.slice(start.startIdx)

  if (start.type === 'webapp') {
    const closeMatch = tail.match(/<\/html\s*>/i)
    if (closeMatch && closeMatch.index !== undefined) {
      const end = start.startIdx + closeMatch.index + closeMatch[0].length
      return {
        type: 'webapp',
        code: content.slice(start.startIdx, end),
        range: [start.startIdx, end],
        complete: true,
      }
    }
    return {
      type: 'webapp',
      code: tail,
      range: [start.startIdx, content.length],
      complete: false,
    }
  }

  if (start.type === 'vst') {
    // VST: needs both </Cabbage> and </CsoundSynthesizer>
    const closeCsd = tail.match(/<\/CsoundSynthesizer\s*>/i)
    if (closeCsd && closeCsd.index !== undefined) {
      const end = start.startIdx + closeCsd.index + closeCsd[0].length
      return {
        type: 'vst',
        code: content.slice(start.startIdx, end),
        range: [start.startIdx, end],
        complete: true,
      }
    }
    return {
      type: 'vst',
      code: tail,
      range: [start.startIdx, content.length],
      complete: false,
    }
  }

  // csd
  const closeMatch = tail.match(/<\/CsoundSynthesizer\s*>/i)
  if (closeMatch && closeMatch.index !== undefined) {
    const end = start.startIdx + closeMatch.index + closeMatch[0].length
    return {
      type: 'csd',
      code: content.slice(start.startIdx, end),
      range: [start.startIdx, end],
      complete: true,
    }
  }
  return {
    type: 'csd',
    code: tail,
    range: [start.startIdx, content.length],
    complete: false,
  }
}

// Convenience: one-shot detect for message bubble rendering and post-stream use.
export function detect(content: string): DetectionResult | null {
  const start = findStart(content)
  if (!start) return null
  return extract(content, start)
}

/** CSD-only detect — ignores HTML/VST precedence. Used for Convert-to-Web-App turns. */
export function detectCsd(content: string): DetectionResult | null {
  const start = content.search(/<CsoundSynthesizer>/i)
  if (start < 0) return null
  const tail = content.slice(start)
  const closeMatch = tail.match(/<\/CsoundSynthesizer\s*>/i)
  if (closeMatch && closeMatch.index !== undefined) {
    const end = start + closeMatch.index + closeMatch[0].length
    return {
      type: 'csd',
      code: content.slice(start, end),
      range: [start, end],
      complete: true,
    }
  }
  return {
    type: 'csd',
    code: tail,
    range: [start, content.length],
    complete: false,
  }
}

// Remove the artifact region from a message so the chat bubble shows prose only.
export function stripArtifact(content: string): string {
  const start = findStart(content)
  if (!start) return content
  const res = extract(content, start)
  const before = content.slice(0, res.range[0]).trimEnd()
  const after = content.slice(res.range[1]).trimStart()
  if (!before && !after) return ''
  return before + (before && after ? '\n\n' : '') + after
}

// Derive a short title from detected code (webapp: <title>, csd/vst: leading comment).
export function deriveTitle(code: string, type: ArtifactType, fallback: string): string {
  if (type === 'webapp') {
    const m = code.match(/<title>([^<]*)<\/title>/i)
    if (m) return m[1].replace(/\s*[—\-|].*/, '').trim().slice(0, 60) || fallback
  }
  const m = code.match(/;\s*(.{3,48})\n/)
  if (m) return m[1].trim()
  return fallback.split(/\s+/).slice(0, 4).join(' ') || 'Untitled'
}
