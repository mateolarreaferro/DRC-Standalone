import { createAnthropic } from '@ai-sdk/anthropic'
import { createOpenAI } from '@ai-sdk/openai'
import { createGoogleGenerativeAI } from '@ai-sdk/google'
import { generateText, type LanguageModelV1 } from 'ai'
import { Log } from '../util/log'
import { defaultOllamaModel, localLlmOpenAiBase, probeOllama } from './ollama'
import { isProPlus } from '../util/tier'

interface ProviderConfig {
  openrouterKey?: string
  anthropicKey?: string
  openaiKey?: string
  googleKey?: string
  groqKey?: string
  ollamaEnabled?: boolean
  ollamaModel?: string
  ollamaBaseUrl?: string
  preferOllama?: boolean
}

// Free AI Studio keys resolve against the Gemini Developer API. Pin it so an
// SDK default change can't silently re-point us at v1 or Vertex.
const GOOGLE_BASE_URL = 'https://generativelanguage.googleapis.com/v1beta'
const OPENROUTER_BASE_URL = 'https://openrouter.ai/api/v1'

let config: ProviderConfig = {}
let ollamaReachable = false
let ollamaModels: string[] = []
const modelCache = new Map<string, LanguageModelV1>()

export namespace Provider {
  export function configure(cfg: ProviderConfig) {
    config = { ...config, ...cfg }
    modelCache.clear()
  }

  export async function refreshOllamaStatus(forceProbe = false): Promise<{ ok: boolean; models: string[] }> {
    // Keep the last probe result when disabled so Settings Test/Refresh is not
    // wiped by unrelated getApiKeys calls before the user turns local LLM on.
    if (!config.ollamaEnabled && !forceProbe) {
      return { ok: ollamaReachable, models: ollamaModels }
    }
    const probe = await probeOllama(config.ollamaBaseUrl)
    ollamaReachable = probe.ok
    ollamaModels = probe.models.map((m) => m.name)
    if (probe.ok && !config.ollamaModel) {
      config.ollamaModel = defaultOllamaModel(probe.models)
    }
    return { ok: probe.ok, models: ollamaModels }
  }

  export function ollamaStatus(): { enabled: boolean; ok: boolean; models: string[]; model?: string } {
    return {
      enabled: Boolean(config.ollamaEnabled),
      ok: ollamaReachable,
      models: ollamaModels,
      model: config.ollamaModel,
    }
  }

  function ollamaAvailable(): boolean {
    if (!config.ollamaEnabled) return false
    const model = config.ollamaModel?.trim() || ollamaModels[0]
    if (!model) return false
    // Prefer a live probe, but allow a saved model when the server is temporarily down.
    return ollamaReachable || Boolean(config.ollamaModel?.trim())
  }

  export function getLanguageModel(providerID: string, modelID: string): LanguageModelV1 {
    const cacheKey = `${providerID}:${modelID}`
    if (modelCache.has(cacheKey)) return modelCache.get(cacheKey)!

    let model: LanguageModelV1

    switch (providerID) {
      case 'openrouter': {
        const apiKey = config.openrouterKey || process.env.OPENROUTER_API_KEY
        if (!apiKey) {
          throw new Error(
            'OpenRouter API key not configured. Get one at https://openrouter.ai/keys and set it in Settings.',
          )
        }
        const openrouter = createOpenAI({
          apiKey,
          baseURL: OPENROUTER_BASE_URL,
          headers: {
            'HTTP-Referer': 'https://github.com/mateolarreaferro/Dr.C-Standalone',
            'X-Title': 'Dr.C',
          },
        })
        model = openrouter(modelID) as unknown as LanguageModelV1
        break
      }
      case 'google': {
        const apiKey = config.googleKey || process.env.GOOGLE_GENERATIVE_AI_API_KEY || process.env.GEMINI_API_KEY
        if (!apiKey) throw new Error('Google AI API key not configured. Get a free key at https://aistudio.google.com/apikey and set it in Settings.')
        const google = createGoogleGenerativeAI({ apiKey, baseURL: GOOGLE_BASE_URL })
        model = google(modelID) as unknown as LanguageModelV1
        break
      }
      case 'anthropic': {
        const apiKey = config.anthropicKey || process.env.ANTHROPIC_API_KEY
        if (!apiKey) throw new Error('Anthropic API key not configured. Set it in Settings.')
        const anthropic = createAnthropic({ apiKey })
        model = anthropic(modelID) as unknown as LanguageModelV1
        break
      }
      case 'openai': {
        const apiKey = config.openaiKey || process.env.OPENAI_API_KEY
        if (!apiKey) throw new Error('OpenAI API key not configured. Set it in Settings.')
        const openai = createOpenAI({ apiKey })
        model = openai(modelID) as unknown as LanguageModelV1
        break
      }
      case 'groq': {
        const apiKey = config.groqKey || process.env.GROQ_API_KEY
        if (!apiKey) {
          throw new Error(
            'Groq API key not configured. Get a free key at https://console.groq.com/keys and set it in Settings.',
          )
        }
        const groq = createOpenAI({ apiKey, baseURL: 'https://api.groq.com/openai/v1' })
        model = groq(modelID) as unknown as LanguageModelV1
        break
      }
      case 'ollama': {
        const baseURL = localLlmOpenAiBase(config.ollamaBaseUrl)
        const ollama = createOpenAI({ apiKey: 'local', baseURL })
        model = ollama(modelID) as unknown as LanguageModelV1
        break
      }
      default:
        throw new Error(`Unknown provider: ${providerID}. Supported: openrouter, google, groq, anthropic, openai, ollama`)
    }

    assertV1(providerID, model)
    modelCache.set(cacheKey, model)
    Log.info(`Loaded model ${providerID}/${modelID}`)
    return model
  }

