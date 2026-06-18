import http from 'node:http'
import https from 'node:https'
import { Log } from '../util/log'

export interface OllamaModel {
  name: string
  size?: number
}

/** Default Ollama install. LM Studio: http://127.0.0.1:1234 · llama.cpp server: http://127.0.0.1:8080 */
const DEFAULT_SERVER = 'http://127.0.0.1:11434'
const DEFAULT_MODEL = 'qwen2.5-coder:7b'

/** Host root without trailing slash or /v1 (config may include either). */
export function localLlmServerUrl(configured?: string): string {
  const raw = (configured ?? process.env.LOCAL_LLM_URL ?? process.env.OLLAMA_HOST ?? '').trim()
  let url = !raw ? DEFAULT_SERVER : raw.startsWith('http') ? raw : `http://${raw}`
  url = url.replace(/\/$/, '').replace(/\/v1$/, '')
  // Ollama often binds IPv4 only; localhost may resolve to ::1 and fail on macOS.
  url = url.replace(/^http:\/\/localhost\b/i, 'http://127.0.0.1')
  url = url.replace(/^https:\/\/localhost\b/i, 'https://127.0.0.1')
  return url
}

function isLikelyOllamaUrl(baseUrl?: string): boolean {
  const url = localLlmServerUrl(baseUrl)
  return url === DEFAULT_SERVER || /:11434$/.test(url)
}

function httpGetJson(url: string, timeoutMs: number): Promise<{ ok: boolean; data?: unknown; error?: string }> {
  return new Promise((resolve) => {
    let parsed: URL
    try {
      parsed = new URL(url)
    } catch (err: any) {
      resolve({ ok: false, error: err?.message ?? 'Invalid URL' })
      return
    }
    const lib = parsed.protocol === 'https:' ? https : http
    const req = lib.request(
      {
        hostname: parsed.hostname,
        port: parsed.port || (parsed.protocol === 'https:' ? 443 : 80),
        path: `${parsed.pathname}${parsed.search}`,
        method: 'GET',
        family: 4,
        timeout: timeoutMs,
      },
      (res) => {
        let body = ''
        res.setEncoding('utf8')
        res.on('data', (chunk) => { body += chunk })
        res.on('end', () => {
          if (!res.statusCode || res.statusCode < 200 || res.statusCode >= 300) {
            resolve({ ok: false, error: `HTTP ${res.statusCode ?? 'unknown'}` })
            return
          }
          try {
            resolve({ ok: true, data: JSON.parse(body) })
          } catch {
            resolve({ ok: false, error: 'Invalid JSON response' })
          }
        })
      },
    )
    req.on('timeout', () => {
      req.destroy()
      resolve({ ok: false, error: 'Request timed out' })
    })
    req.on('error', (err) => resolve({ ok: false, error: err.message }))
    req.end()
  })
}

/** OpenAI-compatible API root for chat completions. */
export function localLlmOpenAiBase(configured?: string): string {
  return `${localLlmServerUrl(configured)}/v1`
}

/** @deprecated use localLlmServerUrl */
export function ollamaBaseUrl(configured?: string): string {
  return localLlmServerUrl(configured)
}

async function probeOpenAiModels(baseUrl?: string): Promise<{ ok: boolean; models: OllamaModel[]; error?: string }> {
  const url = `${localLlmOpenAiBase(baseUrl)}/models`
  const res = await httpGetJson(url, 6000)
  if (!res.ok) return { ok: false, models: [], error: res.error ?? 'Server not reachable' }
  const data = res.data as { data?: { id: string }[] }
  const models = (data.data ?? [])
    .map((m) => ({ name: m.id }))
    .filter((m) => m.name)
  if (models.length === 0) return { ok: false, models: [], error: 'No models listed' }
  return { ok: true, models }
}

async function probeOllamaTags(baseUrl?: string): Promise<{ ok: boolean; models: OllamaModel[]; error?: string }> {
  const url = `${localLlmServerUrl(baseUrl)}/api/tags`
  const res = await httpGetJson(url, 6000)
  if (!res.ok) return { ok: false, models: [], error: res.error ?? 'Ollama tags API not reachable' }
  const data = res.data as { models?: { name: string; size?: number }[] }
  const models = (data.models ?? []).map((m) => ({ name: m.name, size: m.size }))
  if (models.length === 0) return { ok: false, models: [], error: 'No models listed' }
  return { ok: true, models }
}

/** Probe a local OpenAI-compatible server (/v1/models), then Ollama /api/tags as fallback. */
export async function probeLocalLlm(baseUrl?: string): Promise<{ ok: boolean; models: OllamaModel[]; error?: string }> {
  const probes = isLikelyOllamaUrl(baseUrl)
    ? [probeOllamaTags, probeOpenAiModels]
    : [probeOpenAiModels, probeOllamaTags]

  let lastError = 'Local LLM server not reachable'
  for (const probe of probes) {
    const result = await probe(baseUrl)
    if (result.ok) return result
    if (result.error) lastError = result.error
  }

  Log.warn(`Local LLM probe failed (${localLlmServerUrl(baseUrl)}): ${lastError}`)
  return { ok: false, models: [], error: lastError }
}

/** @deprecated use probeLocalLlm */
export async function probeOllama(baseUrl?: string) {
  return probeLocalLlm(baseUrl)
}

export function defaultOllamaModel(models: OllamaModel[], configured?: string): string {
  const want = (configured ?? '').trim()
  if (want && models.some((m) => m.name === want || m.name.startsWith(`${want}:`))) return want
  const coder = models.find((m) => /coder|code|llama|qwen|mistral/i.test(m.name))
  if (coder) return coder.name
  if (models.length) return models[0].name
  return DEFAULT_MODEL
}
