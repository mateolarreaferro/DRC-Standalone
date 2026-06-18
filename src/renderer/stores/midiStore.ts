import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'

// Persistent CC → channel name mapping for MIDI Learn. Keyed as
// "<port-id>:<cc#>" so two controllers with overlapping CC numbers don't
// stomp each other; falls back to "*:<cc#>" when no port is known.
//
// `learnTarget` is the channel name a knob is currently asking to bind. When
// the renderer sees the next CC arrive on any port, it stores the binding and
// clears `learnTarget`. The UI uses `learnTarget` to render the "waiting for
// CC..." pulse on the armed knob.

export interface MidiBinding {
  channel: string         // Csound chnset target (matches ChannelSpec.name)
  cc: number              // MIDI CC number (0..127)
  portId: string          // input.id from the MIDIInput, '*' = any
}

export interface MidiState {
  enabled: boolean
  inputs: { id: string; name: string; manufacturer: string }[]
  status: 'idle' | 'requesting' | 'ready' | 'denied' | 'unsupported'
  errorMessage: string
  learnTarget: string | null
  bindings: Record<string, MidiBinding>  // key = `${portId}:${cc}`
  setEnabled: (v: boolean) => void
  setInputs: (inputs: MidiState['inputs']) => void
  setStatus: (s: MidiState['status'], msg?: string) => void
  startLearn: (channel: string) => void
  cancelLearn: () => void
  bind: (cc: number, portId: string, channel: string) => void
  unbindByChannel: (channel: string) => void
  clearAll: () => void
}

const bindingKey = (portId: string, cc: number) => `${portId}:${cc}`

export const useMidiStore = create<MidiState>()(
  persist(
    (set, get) => ({
      enabled: true,
      inputs: [],
      status: 'idle',
      errorMessage: '',
      learnTarget: null,
      bindings: {},

      setEnabled: (v) => set({ enabled: v }),
      setInputs: (inputs) => set({ inputs }),
      setStatus: (status, errorMessage = '') => set({ status, errorMessage }),
      startLearn: (channel) => set({ learnTarget: channel }),
      cancelLearn: () => set({ learnTarget: null }),

      bind: (cc, portId, channel) => {
        const next = { ...get().bindings }
        // One channel can only own one CC at a time — drop any prior binding
        // that pointed to this same channel so the user gets a clean rebind.
        for (const k of Object.keys(next)) {
          if (next[k].channel === channel) delete next[k]
        }
        next[bindingKey(portId, cc)] = { channel, cc, portId }
        set({ bindings: next, learnTarget: null })
      },

      unbindByChannel: (channel) => {
        const next = { ...get().bindings }
        for (const k of Object.keys(next)) {
          if (next[k].channel === channel) delete next[k]
        }
        set({ bindings: next })
      },

      clearAll: () => set({ bindings: {}, learnTarget: null }),
    }),
    {
      name: 'drc-midi-bindings',
      storage: createJSONStorage(() => localStorage),
      // Only persist the parts that survive a session. enabled is a user
      // preference; bindings are the actual learned mappings.
      partialize: (s) => ({ enabled: s.enabled, bindings: s.bindings }) as Partial<MidiState>,
    },
  ),
)

// Look up a binding by (port, cc) — falls back to wildcard portId so bindings
// learned on one controller still respond if the user reconnects on a slightly
// different port id (browsers reuse ids but it's not guaranteed).
export function findBinding(bindings: Record<string, MidiBinding>, portId: string, cc: number): MidiBinding | undefined {
  return bindings[bindingKey(portId, cc)] ?? bindings[bindingKey('*', cc)]
}
