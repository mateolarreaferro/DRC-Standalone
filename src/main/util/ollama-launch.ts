import { execFile, spawn, type ChildProcess } from 'child_process'
import { promisify } from 'util'
import { probeLocalLlm } from '../provider/ollama'
import { Log } from './log'

const execFileAsync = promisify(execFile)

let ollamaChild: ChildProcess | null = null
let startPromise: Promise<boolean> | null = null

async function ollamaBinary(): Promise<string | null> {
  if (process.platform === 'win32') {
    try {
      const { stdout } = await execFileAsync('where', ['ollama'])
      const line = stdout.split(/\r?\n/).find((l) => l.trim())
      return line?.trim() || null
    } catch {
      return null
    }
  }
  try {
    const { stdout } = await execFileAsync('which', ['ollama'])
    return stdout.trim() || null
  } catch {
    return null
  }
}

/** Start `ollama serve` when the binary exists but nothing is listening on 11434. */
export async function ensureOllamaRunning(): Promise<boolean> {
  if (startPromise) return startPromise
  startPromise = (async () => {
    const probe = await probeLocalLlm()
    if (probe.ok) return true

    const bin = await ollamaBinary()
    if (!bin) return false

    if (!ollamaChild || ollamaChild.killed) {
      Log.info('Starting local Ollama server (ollama serve)…')
      ollamaChild = spawn(bin, ['serve'], {
        detached: true,
        stdio: 'ignore',
        env: process.env,
      })
      ollamaChild.unref()
      ollamaChild.on('error', (err) => Log.warn(`Ollama serve failed: ${err.message}`))
    }

    for (let i = 0; i < 24; i++) {
      await new Promise((r) => setTimeout(r, 500))
      const again = await probeLocalLlm()
      if (again.ok) {
        Log.info('Ollama server is reachable')
        return true
      }
    }
    Log.warn('Ollama installed but did not respond on http://127.0.0.1:11434')
    return false
  })()
  try {
    return await startPromise
  } finally {
    startPromise = null
  }
}
