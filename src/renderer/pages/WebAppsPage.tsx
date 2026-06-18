import { useState, useRef, useCallback, useEffect, useMemo, type CSSProperties } from 'react'
import { useEditorStore } from '../stores/editorStore'
import StudyFlowButton from '../components/study/StudyFlowButton'
import type { SignalFlowStudyInput } from '../lib/signalFlowStudy'

// Real, self-contained finished apps — bundled at build time so clicking a card
// shows the actual drum machine / FM bell / etc. interface, not a generated shell.
import drumMachineHtml from '../assets/apps/drum-machine.html?raw'
import fmBellHtml from '../assets/apps/fm-bell.html?raw'
import etude1Html from '../assets/apps/etude1.html?raw'
import fibonacciFmHtml from '../assets/apps/fibonacci-fm.html?raw'
import fractalExplorerHtml from '../assets/apps/fractal-explorer.html?raw'
import weatherSonificationHtml from '../assets/apps/weather-sonification.html?raw'
import starchartSonificationHtml from '../assets/apps/starchart-sonification.html?raw'
import mandelbrotExplorerHtml from '../assets/apps/mandelbrot-explorer.html?raw'

interface AppTemplate {
  id: string
  name: string
  desc: string
  tags: string[]
  csd: string  // Snippet for "Open in CSD Editor"
  html?: string  // Full finished-app HTML (for the Preview iframe)
}