  // Check which providers are available
  export function availableProviders(): string[] {
    const available: string[] = []
    if (hasOpenRouter()) available.push('openrouter')
    if (ollamaAvailable()) available.push('ollama')
    if (hasGroq()) available.push('groq')
    if (hasGoogle()) available.push('google')
    if (config.anthropicKey || process.env.ANTHROPIC_API_KEY) available.push('anthropic')
    if (config.openaiKey || process.env.OPENAI_API_KEY) available.push('openai')
    return available
  }

  export function isConfigured(): boolean {
    return availableProviders().length > 0
  }

  function hasGoogle(): boolean {
    return Boolean(config.googleKey || process.env.GOOGLE_GENERATIVE_AI_API_KEY || process.env.GEMINI_API_KEY)
  }

  function hasOpenRouter(): boolean {
    return Boolean(config.openrouterKey || process.env.OPENROUTER_API_KEY)
  }

  function hasGroq(): boolean {
    return Boolean(config.groqKey || process.env.GROQ_API_KEY)
  }

  export function tierLabel(): string {
    return isProPlus() ? 'Pro+' : 'Standard'
  }

  export function providerLabel(providerID: string): string {
    if (providerID === 'openrouter') return 'OpenRouter'
    if (providerID === 'google') return 'Gemini'
    if (providerID === 'groq') return 'Groq'
    if (providerID === 'ollama') return 'Ollama (local)'
    if (providerID === 'anthropic') return 'Anthropic'
    if (providerID === 'openai') return 'OpenAI'
    return providerID
  }

  /** True when another provider in the chain may succeed (quota / empty output). */
  export function shouldTryNextProvider(err: unknown, emptyStream: boolean): boolean {
    if (emptyStream) return true
    const raw = err instanceof Error ? err.message : String(err ?? '')
    const lower = raw.toLowerCase()
    return (
      lower.includes('quota') ||
      lower.includes('rate limit') ||
      lower.includes('429') ||
      lower.includes('resource_exhausted') ||
      lower.includes('exceeded') ||
      lower.includes('returned no output')
    )
  }

  function mainModelFor(providerID: string): string {
    if (providerID === 'openrouter') return 'anthropic/claude-sonnet-4'
    if (providerID === 'groq') return 'llama-3.3-70b-versatile'
    if (providerID === 'google') return isProPlus() ? 'gemini-2.5-pro' : 'gemini-2.5-flash'
    if (providerID === 'ollama') return config.ollamaModel || ollamaModels[0] || 'qwen2.5-coder:7b'
    if (providerID === 'anthropic') return 'claude-sonnet-4-5'
    if (providerID === 'openai') return 'gpt-4.1'
    return 'gemini-2.5-flash'
  }

