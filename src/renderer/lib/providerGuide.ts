/** Shared copy + helpers for API provider setup and free-tier limits. */

export const OPENROUTER_OPTION = {
  id: 'openrouter' as const,
  label: 'OpenRouter',
  tier: 'One key · many models',
  signupUrl: 'https://openrouter.ai/keys',
  signupLabel: 'openrouter.ai/keys',
  keyPlaceholder: 'sk-or-...',
  hint:
    'Simplest paid path — one key routes to Claude, GPT, Gemini, Llama, and more. ' +
    'Add credits at openrouter.ai. Dr.C uses Claude Sonnet for Agent and Gemini Flash for narration.',
}

export interface ProviderOption {
  id: 'google' | 'groq' | 'anthropic' | 'openai'
  label: string
  /** Short badge, e.g. "Free tier" */
  tier: string
  free: boolean
  signupUrl: string
  signupLabel: string
  keyPlaceholder: string
  hint: string
  /** When this is the only configured provider */
  soloWarning: string
}

export const PROVIDER_OPTIONS: ProviderOption[] = [
  {
    id: 'groq',
    label: 'Groq',
    tier: 'Free tier',
    free: true,
    signupUrl: 'https://console.groq.com/keys',
    signupLabel: 'console.groq.com/keys',
    keyPlaceholder: 'gsk_...',
    hint: 'Free tier — Dr.C tries Groq first when both free keys are saved. For best Agent results, use your own Anthropic, OpenAI, or OpenRouter key.',
    soloWarning:
      'Groq\'s free tier has rate limits (~30 requests/minute). Wait for the countdown, then Try again. ' +
      'Add a Gemini key in Settings as backup — Dr.C switches automatically. Your own paid API key works best.',
  },
  {
    id: 'google',
    label: 'Google AI (Gemini)',
    tier: 'Free tier or paid',
    free: true,
    signupUrl: 'https://aistudio.google.com/apikey',
    signupLabel: 'aistudio.google.com/apikey',
    keyPlaceholder: 'AIza...',
    hint: 'Same AI Studio key for free or paid — enable billing there for higher quotas. Dr.C falls back to Groq when throttled (if both keys are saved). Anthropic/OpenAI is stronger for teaching.',
    soloWarning:
      'Gemini\'s free tier has rate limits (~20 requests/minute). Wait for the countdown, then Try again. ' +
      'Add a Groq key as backup — Dr.C switches automatically. Your own paid API key works best.',
  },
  {
    id: 'anthropic',
    label: 'Anthropic (Claude)',
    tier: 'Paid credits',
    free: false,
    signupUrl: 'https://console.anthropic.com/settings/keys',
    signupLabel: 'console.anthropic.com',
    keyPlaceholder: 'sk-ant-...',
    hint: 'Recommended for teaching — your own API key gives the best Csound output.',
    soloWarning: '',
  },
  {
    id: 'openai',
    label: 'OpenAI',
    tier: 'Paid credits',
    free: false,
    signupUrl: 'https://platform.openai.com/api-keys',
    signupLabel: 'platform.openai.com',
    keyPlaceholder: 'sk-...',
    hint: 'Your own API key — strong alternative to Anthropic for Complex mode.',
    soloWarning: '',
  },
]

export function providerOption(id: string): ProviderOption | undefined {
  return PROVIDER_OPTIONS.find((p) => p.id === id)
}

/** True when the user only has free-tier providers configured (typical student / try-before-buy setup). */
export function isFreeTierOnly(available: string[]): boolean {
  if (available.length === 0) return false
  return available.every((id) => id === 'ollama' || providerOption(id)?.free === true)
}

/** True when only one provider is configured and it is a free tier. */
export function isSoloFreeProvider(available: string[]): boolean {
  if (available.length !== 1) return false
  if (available[0] === 'ollama') return true
  const p = providerOption(available[0])
  return p?.free === true
}

const QUOTA_RE =
  /quota|rate limit|429|resource_exhausted|returned no output|exceeded your current/i

export function isQuotaError(message: string): boolean {
  return QUOTA_RE.test(message)
}

/** Parse suggested retry delay from provider error text; default 60s. */
export function parseQuotaRetryMs(message: string): number {
  const msMatch = message.match(/retry in (\d+(?:\.\d+)?)\s*ms/i)
  if (msMatch) return Math.max(1000, Math.ceil(parseFloat(msMatch[1])))
  const secMatch = message.match(/retry in (\d+(?:\.\d+)?)\s*s(?:ec)?/i)
  if (secMatch) return Math.max(1000, Math.ceil(parseFloat(secMatch[1]) * 1000))
  const waitSec = message.match(/wait (\d+) seconds?/i)
  if (waitSec) return parseInt(waitSec[1], 10) * 1000
  const waitMin = message.match(/wait (\d+) minute/i)
  if (waitMin) return parseInt(waitMin[1], 10) * 60_000
  return 60_000
}

export function formatCountdown(msRemaining: number): string {
  const totalSec = Math.max(0, Math.ceil(msRemaining / 1000))
  const m = Math.floor(totalSec / 60)
  const s = totalSec % 60
  return m > 0 ? `${m}:${s.toString().padStart(2, '0')}` : `${s}s`
}

/** Local LLM options for setup handouts and Settings copy. */
export const LOCAL_LLM_OPTIONS = [
  {
    id: 'ollama',
    label: 'Ollama',
    recommended: true,
    downloadUrl: 'https://ollama.com/download',
    libraryUrl: 'https://ollama.com/library',
    models: [
      { name: 'qwen2.5-coder:7b', ram: '~8 GB', note: 'Default — best for Csound/code' },
      { name: 'qwen2.5-coder:3b', ram: '~4 GB', note: 'Smaller laptops' },
      { name: 'llama3.2:3b', ram: '~4 GB', note: 'Fast general model' },
    ],
    setup: 'Install Ollama → ollama pull <model> → Settings → Use Ollama for Agent',
  },
  {
    id: 'lmstudio',
    label: 'LM Studio',
    recommended: false,
    downloadUrl: 'https://lmstudio.ai/',
    serverUrl: 'http://127.0.0.1:1234',
    note: 'Load a model → start Local Server → set Server URL in Settings → Local LLM server',
  },
] as const
