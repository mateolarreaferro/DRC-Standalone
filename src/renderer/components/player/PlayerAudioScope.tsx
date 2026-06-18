import { useEffect, useRef, useState, type CSSProperties } from 'react'
import { usePlayerScopeAudio } from '../../hooks/usePlayerScopeAudio'

type ScopeView = 'time' | 'spectrum'

interface Props {
  activeNotes: Set<number>
  isPlaying: boolean
  height?: number
}

export default function PlayerAudioScope({ activeNotes, isPlaying, height = 160 }: Props) {
  const [view, setView] = useState<ScopeView>('time')
  const [autoAlternate, setAutoAlternate] = useState(true)
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const analyserRef = usePlayerScopeAudio(activeNotes, isPlaying)
  const timeDataRef = useRef<Uint8Array | null>(null)
  const freqDataRef = useRef<Uint8Array | null>(null)

  useEffect(() => {
    if (!autoAlternate) return
    const id = window.setInterval(() => {
      setView((v) => (v === 'time' ? 'spectrum' : 'time'))
    }, 5000)
    return () => window.clearInterval(id)
  }, [autoAlternate])

  useEffect(() => {
    let raf = 0
    const draw = () => {
      const canvas = canvasRef.current
      const analyser = analyserRef.current
      if (!canvas) {
        raf = requestAnimationFrame(draw)
        return
      }

      const ctx = canvas.getContext('2d')
      if (!ctx) {
        raf = requestAnimationFrame(draw)
        return
      }

      const dpr = window.devicePixelRatio || 1
      const width = canvas.offsetWidth
      if (width < 8) {
        raf = requestAnimationFrame(draw)
        return
      }
      canvas.width = width * dpr
      canvas.height = height * dpr
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0)

      ctx.fillStyle = getComputedStyle(document.documentElement).getPropertyValue('--bg-secondary').trim() || '#161b22'
      ctx.fillRect(0, 0, width, height)

      const hasSignal = isPlaying && (activeNotes.size > 0 || analyser)
      if (analyser && hasSignal) {
        if (!timeDataRef.current || timeDataRef.current.length !== analyser.fftSize) {
          timeDataRef.current = new Uint8Array(analyser.fftSize)
        }
        if (!freqDataRef.current || freqDataRef.current.length !== analyser.frequencyBinCount) {
          freqDataRef.current = new Uint8Array(analyser.frequencyBinCount)
        }
        analyser.getByteTimeDomainData(timeDataRef.current)
        analyser.getByteFrequencyData(freqDataRef.current)

        if (view === 'time') {
          drawTimeDomain(ctx, width, height, timeDataRef.current)
        } else {
          drawSpectrum(ctx, width, height, freqDataRef.current)
        }
      } else {
        drawIdle(ctx, width, height, view)
      }

      raf = requestAnimationFrame(draw)
    }

    raf = requestAnimationFrame(draw)
    return () => cancelAnimationFrame(raf)
  }, [activeNotes.size, analyserRef, height, isPlaying, view])

  return (
    <div style={styles.shell}>
      <div style={styles.toolbar}>
        <div style={styles.tabs}>
          <button
            type="button"
            style={{ ...styles.tab, ...(view === 'time' ? styles.tabActive : {}) }}
            onClick={() => { setAutoAlternate(false); setView('time') }}
          >
            Time
          </button>
          <button
            type="button"
            style={{ ...styles.tab, ...(view === 'spectrum' ? styles.tabActive : {}) }}
            onClick={() => { setAutoAlternate(false); setView('spectrum') }}
          >
            Spectrum
          </button>
        </div>
        <label style={styles.autoLabel}>
          <input
            type="checkbox"
            checked={autoAlternate}
            onChange={(e) => setAutoAlternate(e.target.checked)}
          />
          Alternate views
        </label>
        <span style={styles.hint}>
          {isPlaying
            ? activeNotes.size > 0
              ? 'Live scope — keyboard/MIDI'
              : 'Play keys for live scope'
            : 'Start playback to enable scope'}
        </span>
      </div>
      <canvas ref={canvasRef} style={{ width: '100%', height, display: 'block' }} />
    </div>
  )
}

