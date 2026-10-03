import { useEffect, useRef } from 'react'
import { useMidiStore, findBinding, type MidiBinding } from '../stores/midiStore'

// Lightweight structural types for Web MIDI. We don't import lib.dom's
// MIDIAccess directly because some TS lib targets don't include it; instead
// we type only the fields we actually touch and feed them via `unknown` casts.
interface MIDIMessageLike {
  data: Uint8Array | null
}
interface MIDIInputLike {
  id: string
  name: string | null
  manufacturer: string | null
  state: 'connected' | 'disconnected'
  onmidimessage: ((ev: MIDIMessageLike) => void) | null
}
interface MIDIPortStateChangeEvent {
  port: { type: 'input' | 'output' }
}
interface MIDIAccessLike {
  inputs: { values(): IterableIterator<MIDIInputLike> }
  onstatechange: ((ev: MIDIPortStateChangeEvent) => void) | null
}

export interface MidiHandlers {
  onNoteOn: (midi: number, velocity: number) => void
  onNoteOff: (midi: number) => void
  onCC?: (cc: number, value: number, portId: string) => void
}

// `useMidi` wires Web MIDI to the supplied note/CC callbacks and routes CC
// messages through MIDI Learn: an armed knob captures the next CC, otherwise
// CCs flow to the channel they're already bound to.
//
// The hook owns the lifetime of `onmidimessage` per input — it reattaches when
// the device list changes so hot-plug works without a refresh.
export function useMidi(
  handlers: MidiHandlers,
  knobChange: (channel: string, normalized: number) => void,
  /** Re-attach Web MIDI inputs when the Player engine goes live (hot-plug after csound start). */
  engineLive = true,
): void {
  const setStatus = useMidiStore((s) => s.setStatus)
  const setInputs = useMidiStore((s) => s.setInputs)
  const enabled = useMidiStore((s) => s.enabled)
  const handlersRef = useRef(handlers)
  const knobChangeRef = useRef(knobChange)
  handlersRef.current = handlers
  knobChangeRef.current = knobChange

  const accessRef = useRef<MIDIAccessLike | null>(null)
  const bindInputsRef = useRef<(() => void) | null>(null)

  useEffect(() => {
    if (!enabled) {
      setStatus('idle')
      accessRef.current = null
      bindInputsRef.current = null
      return
    }

    const nav = navigator as unknown as {
      requestMIDIAccess?: (opts?: { sysex?: boolean }) => Promise<unknown>
    }
    if (typeof nav.requestMIDIAccess !== 'function') {
      setStatus('unsupported', 'Web MIDI API unavailable in this browser')
      return
    }

    let cancelled = false

    const handleMessage = (portId: string) => (ev: MIDIMessageLike) => {
      const data = ev.data
      if (!data || data.length < 2) return
      const status = data[0] & 0xf0
      if (status === 0x90 && data[2] > 0) {
        handlersRef.current.onNoteOn(data[1], data[2] / 127)
        return
      }
      if (status === 0x80 || (status === 0x90 && data[2] === 0)) {
        handlersRef.current.onNoteOff(data[1])
        return
      }
      if (status === 0xb0) {
        const cc = data[1]
        const value = data[2] / 127
        const state = useMidiStore.getState()
        if (state.learnTarget) {
          state.bind(cc, portId, state.learnTarget)
          return
        }
        const binding: MidiBinding | undefined = findBinding(state.bindings, portId, cc)
        if (binding) {
          knobChangeRef.current(binding.channel, value)
          return
        }
        handlersRef.current.onCC?.(cc, value, portId)
      }
    }

    const bindInputs = () => {
      const access = accessRef.current
      if (!access || cancelled) return
      const list: { id: string; name: string; manufacturer: string }[] = []
      for (const input of access.inputs.values()) {
        list.push({
          id: input.id,
          name: input.name ?? input.id,
          manufacturer: input.manufacturer ?? '',
        })
        input.onmidimessage = handleMessage(input.id)
      }
      setInputs(list)
    }
    bindInputsRef.current = bindInputs

    setStatus('requesting')
    nav.requestMIDIAccess({ sysex: false })
      .then((acc) => {
        if (cancelled) return
        accessRef.current = acc as MIDIAccessLike
        accessRef.current.onstatechange = (ev: MIDIPortStateChangeEvent) => {
          if (ev.port.type === 'input') bindInputs()
        }
        bindInputs()
        setStatus('ready')
      })
      .catch((err: unknown) => {
        if (cancelled) return
        const msg = err instanceof Error ? err.message : String(err)
        setStatus('denied', msg)
      })

    return () => {
      cancelled = true
      bindInputsRef.current = null
      const access = accessRef.current
      if (access) {
        for (const input of access.inputs.values()) input.onmidimessage = null
        access.onstatechange = null
      }
      accessRef.current = null
    }
  }, [enabled, setInputs, setStatus])

  useEffect(() => {
    if (!enabled || !engineLive) return
    bindInputsRef.current?.()
  }, [enabled, engineLive])
}