  function smallModelFor(providerID: string): string {
    if (providerID === 'openrouter') return 'google/gemini-2.5-flash'
    if (providerID === 'groq') return 'llama-3.1-8b-instant'
    if (providerID === 'google') return 'gemini-2.5-flash'
    if (providerID === 'ollama') return config.ollamaModel || ollamaModels[0] || 'qwen2.5-coder:7b'
    if (providerID === 'anthropic') return 'claude-haiku-4-5'
    if (providerID === 'openai') return 'gpt-4.1-mini'
    return 'gemini-2.5-flash'
  }

  /** Ordered providers to try — primary first, then alternate free keys, then paid/local. */
  export function providerChain(
    primary: { providerID: string; modelID: string },
    size: 'main' | 'small' = 'main',
  ): Array<{ providerID: string; modelID: string }> {
    const chain: Array<{ providerID: string; modelID: string }> = []
    const seen = new Set<string>()
    const pick = (providerID: string) =>
      size === 'small' ? smallModelFor(providerID) : mainModelFor(providerID)

    const add = (providerID: string, modelID?: string) => {
      const mid = modelID ?? pick(providerID)
      const key = `${providerID}:${mid}`
      if (seen.has(key)) return
      seen.add(key)
      chain.push({ providerID, modelID: mid })
    }

    add(primary.providerID, primary.modelID)

    if (hasOpenRouter() && primary.providerID !== 'openrouter') add('openrouter')
    if ((config.anthropicKey || process.env.ANTHROPIC_API_KEY) && primary.providerID !== 'anthropic') {
      add('anthropic')
    }
    if ((config.openaiKey || process.env.OPENAI_API_KEY) && primary.providerID !== 'openai') {
      add('openai')
    }
    if (hasGroq() && primary.providerID !== 'groq') add('groq')
    if (hasGoogle() && primary.providerID !== 'google') add('google')
    if (ollamaAvailable() && primary.providerID !== 'ollama') add('ollama')

    return chain
  }

  export function defaultProvider(): { providerID: string; modelID: string } {
    if (hasOpenRouter()) {
      return { providerID: 'openrouter', modelID: 'anthropic/claude-sonnet-4' }
    }
    if (config.anthropicKey || process.env.ANTHROPIC_API_KEY) {
      return { providerID: 'anthropic', modelID: 'claude-sonnet-4-5' }
    }
    if (config.openaiKey || process.env.OPENAI_API_KEY) {
      return { providerID: 'openai', modelID: 'gpt-4.1' }
    }
    if (config.preferOllama && ollamaAvailable()) {
      return { providerID: 'ollama', modelID: config.ollamaModel || ollamaModels[0] || 'qwen2.5-coder:7b' }
    }
    if (hasGroq()) {
      return { providerID: 'groq', modelID: 'llama-3.3-70b-versatile' }
    }
    if (hasGoogle()) {
      return { providerID: 'google', modelID: isProPlus() ? 'gemini-2.5-pro' : 'gemini-2.5-flash' }
    }
    if (ollamaAvailable()) {
      return { providerID: 'ollama', modelID: config.ollamaModel || ollamaModels[0] || 'qwen2.5-coder:7b' }
    }
    throw new Error(
      'No Agent provider configured. Add an OpenRouter key, a direct API key, enable Ollama, or use Web Apps / workshop demos (no key).',
    )
  }

  // Small/fast model for narration, summaries, sine mode.
  export function smallModel(): { providerID: string; modelID: string } {
    if (hasOpenRouter()) {
      return { providerID: 'openrouter', modelID: 'google/gemini-2.5-flash' }
    }
    if (config.anthropicKey || process.env.ANTHROPIC_API_KEY) {
      return { providerID: 'anthropic', modelID: 'claude-haiku-4-5' }
    }
    if (config.openaiKey || process.env.OPENAI_API_KEY) {
      return { providerID: 'openai', modelID: 'gpt-4.1-mini' }
    }
    if (config.preferOllama && ollamaAvailable()) {
      return { providerID: 'ollama', modelID: config.ollamaModel || ollamaModels[0] || 'qwen2.5-coder:7b' }
    }
    if (hasGroq()) {
      return { providerID: 'groq', modelID: 'llama-3.1-8b-instant' }
    }
    if (hasGoogle()) {
      return { providerID: 'google', modelID: 'gemini-2.5-flash' }
    }
    if (ollamaAvailable()) {
      return { providerID: 'ollama', modelID: config.ollamaModel || ollamaModels[0] || 'qwen2.5-coder:7b' }
    }
    return { providerID: 'groq', modelID: 'llama-3.1-8b-instant' }
  }

