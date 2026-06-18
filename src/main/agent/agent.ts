import { z } from 'zod'
// Inline prompt text at bundle time via Vite's ?raw suffix. Runtime file reads
// break once the main process is bundled because the prompts/ folder isn't
// copied into out/main — inlining avoids the whole class of resolution bugs.
import csoundPromptText from './prompts/csound.txt?raw'
import csoundSinePromptText from './prompts/csound-sine.txt?raw'
import csoundSynthesisPromptText from './prompts/csound-synthesis.txt?raw'
import csoundEffectsPromptText from './prompts/csound-effects.txt?raw'
import csoundModulationPromptText from './prompts/csound-modulation.txt?raw'
import authoritativeSourcesText from './prompts/authoritative-sources.txt?raw'
import demoScorePromptText from './prompts/demo-score.txt?raw'
import narratorPromptText from './prompts/narrator.txt?raw'

const PROMPTS: Record<string, string> = {
  csound: `${csoundPromptText}\n\n${authoritativeSourcesText}\n\n${demoScorePromptText}`,
  'csound-sine': `${csoundSinePromptText}\n\n${authoritativeSourcesText}\n\n${demoScorePromptText}`,
  'csound-synthesis': csoundSynthesisPromptText,
  'csound-effects': csoundEffectsPromptText,
  'csound-modulation': csoundModulationPromptText,
  narrator: narratorPromptText,
}

function loadPrompt(name: string): string {
  return PROMPTS[name] ?? ''
}

export namespace Agent {
  export const Info = z.object({
    name: z.string(),
    description: z.string().optional(),
    mode: z.enum(['subagent', 'primary', 'all']),
    hidden: z.boolean().optional(),
    topP: z.number().optional(),
    temperature: z.number().optional(),
    color: z.string().optional(),
    model: z.object({
      modelID: z.string(),
      providerID: z.string(),
    }).optional(),
    prompt: z.string().optional(),
    options: z.record(z.string(), z.any()).default({}),
    steps: z.number().int().positive().optional(),
  })
  export type Info = z.infer<typeof Info>

  // Built-in agent definitions
  // Default: Gemini 2.5 Flash (free). Upgrades to Claude if Anthropic key is set.
  const AGENTS: Record<string, Info> = {
    csound: {
      name: 'csound',
      description: 'Full Csound design specialist with RAG, sub-agents, and design exploration',
      mode: 'primary',
      // Model resolved at runtime via Provider.defaultProvider()
      model: undefined,
      prompt: loadPrompt('csound'),
      color: '#7cb8a4',
      options: { designMode: true },
    },
    'csound-sine': {
      name: 'csound-sine',
      description: 'Lightweight Csound agent for quick edits and parameter tweaks',
      mode: 'primary',
      model: undefined, // Resolved at runtime via Provider.smallModel()
      prompt: loadPrompt('csound-sine'),
      color: '#f0b27a',
      options: { designMode: true, sineMode: true },
    },
    'csound-synthesis': {
      name: 'csound-synthesis',
      description: 'Sub-agent specializing in oscillators, FM/AM, additive/subtractive synthesis',
      mode: 'subagent',
      model: undefined, // Resolved at runtime
      prompt: loadPrompt('csound-synthesis'),
      hidden: true,
      options: {},
    },
    'csound-effects': {
      name: 'csound-effects',
      description: 'Sub-agent specializing in reverb, delay, filters, distortion, EQ',
      mode: 'subagent',
      model: undefined, // Resolved at runtime
      prompt: loadPrompt('csound-effects'),
      hidden: true,
      options: {},
    },
    'csound-modulation': {
      name: 'csound-modulation',
      description: 'Sub-agent specializing in envelopes, LFOs, control signals',
      mode: 'subagent',
      model: undefined, // Resolved at runtime
      prompt: loadPrompt('csound-modulation'),
      hidden: true,
      options: {},
    },
    narrator: {
      name: 'narrator',
      description: 'Educational narrator for computer music history',
      mode: 'subagent',
      model: undefined, // Resolved at runtime via Provider.smallModel()
      prompt: loadPrompt('narrator'),
      hidden: true,
      options: {},
    },
  }

  export function get(name: string): Info | undefined {
    return AGENTS[name]
  }

  export function list(): Info[] {
    return Object.values(AGENTS).sort((a, b) => {
      if (a.mode === 'primary' && b.mode !== 'primary') return -1
      if (a.mode !== 'primary' && b.mode === 'primary') return 1
      return a.name.localeCompare(b.name)
    })
  }

  export function primaryAgents(): Info[] {
    return list().filter((a) => a.mode === 'primary')
  }

  export function defaultAgent(): string {
    return 'csound'
  }

  export function isSineMode(agent: Info): boolean {
    return agent.options?.sineMode === true
  }
}
