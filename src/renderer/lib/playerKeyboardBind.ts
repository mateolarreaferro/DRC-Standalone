/**
 * QWERTY bindings for the Player on-screen keyboard (webHarness-style per octave).
 */

/** MIDI note → lowercase letter shown on the key. */
const MIDI_TO_KEY: Record<number, string> = {
  // Octave row 0 (midi 36–47)
  36: 'q', 37: '1', 38: '2', 39: '3', 40: '4', 41: '5', 42: '6', 43: '7', 44: '8', 45: '9', 46: '0', 47: '-',
  // Octave row 1 (midi 48–59)
  48: 'z', 49: 's', 50: 'x', 51: 'd', 52: 'c', 53: 'f', 54: 'v', 55: 'g', 56: 'b', 57: 'h', 58: 'n', 59: 'j',
  // Octave row 2 (midi 60–71) — matches webHarness
  60: 'a', 61: 'w', 62: 'e', 63: 'r', 64: 'd', 65: 'f', 66: 't', 67: 'g', 68: 'y', 69: 'h', 70: 'u', 71: 'j',
  // Optional upper (midi 72–83)
  72: 'k', 73: 'o', 74: 'l', 75: 'p', 76: ';', 77: "'", 78: ']', 79: '\\', 80: 'z', 81: 'x', 82: 'c', 83: 'v',
}

export function keyLabelForMidi(midi: number): string | null {
  const k = MIDI_TO_KEY[midi]
  return k ? k.toUpperCase() : null
}

export function midiInKeyboardRange(
  midi: number,
  startOctave: number,
  octaves: number,
): boolean {
  const low = startOctave * 12
  const high = (startOctave + octaves) * 12 - 1
  return midi >= low && midi <= high
}

/** Resolve a physical key to a MIDI note in the visible keyboard range. */
export function midiForKeyEvent(
  key: string,
  startOctave: number,
  octaves: number,
): number | null {
  const k = key.length === 1 ? key.toLowerCase() : key
  const low = startOctave * 12
  const high = (startOctave + octaves) * 12 - 1
  const matches: number[] = []
  for (const [midiStr, bound] of Object.entries(MIDI_TO_KEY)) {
    if (bound === k) matches.push(Number(midiStr))
  }
  const inRange = matches.filter((m) => m >= low && m <= high)
  if (inRange.length === 0) return null
  if (inRange.length === 1) return inRange[0]
  const mid = Math.floor((low + high) / 2)
  inRange.sort((a, b) => Math.abs(a - mid) - Math.abs(b - mid))
  return inRange[0]
}
