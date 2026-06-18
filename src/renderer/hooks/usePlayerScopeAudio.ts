import { useEffect, useRef } from 'react'

function midiToHz(midi: number): number {
  return 440 * 2 ** ((midi - 69) / 12)
}

/** Muted oscillator bank synced to Player keyboard — drives scope / spectrum analysis. */
export function usePlayerScopeAudio(activeNotes: Set<number>, enabled: boolean) {
  const analyserRef = useRef<AnalyserNode | null>(null)
  const ctxRef = useRef<AudioContext | null>(null)
  const oscsRef = useRef<Map<number, { osc: OscillatorNode; gain: GainNode }>>(new Map())

  useEffect(() => {
    if (!enabled) return
    const ctx = new AudioContext()
    const analyser = ctx.createAnalyser()
    analyser.fftSize = 2048
    analyser.smoothingTimeConstant = 0.65
    const mute = ctx.createGain()
    mute.gain.value = 0
    analyser.connect(mute)
    mute.connect(ctx.destination)
    ctxRef.current = ctx
    analyserRef.current = analyser

    const resume = () => {
      if (ctx.state === 'suspended') void ctx.resume()
    }
    window.addEventListener('pointerdown', resume, { once: true })

    return () => {
      window.removeEventListener('pointerdown', resume)
      for (const { osc } of oscsRef.current.values()) {
        try { osc.stop() } catch { /* ignore */ }
      }
      oscsRef.current.clear()
      void ctx.close()
      ctxRef.current = null
      analyserRef.current = null
    }
  }, [enabled])

  useEffect(() => {
    const ctx = ctxRef.current
    const analyser = analyserRef.current
    if (!ctx || !analyser || !enabled) return

    for (const midi of activeNotes) {
      if (oscsRef.current.has(midi)) continue
      const osc = ctx.createOscillator()
      const gain = ctx.createGain()
      osc.type = 'triangle'
      osc.frequency.value = midiToHz(midi)
      gain.gain.value = 0.16
      osc.connect(gain)
      gain.connect(analyser)
      osc.start()
      oscsRef.current.set(midi, { osc, gain })
    }

    for (const [midi, nodes] of [...oscsRef.current.entries()]) {
      if (activeNotes.has(midi)) continue
      nodes.gain.gain.setTargetAtTime(0, ctx.currentTime, 0.015)
      nodes.osc.stop(ctx.currentTime + 0.04)
      oscsRef.current.delete(midi)
    }
  }, [activeNotes, enabled])

  return analyserRef
}