function drawTimeDomain(
  ctx: CanvasRenderingContext2D,
  width: number,
  height: number,
  data: Uint8Array,
) {
  const mid = height / 2
  ctx.beginPath()
  ctx.strokeStyle = '#7cb8a4'
  ctx.lineWidth = 1.5
  const step = data.length / width
  for (let x = 0; x < width; x++) {
    const i = Math.floor(x * step)
    const v = (data[i] - 128) / 128
    const y = mid + v * mid * 1.35
    if (x === 0) ctx.moveTo(x, y)
    else ctx.lineTo(x, y)
  }
  ctx.stroke()
  ctx.strokeStyle = 'rgba(124, 184, 164, 0.2)'
  ctx.beginPath()
  ctx.moveTo(0, mid)
  ctx.lineTo(width, mid)
  ctx.stroke()
}

function drawSpectrum(
  ctx: CanvasRenderingContext2D,
  width: number,
  height: number,
  data: Uint8Array,
) {
  const bins = Math.min(data.length, Math.floor(width))
  const barW = width / bins
  for (let i = 0; i < bins; i++) {
    const amp = data[i] / 255
    const barH = amp * height * 0.95
    const hue = 160 + (i / bins) * 80
    ctx.fillStyle = `hsla(${hue}, 70%, 55%, ${0.35 + amp * 0.65})`
    ctx.fillRect(i * barW, height - barH, Math.max(1, barW - 1), barH)
  }
}

function drawIdle(ctx: CanvasRenderingContext2D, width: number, height: number, view: ScopeView) {
  const mid = height / 2
  const t = Date.now() / 1000
  if (view === 'time') {
    ctx.beginPath()
    ctx.strokeStyle = 'rgba(124, 184, 164, 0.2)'
    for (let x = 0; x < width; x++) {
      const y = mid + Math.sin(x * 0.04 + t) * mid * 0.08
      if (x === 0) ctx.moveTo(x, y)
      else ctx.lineTo(x, y)
    }
    ctx.stroke()
  } else {
    for (let i = 0; i < 24; i++) {
      const amp = 0.08 + Math.abs(Math.sin(t * 0.7 + i * 0.4)) * 0.12
      const barH = amp * height
      const x = (i / 24) * width
      const barW = width / 24 - 2
      ctx.fillStyle = `rgba(124, 184, 164, ${0.12 + amp})`
      ctx.fillRect(x, height - barH, barW, barH)
    }
  }
}

const styles: Record<string, CSSProperties> = {
  shell: {
    width: '100%',
    borderRadius: 16,
    overflow: 'hidden',
    border: 'var(--border-width) solid var(--border)',
    background: 'var(--bg-secondary)',
  },
  toolbar: {
    display: 'flex',
    alignItems: 'center',
    gap: 10,
    padding: '8px 12px',
    borderBottom: '1px solid var(--border-subtle)',
    flexWrap: 'wrap',
  },
  tabs: { display: 'flex', gap: 4 },
  tab: {
    padding: '4px 10px',
    borderRadius: 6,
    border: '1px solid var(--border)',
    background: 'transparent',
    color: 'var(--text-secondary)',
    fontSize: 11,
    fontWeight: 600,
    cursor: 'pointer',
    fontFamily: 'var(--font-primary)',
  },
  tabActive: {
    borderColor: 'var(--accent)',
    color: 'var(--accent)',
    background: 'var(--accent-muted)',
  },
  autoLabel: {
    display: 'flex',
    alignItems: 'center',
    gap: 6,
    fontSize: 11,
    color: 'var(--text-muted)',
    cursor: 'pointer',
    userSelect: 'none',
  },
  hint: {
    marginLeft: 'auto',
    fontSize: 11,
    color: 'var(--text-muted)',
    fontStyle: 'italic',
  },
}