const REFERENCE_APPS: AppTemplate[] = [
  {
    id: 'drum-machine',
    name: 'Drum Machine',
    desc: '16-step sequencer with 10 synth drums, 6 kits, 12 global effects',
    tags: ['sequencer', 'percussion', 'FM synthesis'],
    html: drumMachineHtml,
    csd: `; Drum Machine - FM Kick
instr 1  ; kick
  iAmp = p5
  kFreq expseg 200, 0.02, 55, p3-0.02, 30
  kEnv expseg iAmp, 0.01, iAmp, p3-0.01, 0.001
  aOut oscili kEnv, kFreq
  aOut butterlp aOut, 200
  outs aOut, aOut
endin`,
  },
  {
    id: 'etude1',
    name: 'Étude #1',
    desc: 'Generative audiovisual piece — 14 autonomous instruments in B Phrygian',
    tags: ['generative', 'autonomous', 'FOF synthesis', 'Three.js'],
    html: etude1Html,
    csd: `; Étude #1 - Autonomous composer
instr 10  ; grain cloud
  iDur = p3
  iFreq = p4
  kDens linseg 10, iDur*0.3, 80, iDur*0.4, 40, iDur*0.3, 5
  aOut grain iFreq, 0.02, kDens, 1, 1, 0.5
  kEnv linseg 0, 0.1, 0.3, iDur-0.2, 0.3, 0.1, 0
  outs aOut*kEnv, aOut*kEnv
endin`,
  },
  {
    id: 'fibonacci-fm',
    name: 'Fibonacci FM Explorer',
    desc: 'FM synth with 25 scales (microtonal, Fibonacci, Bohlen-Pierce), ghost mode, 30+ presets',
    tags: ['FM synthesis', 'microtonal', 'polyphonic', 'MIDI'],
    html: fibonacciFmHtml,
    csd: `; Fibonacci FM - Golden ratio FM
instr 1
  iFreq = p4
  iAmp = p5
  iPhi = 1.618033988 ; golden ratio

  iModFreq = iFreq * iPhi
  kModIdx expseg 12, p3*0.5, 3, p3*0.5, 0.5

  aMod oscili iFreq*kModIdx, iModFreq
  aOut oscili iAmp, iFreq + aMod

  kEnv madsr 0.01, 0.3, 0.6, 0.5
  outs aOut*kEnv, aOut*kEnv
endin`,
  },
  {
    id: 'fm-bell',
    name: 'FM Bell',
    desc: 'Minimal FM synthesis example — clean, focused, under 2KB',
    tags: ['FM synthesis', 'beginner', 'minimal'],
    html: fmBellHtml,
    csd: `; FM Bell
instr 1
  iFreq = p4
  iAmp = p5
  kIdx expseg 8, p3*0.8, 0.1, p3*0.2, 0.01
  aMod oscili iFreq*3.5*kIdx, iFreq*3.5
  kEnv expseg iAmp, 0.01, iAmp, p3-0.01, 0.001
  aOut oscili kEnv, iFreq + aMod
  outs aOut, aOut
endin`,
  },
  {
    id: 'fractal-explorer',
    name: 'Fractal Explorer',
    desc: 'L-System music — Algae, Tree, Dragon, Koch, Sierpinski mapped to synthesis',
    tags: ['L-system', 'algorithmic', 'fractal', 'ambisonics'],
    html: fractalExplorerHtml,
    csd: `; Fractal Explorer - L-system note generator
; Depth maps to pitch, angle maps to duration
instr 1
  iFreq = p4
  iDur = p3
  iPan = p6

  kEnv adsr 0.05, iDur*0.3, 0.4, iDur*0.2
  aOut vco2 0.3*kEnv, iFreq, 2, 0.5
  aOut moogladder aOut, iFreq*4, 0.3

  aL, aR pan2 aOut, iPan
  outs aL, aR
endin`,
  },
  {
    id: 'weather-sonification',
    name: 'Weather Sonification',
    desc: 'Real-time Open-Meteo API data → Markov chords, 7 scales, 4 orchestral palettes',
    tags: ['sonification', 'API', 'Markov chains', 'generative'],
    html: weatherSonificationHtml,
    csd: `; Weather Sonification - Temperature → pitch
instr 1  ; warm pad
  iTemp = p4  ; temperature in Celsius
  iFreq = 220 * semitone(iTemp - 20)

  aOsc1 vco2 0.2, iFreq, 0
  aOsc2 vco2 0.15, iFreq*1.002, 0
  aMix = aOsc1 + aOsc2
  aMix moogladder aMix, 800 + iTemp*40, 0.4

  kEnv madsr 2, 1, 0.7, 3
  outs aMix*kEnv, aMix*kEnv
endin`,
  },
  {
    id: 'starchart-sonification',
    name: 'StarChart Sonification',
    desc: 'Real-time star sonification — catalog stars mapped to voices by temperature, magnitude, and constellation',
    tags: ['sonification', 'astronomy', 'granular', 'generative'],
    html: starchartSonificationHtml,
    csd: `; StarSound - a single star's voice
instr 1
  iFreq = p4  ; pitch from stellar temperature
  iAmp  = p5  ; loudness from apparent magnitude
  kEnv madsr 0.4, 0.3, 0.6, 1.5
  aOsc oscili iAmp*kEnv, iFreq
  aShimmer oscili iAmp*kEnv*0.3, iFreq*2.002
  aMix moogladder aOsc + aShimmer, 1200 + iAmp*4000, 0.2
  outs aMix, aMix
endin`,
  },
  {
    id: 'mandelbrot-explorer',
    name: 'Mandelbrot Explorer',
    desc: 'Explore the Mandelbrot set as sound — escape-time orbits drive pluck synthesis with zoomable fractal navigation',
    tags: ['fractal', 'sonification', 'pluck synthesis', 'interactive'],
    html: mandelbrotExplorerHtml,
    csd: `; Mandelbrot Explorer - escape-time pluck voice
instr 1
  iFreq = p4  ; pitch from orbit position
  iAmp  = p5  ; loudness from escape iteration count
  kEnv linsegr 0, 0.005, iAmp, 0.4, 0
  aSig pluck kEnv, iFreq, iFreq, 0, 1
  aSig tone aSig, 500 + iAmp*3000
  aL, aR pan2 aSig, 0.5
  outs aL, aR
endin`,
  },
]