  // The whole app runs on AI SDK 4, which only drives spec-version "v1" models.
  // If an `@ai-sdk/*` package is ever pulled at a 2.x/3.x (AI SDK 5) version, its
  // models advertise "v2" and streamText throws the opaque "upgrade to AI SDK 5"
  // error on EVERY turn — the exact bug that bricked Gemini. Catch it here, at
  // model-load time, with a message that tells the user what to actually do.
  function assertV1(providerID: string, model: LanguageModelV1): void {
    const spec = (model as { specificationVersion?: string }).specificationVersion
    if (spec && spec !== 'v1') {
      throw new Error(
        `The ${providerID} integration is on an incompatible version (model spec "${spec}"; this build needs "v1"). ` +
        `This is a packaging bug, not your key. Switch to another provider in Settings, or reinstall the app.`,
      )
    }
  }

  // streamText can complete with zero chunks (no throw) when Gemini quota is hit.
  export function emptyStreamMessage(providerID: string): string {
    if (providerID === 'google') {
      return (
        'Gemini returned no output. Wait for the countdown and try again. ' +
        'Dr.C will try Groq automatically if that key is saved. For better sound design, use your own Anthropic or OpenAI key.'
      )
    }
    if (providerID === 'groq') {
      return (
        'Groq returned no output. Wait for the countdown and try again. ' +
        'Dr.C will try Gemini automatically if that key is saved. For better sound design, use your own Anthropic or OpenAI key.'
      )
    }
    if (providerID === 'ollama') {
      return (
        'Ollama returned no output. Check the server is running, the model is loaded, and Settings → Local LLM server ' +
        '(URL + model). Ollama: ollama pull qwen2.5-coder:7b · LM Studio: load a model and start the server.'
      )
    }
    return (
      'The model returned no output. Check your API key in Settings, wait a moment, and try again.'
    )
  }

  export function humanizeError(providerID: string, err: unknown): string {
    const raw = err instanceof Error ? err.message : String(err)
    const lower = raw.toLowerCase()

    // SDK version mismatch (see assertV1) — surfaces from streamText if a model
    // slips past the load-time guard. Tell the user to switch providers, since
    // no API key change can fix a packaging mismatch.
    if (lower.includes('specification version') || lower.includes('upgrade to ai sdk')) {
      return `The ${providerID} integration is on an incompatible SDK version in this build. Switch to another provider in Settings while this is fixed.`
    }

    if (providerID === 'google') {
      if (lower.includes('api_key_invalid') || lower.includes('api key not valid')) {
        return 'Invalid Gemini API key. Get a free one at aistudio.google.com/apikey.'
      }
      if (lower.includes('is not found for api version') || (lower.includes('not found') && lower.includes('model'))) {
        return 'This Gemini model is not available on the free Gemini Developer API. Use a gemini-2.5-* model, or check that the key is from aistudio.google.com (not Vertex AI).'
      }
      if (lower.includes('permission_denied') || lower.includes('permission denied')) {
        return 'Permission denied. The key may be a Vertex AI credential — the free tier needs a key from aistudio.google.com/apikey.'
      }
      if (lower.includes('resource_exhausted') || lower.includes('quota')) {
        return 'Gemini rate limit reached. Wait for the countdown. Dr.C will try Groq automatically if that key is saved in Settings.'
      }
    }

    if (providerID === 'groq') {
      if (lower.includes('invalid') && lower.includes('api')) {
        return 'Invalid Groq API key. Get a free one at console.groq.com/keys.'
      }
      if (lower.includes('rate limit') || lower.includes('429') || lower.includes('quota')) {
        return 'Groq rate limit reached. Wait for the countdown. Dr.C will try Gemini automatically if that key is saved in Settings.'
      }
    }

    if (providerID === 'ollama') {
      if (lower.includes('connection') || lower.includes('fetch') || lower.includes('econnrefused')) {
        return (
          'Cannot reach the local LLM server. Ollama: ollama.com · LM Studio: start the local server on port 1234 · ' +
          'Check Settings → Local LLM server → Server URL.'
        )
      }
      if (lower.includes('not found') && lower.includes('model')) {
        return `Model not found on local server. Pick a loaded model in Settings, or pull one (Ollama: ollama pull ${config.ollamaModel || 'qwen2.5-coder:7b'})`
      }
    }

    if (providerID === 'anthropic') {
      if (lower.includes('authentication') || lower.includes('invalid x-api-key') || lower.includes('invalid api key')) {
        return 'Invalid Anthropic API key. Check it at console.anthropic.com/settings/keys.'
      }
      if (lower.includes('credit balance') || lower.includes('insufficient')) {
        return 'Anthropic account is out of credits.'
      }
    }

    if (providerID === 'openai') {
      if (lower.includes('invalid_api_key') || lower.includes('incorrect api key')) {
        return 'Invalid OpenAI API key. Check it at platform.openai.com/api-keys.'
      }
      if (lower.includes('insufficient_quota') || lower.includes('exceeded your current quota')) {
        return 'OpenAI account is out of quota.'
      }
    }

    if (providerID === 'openrouter') {
      if (lower.includes('invalid') && lower.includes('api')) {
        return 'Invalid OpenRouter API key. Get one at openrouter.ai/keys.'
      }
      if (lower.includes('insufficient') || lower.includes('credit') || lower.includes('balance')) {
        return 'OpenRouter account needs credits — add funds at openrouter.ai/credits.'
      }
      if (lower.includes('not found') && lower.includes('model')) {
        return 'This model is not available on OpenRouter. Dr.C uses anthropic/claude-sonnet-4 by default — check openrouter.ai/models.'
      }
    }

    // Fall back to the first line of the raw message so we don't dump a stack.
    const firstLine = raw.split('\n')[0].trim()
    return firstLine.length > 200 ? firstLine.slice(0, 200) + '…' : firstLine
  }

