import { generateText } from 'ai'
import { Agent } from '../agent/agent'
import { Provider } from '../provider/provider'
import { Log } from '../util/log'
import { isProPlus } from '../util/tier'

const SYNTH_RE =
  /\b(fm|bell|chime|oscill|synth|foscil|carrier|modulator|additive|subtractive|wavetable|vco|pluck|pad|drone)\b/i
const FX_RE = /\b(reverb|delay|echo|filter|eq|distort|chorus|flang|compress|moog|reverbsc)\b/i

async function briefConsult(agentName: string, userPrompt: string): Promise<string> {
  const agent = Agent.get(agentName)
  if (!agent?.prompt) return ''
  const { providerID, modelID } = Provider.smallModel()
  try {
    const model = Provider.getLanguageModel(providerID, modelID)
    const { text } = await generateText({
      model: model as any,
      system:
        `${agent.prompt}\n\n` +
        'You advise the main Csound agent. Reply in ≤100 words: opcodes, rate rules, one pitfall, score tip. No CSD code.',
      prompt: userPrompt,
      temperature: 0.25,
      maxTokens: 220,
    })
    return text.trim()
  } catch (err: any) {
    Log.warn(`Sub-agent ${agentName} consult failed: ${err.message}`)
    return ''
  }
}

/** Pro+ parallel specialist briefs — synthesis and/or effects — before main generation. */
export async function consultSpecialists(userPrompt: string): Promise<string> {
  const jobs: Array<Promise<{ label: string; text: string }>> = []

  if (SYNTH_RE.test(userPrompt)) {
    jobs.push(
      briefConsult('csound-synthesis', userPrompt).then((text) => ({ label: 'synthesis', text })),
    )
  }

  if (!isProPlus()) {
    const results = await Promise.all(jobs)
    return results
      .filter((r) => r.text.length > 0)
      .map((r) => `<specialist-${r.label}>\n${r.text}\n</specialist-${r.label}>`)
      .join('\n')
  }

  if (FX_RE.test(userPrompt)) {
    jobs.push(
      briefConsult('csound-effects', userPrompt).then((text) => ({ label: 'effects', text })),
    )
  }
  if (/\b(lfo|envelope|adsr|linseg|expseg|control|modulat|sequenc|metro|sched)\b/i.test(userPrompt)) {
    jobs.push(
      briefConsult('csound-modulation', userPrompt).then((text) => ({ label: 'modulation', text })),
    )
  }

  if (jobs.length === 0) {
    jobs.push(
      briefConsult('csound-synthesis', userPrompt).then((text) => ({ label: 'synthesis', text })),
    )
  }

  const results = await Promise.all(jobs)
  const parts = results
    .filter((r) => r.text.length > 0)
    .map((r) => `<specialist-${r.label}>\n${r.text}\n</specialist-${r.label}>`)

  return parts.join('\n')
}
