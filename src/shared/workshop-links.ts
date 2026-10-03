/** LAC 2026 workshop URLs — single source for clipboard copy and handout generation. */

export const SETUP_GUIDE = {
  sectionTitle: 'Setup guide',
  linksTitle: 'Install & API key links',
  linksBody:
    'For classes, workshops, and presentations: copy every git clone command, install URL, API signup link, and local LLM ' +
    'resource — paste into chat, email, or slides for students. For LAC 2026, install Dr.C from csounder/DRC-Standalone (branch lac-2026-csound7); handouts live in csounder/Dr.C-Workshop-Demo.',
  copyButton: 'Copy workshop links',
  copyButtonDone: 'Copied!',
  handoutOpen: 'Open one-slide handout',
  handoutReveal: 'Show handout in Finder',
  clipboardHeader: 'Dr.C — workshop links (git clone, install, API keys, local LLM)',
  clipboardPlatforms: 'Platforms: macOS & Linux',
} as const

export interface WorkshopLink {
  label: string
  url: string
}

export interface WorkshopLinkGroup {
  title: string
  links: WorkshopLink[]
}

export const WORKSHOP_HANDOUT_FILENAME = 'LAC-2026-one-slide.pdf'

export const WORKSHOP_LINK_GROUPS: WorkshopLinkGroup[] = [
  {
    title: 'Repos & install (git clone)',
    links: [
      {
        label: 'Dr.C Standalone repo (lac-2026-csound7)',
        url: 'https://github.com/csounder/DRC-Standalone/tree/lac-2026-csound7',
      },
      {
        label: 'Dr.C Standalone — git clone',
        url: 'git clone -b lac-2026-csound7 https://github.com/csounder/DRC-Standalone.git ~/Dr.C-Standalone',
      },
      {
        label: 'Workshop handouts & demos (Dr.C-Workshop-Demo)',
        url: 'https://github.com/csounder/Dr.C-Workshop-Demo',
      },
      {
        label: 'Workshop bundle — git clone',
        url: 'git clone https://github.com/csounder/Dr.C-Workshop-Demo.git',
      },
      {
        label: 'Participant guide (PARTICIPANTS.md)',
        url: 'https://github.com/csounder/DRC-Standalone/blob/lac-2026-csound7/PARTICIPANTS.md',
      },
      {
        label: 'Local LLM guide (LOCAL-LLM.md)',
        url: 'https://github.com/csounder/DRC-Standalone/blob/lac-2026-csound7/LOCAL-LLM.md',
      },
      {
        label: 'Mac attendee handout',
        url: 'https://github.com/csounder/Dr.C-Workshop-Demo/blob/main/MAC-ATTENDEE-HANDOUT.md',
      },
      {
        label: 'Linux attendee handout',
        url: 'https://github.com/csounder/Dr.C-Workshop-Demo/blob/main/LINUX-ATTENDEE-HANDOUT.md',
      },
    ],
  },
  {
    title: 'Csound & tools',
    links: [
      { label: 'Csound 7 releases', url: 'https://github.com/csound/csound/releases' },
      { label: 'Csound download', url: 'https://csound.com/download.html' },
      { label: 'FLOSS Manual', url: 'https://flossmanual.csound.com/' },
      { label: 'Opcode index', url: 'https://csound.com/manual/opcodesIndex/' },
      { label: 'CsoundQt 7 releases', url: 'https://github.com/CsoundQt/CsoundQt/releases' },
      { label: 'Node.js 22', url: 'https://nodejs.org/' },
    ],
  },
  {
    title: 'API keys (Agent)',
    links: [
      { label: 'OpenRouter (one key — recommended)', url: 'https://openrouter.ai/keys' },
      { label: 'OpenRouter credits', url: 'https://openrouter.ai/credits' },
      { label: 'OpenRouter free models', url: 'https://openrouter.ai/models?max_price=0' },
      { label: 'Anthropic (direct)', url: 'https://console.anthropic.com/settings/keys' },
      { label: 'OpenAI (direct)', url: 'https://platform.openai.com/api-keys' },
      { label: 'Groq (free tier)', url: 'https://console.groq.com/keys' },
      { label: 'Google Gemini (free tier)', url: 'https://aistudio.google.com/apikey' },
    ],
  },
  {
    title: 'Local model (no API key)',
    links: [
      { label: 'Ollama download', url: 'https://ollama.com/download' },
      { label: 'Ollama model library', url: 'https://ollama.com/library' },
      { label: 'Default model pull', url: 'https://ollama.com/library/qwen2.5-coder:7b' },
      { label: 'LM Studio (local server)', url: 'https://lmstudio.ai/' },
    ],
  },
]

/** Plain-text block for clipboard — one URL per line, grouped by section. */
export function formatWorkshopLinksForClipboard(): string {
  const lines = [
    SETUP_GUIDE.clipboardHeader,
    SETUP_GUIDE.clipboardPlatforms,
    '',
  ]
  for (const group of WORKSHOP_LINK_GROUPS) {
    lines.push(`=== ${group.title} ===`)
    for (const { label, url } of group.links) {
      lines.push(`${label}: ${url}`)
    }
    lines.push('')
  }
  return lines.join('\n').trimEnd()
}