  export async function testApiKey(providerID: string): Promise<{ ok: boolean; message: string }> {
    try {
      const { modelID } = pickTestModel(providerID)
      const model = getLanguageModel(providerID, modelID)
      const result = await generateText({ model, prompt: 'Reply with exactly: OK', maxTokens: 16 })
      if (!result.text.trim()) {
        return {
          ok: false,
          message:
            `${providerLabel(providerID)} accepted the key but returned no text — usually rate limit or quota. ` +
            'Wait a minute and try again, or use another provider.',
        }
      }
      return { ok: true, message: `${providerLabel(providerID)} key works (${modelID}).` }
    } catch (err) {
      return { ok: false, message: humanizeError(providerID, err) }
    }
  }

  export async function testOllama(): Promise<{ ok: boolean; message: string }> {
    const status = await refreshOllamaStatus(true)
    if (!status.ok) {
      return { ok: false, message: 'Local LLM server is not running. Set Server URL in Settings (Ollama, LM Studio, or llama.cpp server).' }
    }
    const prevEnabled = config.ollamaEnabled
    config.ollamaEnabled = true
    const modelID = config.ollamaModel || defaultOllamaModel(status.models.map((n) => ({ name: n })))
    try {
      const model = getLanguageModel('ollama', modelID)
      const result = await generateText({ model, prompt: 'Reply with exactly: OK', maxTokens: 16 })
      if (!result.text.trim()) {
        return { ok: false, message: 'Ollama responded but returned no text. Check the model is fully pulled.' }
      }
      return { ok: true, message: `Ollama works (${modelID}).` }
    } catch (err) {
      return { ok: false, message: humanizeError('ollama', err) }
    } finally {
      config.ollamaEnabled = prevEnabled
    }
  }

  function pickTestModel(providerID: string): { modelID: string } {
    switch (providerID) {
      case 'openrouter': return { modelID: 'google/gemini-2.5-flash' }
      case 'google': return { modelID: 'gemini-2.5-flash' }
      case 'groq': return { modelID: 'llama-3.1-8b-instant' }
      case 'anthropic': return { modelID: 'claude-haiku-4-5' }
      case 'openai': return { modelID: 'gpt-4.1-mini' }
      case 'ollama': return { modelID: config.ollamaModel || ollamaModels[0] || 'qwen2.5-coder:7b' }
      default: throw new Error(`Unknown provider: ${providerID}`)
    }
  }
}