export default function WebAppsPage() {
  const [selectedApp, setSelectedApp] = useState<AppTemplate | null>(null)
  const [appCode, setAppCode] = useState('')
  // Fraction of split width given to the code panel when it's open. Preview
  // takes the rest. The preview is what the user interacts with, so the code
  // panel is hidden by default and revealed on demand via "Open Code".
  const [codeFrac, setCodeFrac] = useState(0.4)
  const [showCode, setShowCode] = useState(false)
  const [browserStatus, setBrowserStatus] = useState('')
  const splitRef = useRef<HTMLDivElement>(null)
  const draggingRef = useRef(false)
  const { setCsdContent } = useEditorStore()

  const handleSelectApp = (app: AppTemplate) => {
    setSelectedApp(app)
    // Prefer the real finished-app HTML when bundled; fall back to the generated
    // shell for the "New App" / scratch path.
    setAppCode(app.html ?? buildHtmlApp(app))
  }

  const onSplitterDown = useCallback((e: React.MouseEvent) => {
    e.preventDefault()
    draggingRef.current = true
    document.body.style.cursor = 'col-resize'
    document.body.style.userSelect = 'none'
  }, [])

  useEffect(() => {
    const onMove = (e: MouseEvent) => {
      if (!draggingRef.current || !splitRef.current) return
      const rect = splitRef.current.getBoundingClientRect()
      const frac = (e.clientX - rect.left) / rect.width
      setCodeFrac(Math.max(0.12, Math.min(0.72, frac)))
    }
    const onUp = () => {
      if (!draggingRef.current) return
      draggingRef.current = false
      document.body.style.cursor = ''
      document.body.style.userSelect = ''
    }
    window.addEventListener('mousemove', onMove)
    window.addEventListener('mouseup', onUp)
    return () => {
      window.removeEventListener('mousemove', onMove)
      window.removeEventListener('mouseup', onUp)
    }
  }, [])

  const handleLoadInEditor = () => {
    if (selectedApp) {
      setCsdContent(buildFullCsd(selectedApp))
    }
  }

  const handleOpenInBrowser = async () => {
    if (!selectedApp) return
    const html = appCode || buildHtmlApp(selectedApp)
    setBrowserStatus('Opening in browser…')
    const res = await window.api?.export?.openInBrowser?.(html, selectedApp.name)
    if (res?.success) {
      setBrowserStatus('Opened in browser')
      setTimeout(() => setBrowserStatus(''), 5000)
    } else {
      setBrowserStatus(res?.error ? String(res.error).slice(0, 120) : 'Could not open browser')
    }
  }

  const studyForApp = useCallback((app: AppTemplate, html?: string): SignalFlowStudyInput => {
    const raw = html ?? app.html ?? buildHtmlApp(app)
    return {
      title: app.name,
      source: raw.includes('const ORC') ? raw : buildFullCsd(app),
    }
  }, [])

  const studyInput = useMemo(
    () => (selectedApp ? studyForApp(selectedApp, appCode || undefined) : null),
    [selectedApp, appCode, studyForApp],
  )

  return (
    <div style={styles.container}>
      {!selectedApp ? (
        /* Gallery view */
        <>
          <div style={styles.header}>
            <div style={styles.headerTitleRow}>
              <h1 style={styles.title}>Web Apps</h1>
            </div>
            <p style={styles.subtitle}>
              Interactive Csound web apps — open any card to preview, or use Study flow on each instrument for block diagrams.
            </p>
          </div>

          <div style={styles.gallery}>
            <button style={styles.newCard} onClick={() => handleSelectApp({
              id: 'new', name: 'New App', desc: '', tags: [],
              csd: '; Start your instrument here\ninstr 1\n  aOut oscili 0.5, 440\n  outs aOut, aOut\nendin',
            })}>
              <span style={styles.newIcon}>+</span>
              <span style={styles.newLabel}>New App</span>
              <span style={styles.newHint}>Start from scratch</span>
            </button>

            {REFERENCE_APPS.map((app) => (
              <div key={app.id} style={styles.card}>
                <button
                  type="button"
                  style={styles.cardMain}
                  onClick={() => handleSelectApp(app)}
                >
                  <div style={styles.cardInfo}>
                    <span style={styles.cardName}>{app.name}</span>
                    <span style={styles.cardDesc}>{app.desc}</span>
                    <div style={styles.cardTags}>
                      {app.tags.map((t) => (
                        <span key={t} style={styles.tag}>{t}</span>
                      ))}
                    </div>
                  </div>
                </button>
                <div style={styles.cardStudyRow}>
                  <StudyFlowButton
                    studyInput={studyForApp(app)}
                    variant="compact"
                    label="Study flow"
                    title={`Block diagram — ${app.name}`}
                  />
                </div>
              </div>
            ))}
          </div>
        </>
      ) : (
        /* Editor view */
        <div style={styles.editorView}>
          <div style={styles.editorToolbar}>
            <button onClick={() => setSelectedApp(null)} style={styles.backButton}>← Back</button>
            <span style={styles.appTitle}>{selectedApp.name}</span>
            <div style={styles.toolbarActions}>
              <StudyFlowButton
                studyInput={studyInput}
                label="Study flow"
                title={`Block diagram — ${selectedApp.name}`}
              />
              <button onClick={handleOpenInBrowser} style={styles.toolbarButton} title="Save HTML and open in your default browser">
                Export to Browser
              </button>
              <button onClick={handleLoadInEditor} style={styles.toolbarButton}>
                Open in CSD Editor
              </button>
              <button
                onClick={() => setShowCode((v) => !v)}
                style={showCode ? styles.toolbarButtonPrimary : styles.toolbarButton}
                title={showCode ? 'Hide the HTML source' : 'Show the HTML source'}
              >
                {showCode ? '✕ Hide Code' : '⟨⟩ Open Code'}
              </button>
            </div>
            {browserStatus && (
              <span style={styles.browserStatus}>{browserStatus}</span>
            )}
          </div>

          <div ref={splitRef} style={styles.editorSplit}>
            {showCode && (
              <>
                {/* Code (revealed on demand) */}
                <div style={{ ...styles.codePanel, flex: `0 0 ${codeFrac * 100}%` }}>
                  <div style={styles.codePanelHeader}>
                    <span style={styles.fileName}>index.html</span>
                  </div>
                  <textarea
                    value={appCode || buildHtmlApp(selectedApp)}
                    onChange={(e) => setAppCode(e.target.value)}
                    style={styles.codeArea}
                    spellCheck={false}
                  />
                </div>

                {/* Draggable splitter */}
                <div
                  style={styles.splitter}
                  onMouseDown={onSplitterDown}
                  title="Drag to resize"
                />
              </>
            )}

            {/* Live preview — full width by default, header only when sharing space */}
            <div style={{ ...styles.previewPanel, flex: 1 }}>
              {showCode && (
                <div style={styles.codePanelHeader}>
                  <span style={styles.fileName}>Preview</span>
                </div>
              )}
              <iframe
                srcDoc={appCode || buildHtmlApp(selectedApp)}
                style={styles.previewFrame}
                sandbox="allow-scripts allow-same-origin allow-forms allow-modals"
                allow="autoplay; microphone; clipboard-write"
                title={selectedApp.name}
              />
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

function buildFullCsd(app: AppTemplate): string {
  return `<CsoundSynthesizer>
<CsOptions>
-odac -d -m0
</CsOptions>
<CsInstruments>
sr = 44100
ksmps = 32
nchnls = 2
0dbfs = 1

${app.csd}

</CsInstruments>
<CsScore>
i 1 0 4 440 0.5
i 1 1 3 554 0.4
i 1 2 4 330 0.45
</CsScore>
</CsoundSynthesizer>`
}

function buildHtmlApp(app: AppTemplate): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>${app.name} — DrC Web App</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      background: #111110; color: #e8e6e1;
      font-family: 'Inter', system-ui, sans-serif;
      display: flex; flex-direction: column;
      align-items: center; padding: 40px;
      min-height: 100vh;
    }
    h1 { font-weight: 300; letter-spacing: 0.04em; margin-bottom: 8px; }
    .subtitle { color: #8a8884; font-size: 14px; margin-bottom: 32px; }
    .controls { display: flex; gap: 12px; margin-bottom: 24px; }
    button {
      padding: 10px 24px; border-radius: 10px;
      border: 1.5px solid #2a2926; background: transparent;
      color: #e8e6e1; font-size: 14px; cursor: pointer;
      font-family: inherit; transition: all 150ms ease;
    }
    button:active { transform: scale(0.96); }
    button.play { border-color: #7cb8a4; color: #7cb8a4; }
    button.play:hover { background: rgba(124,184,164,0.1); }
    canvas { border-radius: 12px; margin-top: 16px; }
  </style>
</head>
<body>
  <h1>${app.name}</h1>
  <p class="subtitle">${app.desc}</p>
  <div class="controls">
    <button class="play" onclick="startCsound()">▶ Play</button>
    <button onclick="stopCsound()">■ Stop</button>
  </div>
  <canvas id="waveform" width="600" height="120"></canvas>

  <script type="text/csound" id="csd">
${buildFullCsd(app)}
  </script>

  <script type="module">
    import { Csound } from "https://cdn.jsdelivr.net/npm/@csound/browser@7.0.0-beta31/dist/csound.js";

    let csound = null;

    window.startCsound = async () => {
      if (!csound) {
        csound = await Csound({ useWorker: false, useSPN: false, outputChannelCount: 2 });
      }
      const csd = document.getElementById('csd').textContent;
      const orcM = csd.match(/<CsInstruments>([\\s\\S]*?)<\\/CsInstruments>/i);
      const orc = orcM ? orcM[1].trim() : csd;
      await csound.setOption("-odac");
      await csound.setOption("-m0");
      const status = await csound.compileOrc(orc);
      if (status !== undefined && status !== 0) throw new Error("Csound compile failed: " + status);
      await csound.start();
    };

    window.stopCsound = async () => {
      if (csound) await csound.stop();
    };
  </script>
</body>
</html>`
}

const styles: Record<string, CSSProperties> = {
  container: { height: '100%', overflow: 'auto' },
  header: { padding: '40px 40px 0' },
  headerTitleRow: { display: 'flex', alignItems: 'center', gap: 12, marginBottom: 8 },
  title: { fontSize: 28, fontWeight: 300, color: 'var(--text-primary)', letterSpacing: '0.04em', margin: 0 },
  subtitle: { fontSize: 14, color: 'var(--text-muted)', maxWidth: 500, lineHeight: 1.5 },
  gallery: {
    display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))',
    gap: 16, padding: '32px 40px 40px',
  },
  newCard: {
    display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
    gap: 8, minHeight: 220, border: 'var(--border-width) dashed var(--border)',
    borderRadius: 'var(--panel-radius)', background: 'transparent',
    color: 'var(--text-muted)', cursor: 'pointer', transition: 'all 150ms ease',
    textAlign: 'center',
  },
  newIcon: { fontSize: 36, fontWeight: 300 },
  newLabel: { fontSize: 14, fontWeight: 500, letterSpacing: '0.04em' },
  newHint: { fontSize: 12, opacity: 0.5 },
  card: {
    display: 'flex', flexDirection: 'column', minHeight: 180,
    border: 'var(--border-width) solid var(--border)', borderRadius: 'var(--panel-radius)',
    background: 'var(--bg-secondary)', overflow: 'hidden',
    transition: 'all 150ms ease', textAlign: 'left',
  },
  cardMain: {
    display: 'flex', flex: 1, flexDirection: 'column', width: '100%',
    border: 'none', background: 'transparent', cursor: 'pointer', padding: 0, textAlign: 'left',
  },
  cardStudyRow: {
    display: 'flex', alignItems: 'center', padding: '10px 14px',
    borderTop: '1px solid var(--border-subtle)', background: 'var(--bg-tertiary)',
  },
  cardInfo: { padding: '20px 22px', display: 'flex', flexDirection: 'column', gap: 8, flex: 1, justifyContent: 'space-between' },
  cardName: { fontSize: 17, fontWeight: 500, color: 'var(--text-primary)', letterSpacing: '-0.01em' },
  cardDesc: { fontSize: 12.5, color: 'var(--text-muted)', lineHeight: 1.45, flex: 1 },
  cardTags: { display: 'flex', gap: 4, flexWrap: 'wrap', marginTop: 8 },
  tag: {
    fontSize: 10, color: 'var(--accent)', background: 'var(--accent-muted)',
    padding: '2px 8px', borderRadius: 6, fontWeight: 500,
  },
  // Editor view
  editorView: { height: '100%', display: 'flex', flexDirection: 'column' },
  editorToolbar: {
    display: 'flex', alignItems: 'center', gap: 16,
    padding: '12px 20px', borderBottom: 'var(--border-width) solid var(--border)',
  },
  backButton: {
    padding: '4px 12px', borderRadius: 6, border: 'var(--border-width) solid var(--border)',
    background: 'transparent', color: 'var(--text-secondary)', fontSize: 13,
    fontFamily: 'var(--font-primary)', cursor: 'pointer',
  },
  appTitle: { fontSize: 15, fontWeight: 500, color: 'var(--text-primary)', flex: 1 },
  toolbarActions: { display: 'flex', gap: 8 },
  browserStatus: {
    fontSize: 12,
    color: 'var(--text-muted)',
    marginLeft: 8,
    maxWidth: 280,
    overflow: 'hidden',
    textOverflow: 'ellipsis',
    whiteSpace: 'nowrap',
  },
  toolbarButton: {
    padding: '6px 16px', borderRadius: 8, border: 'var(--border-width) solid var(--border)',
    background: 'transparent', color: 'var(--text-secondary)', fontSize: 13,
    fontFamily: 'var(--font-primary)', cursor: 'pointer',
  },
  toolbarButtonPrimary: {
    padding: '6px 16px', borderRadius: 8, border: 'none',
    background: 'var(--accent)', color: 'var(--bg-primary)', fontSize: 13,
    fontWeight: 500, fontFamily: 'var(--font-primary)', cursor: 'pointer',
  },
  editorSplit: { flex: 1, display: 'flex', overflow: 'hidden', minHeight: 0 },
  codePanel: {
    display: 'flex', flexDirection: 'column', minWidth: 0, overflow: 'hidden',
  },
  splitter: {
    flex: '0 0 6px', cursor: 'col-resize',
    background: 'var(--border)',
    transition: 'background 150ms ease',
  },
  codePanelHeader: {
    padding: '8px 16px', borderBottom: 'var(--border-width) solid var(--border-subtle)',
  },
  fileName: { fontSize: 12, color: 'var(--text-muted)', fontFamily: 'var(--font-mono)' },
  codeArea: {
    flex: 1, resize: 'none', border: 'none', padding: 16,
    fontSize: 13, fontFamily: 'var(--font-mono)', lineHeight: 1.6,
    background: 'var(--bg-primary)', color: 'var(--text-primary)', outline: 'none',
    tabSize: 2,
  },
  previewPanel: { flex: 1, display: 'flex', flexDirection: 'column' },
  previewFrame: {
    flex: 1, border: 'none', background: '#111', width: '100%',
  },
}
