import { readFileSync, existsSync } from 'fs'
import { join } from 'path'
import { Log } from '../util/log'
import { isProPlus } from '../util/tier'
import { searchPassages } from './passages'
import { initKnowledgeSources, searchKnowledgeSources } from './knowledge-sources'
import { initCsoundQtExamples, searchCsoundQtExamples } from './csoundqt-examples'
import { matchWorkshopModelRoute } from '../../shared/workshop-model-routes'

export interface RetrievalChunk {
  id: string
  content: string
  source: string
  score: number
}

export interface OpcodeCard {
  name: string
  category: string
  syntax: string
  description: string
  parameters: string[]
  seeAlso: string[]
  domain: string
  tags: string[]
  exampleIDs: string[]
}

// CSD examples: id -> full CSD content
let csdExamples: Map<string, string> = new Map()
let opcodeCards: OpcodeCard[] = []
let opcodeMap: Map<string, OpcodeCard> = new Map()
let knowledgeGraph: { nodes: any[]; edges: any[] } = { nodes: [], edges: [] }
let bookLines: string[] = []
let initialized = false

function findResource(filename: string): string | null {
  const candidates = [
    join(__dirname, '../../resources/knowledge', filename),
    join(__dirname, '../../../resources/knowledge', filename),
    join(process.cwd(), 'resources/knowledge', filename),
  ]
  for (const p of candidates) {
    if (existsSync(p)) return p
  }
  return null
}

function findGoldenStarter(filename: string): string | null {
  const candidates = [
    join(__dirname, '../../resources/workshop-starters', filename),
    join(__dirname, '../../../resources/workshop-starters', filename),
    join(process.cwd(), 'resources/workshop-starters', filename),
  ]
  for (const p of candidates) {
    if (existsSync(p)) return p
  }
  return null
}

function loadJSON<T>(filename: string): T | null {
  const path = findResource(filename)
  if (!path) { Log.warn(`Not found: ${filename}`); return null }
  try {
    return JSON.parse(readFileSync(path, 'utf-8'))
  } catch (err: any) {
    Log.error(`Parse error ${filename}: ${err.message}`)
    return null
  }
}

export namespace Retrieval {
  export function init(): void {
    if (initialized) return
    Log.info('Initializing RAG engine...')

    // Load core bundle: opcode cards + knowledge graph
    const core = loadJSON<{ opcodeCards: OpcodeCard[]; graph: { nodes: any[]; edges: any[] } }>('bundle-core.json')
    if (core) {
      opcodeCards = core.opcodeCards || []
      opcodeMap = new Map(opcodeCards.map((c) => [c.name.toLowerCase(), c]))
      knowledgeGraph = core.graph || { nodes: [], edges: [] }
      Log.info(`Core: ${opcodeCards.length} opcodes, ${knowledgeGraph.nodes.length} graph nodes, ${knowledgeGraph.edges.length} edges`)
    }

    // Load CSD examples bundle
    const csd = loadJSON<{ contents: Record<string, string> }>('bundle-csd.json')
    if (csd?.contents) {
      csdExamples = new Map(Object.entries(csd.contents))
      Log.info(`CSD examples: ${csdExamples.size} files`)
    }

    // Elected Csound Models — Dr. B workshop foundation (6 collections)
    const elected = loadJSON<{ contents: Record<string, string> }>('bundle-elected-models.json')
    if (elected?.contents) {
      for (const [id, content] of Object.entries(elected.contents)) {
        csdExamples.set(id, content)
      }
      Log.info(`Elected models: ${Object.keys(elected.contents).length} foundational CSDs`)
    }

    // McCurdy Haiku — generative ambient foundation (9 pieces, always bundled)
    const haiku = loadJSON<{ contents: Record<string, string> }>('bundle-mccurdy-haiku.json')
    if (haiku?.contents) {
      for (const [id, content] of Object.entries(haiku.contents)) {
        csdExamples.set(id, content)
      }
      Log.info(`McCurdy Haiku: ${Object.keys(haiku.contents).length} generative ambient models`)
    }

    // Selected Instruments — The Csound Catalog v2.5 (Dr. B curated)
    const catalog = loadJSON<{ contents: Record<string, string> }>('bundle-selected-catalog-v25.json')
    if (catalog?.contents) {
      for (const [id, content] of Object.entries(catalog.contents)) {
        csdExamples.set(id, content)
      }
      Log.info(`Csound Catalog v2.5: ${Object.keys(catalog.contents).length} selected instruments`)
    }

    // Granular synthesis models (grain, partikkel, sndwarp, Brandtsegg, Boulanger)
    const granular = loadJSON<{ contents: Record<string, string> }>('bundle-granular-models.json')
    if (granular?.contents) {
      for (const [id, content] of Object.entries(granular.contents)) {
        csdExamples.set(id, content)
      }
      Log.info(`Granular models: ${Object.keys(granular.contents).length} foundational CSDs`)
    }

    // Physical / waveguide models (wg*, pluck, Karplus, handpan, pipa)
    const physical = loadJSON<{ contents: Record<string, string> }>('bundle-physical-models.json')
    if (physical?.contents) {
      for (const [id, content] of Object.entries(physical.contents)) {
        csdExamples.set(id, content)
      }
      Log.info(`Physical models: ${Object.keys(physical.contents).length} waveguide CSDs`)
    }

    // Synthetic drum models (kits, generative, glitch, MS-20)
    const drums = loadJSON<{ contents: Record<string, string> }>('bundle-drum-models.json')
    if (drums?.contents) {
      for (const [id, content] of Object.entries(drums.contents)) {
        csdExamples.set(id, content)
      }
      Log.info(`Drum models: ${Object.keys(drums.contents).length} synthetic drum CSDs`)
    }

    // Generative Groovy models (Jagwani + Marston)
    const generative = loadJSON<{ contents: Record<string, string> }>('bundle-generative-models.json')
    if (generative?.contents) {
      for (const [id, content] of Object.entries(generative.contents)) {
        csdExamples.set(id, content)
      }
      Log.info(`Generative models: ${Object.keys(generative.contents).length} groovy CSDs`)
    }

    // Load csound_book.txt for full-text search
    const bookPath = findResource('csound_book.txt')
    if (bookPath) {
      bookLines = readFileSync(bookPath, 'utf-8').split('\n')
      Log.info(`Book: ${bookLines.length} lines`)
    }

    initKnowledgeSources(findResource)
    try {
      initCsoundQtExamples()
    } catch (err: any) {
      Log.warn(`CsoundQt init failed: ${err?.message ?? err}`)
    }

    initialized = true
    Log.info('RAG engine ready')
  }

  export function lookupOpcode(name: string): OpcodeCard | undefined {
    return opcodeMap.get(name.toLowerCase())
  }

  export function searchOpcodes(query: string): OpcodeCard[] {
    const q = query.toLowerCase()
    return opcodeCards
      .filter((c) =>
        c.name.toLowerCase().includes(q) ||
        c.category.toLowerCase().includes(q) ||
        c.description.toLowerCase().includes(q) ||
        c.tags.some((t) => t.toLowerCase().includes(q))
      )
      .slice(0, 10)
  }

  // Get CSD example by ID (used by opcode cards)
  export function getCsdExample(id: string): string | undefined {
    return csdExamples.get(id)
  }

  // Find relevant CSD examples by keyword search
  export function searchExamples(query: string, max = 3): { id: string; content: string; score: number }[] {
    const terms = query.toLowerCase().split(/\s+/).filter((t) => t.length > 2)
    if (terms.length === 0) return []

    const scored: { id: string; content: string; score: number }[] = []
    for (const [id, content] of csdExamples) {
      const lower = content.toLowerCase()
      let score = 0
      for (const term of terms) {
        const count = (lower.match(new RegExp(term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g')) || []).length
        if (count > 0) score += Math.log2(1 + count)
      }
      // Boost catalog examples from authoritative sources (Dr. B standing rule)
      if (id.startsWith('granular-brandtsegg-partikkel')) score *= 6.5
      else if (id.startsWith('granular-')) score *= 6
      else if (id.startsWith('physical-ningxin-')) score *= 6.5
      else if (id.startsWith('physical-')) score *= 6
      else if (id.startsWith('drum-mccurdy-')) score *= 6.5
      else if (id.startsWith('drum-')) score *= 6
      else if (id.startsWith('generative-jagwani-')) score *= 6.5
      else if (id.startsWith('generative-marston-')) score *= 6.2
      else if (id.startsWith('generative-')) score *= 6
      else if (id.startsWith('catalog-v25-drb')) score *= 6
      else if (id.startsWith('catalog-v25')) score *= 5
      else if (id.startsWith('mccurdy-haiku-')) score *= 5.5
      else if (id.startsWith('elected-')) score *= 5
      else if (id.startsWith('flossmanual')) score *= 4
      else if (id.startsWith('csoundmanual-')) score *= 5.5
      else if (id.startsWith('zuccobook-')) score *= 4.5
      else if (id.startsWith('lazzarinispectral') || id.startsWith('lazzarinicsound')) score *= 3.5
      else if (id.startsWith('lazzarini')) score *= 3
      else if (id.startsWith('hornerbook')) score *= 2.5
      if (terms.some((t) => id.toLowerCase().includes(t))) score *= 2
      if (score > 0) scored.push({ id, content: content.slice(0, 2000), score })
    }

    scored.sort((a, b) => b.score - a.score)
    return scored.slice(0, max)
  }

  // Search the csound book text
  export function searchBook(query: string, max = 4): RetrievalChunk[] {
    if (bookLines.length === 0) return []
    const terms = query.toLowerCase().split(/\s+/).filter((t) => t.length > 2)
    if (terms.length === 0) return []

    const results: RetrievalChunk[] = []
    const windowSize = 20

    for (let i = 0; i < bookLines.length - windowSize; i += windowSize / 2) {
      const window = bookLines.slice(i, i + windowSize).join('\n')
      const lower = window.toLowerCase()
      let score = 0
      for (const term of terms) {
        const count = (lower.match(new RegExp(term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g')) || []).length
        if (count > 0) score += Math.log2(1 + count)
      }
      if (score > 1) {
        results.push({ id: `book_${i}`, content: window, source: 'csound_book', score })
      }
    }

    results.sort((a, b) => b.score - a.score)
    return results.slice(0, max)
  }

  // Full RAG search: opcodes + examples + book
  export function search(query: string, maxResults = 8): RetrievalChunk[] {
    init()
    const all: RetrievalChunk[] = []

    // CSD examples
    const examples = searchExamples(query, 3)
    for (const ex of examples) {
      all.push({ id: ex.id, content: ex.content, source: 'csd_example', score: ex.score })
    }

    // Book text
    const bookChunks = searchBook(query, 4)
    all.push(...bookChunks)

    all.sort((a, b) => b.score - a.score)
    return all.slice(0, maxResults)
  }

  // Build RAG context for prompt injection
  export function formatForPrompt(query: string): string {
    init()
    const parts: string[] = []
    const q = query.toLowerCase()
    const cap = isProPlus() ? 6000 : 4500

    const pushCatalogGolden = (exId: string, label: string, maxLen = 2400) => {
      const ex = csdExamples.get(exId)
      if (ex) {
        parts.push(
          `<golden-pattern source="${label}" priority="adapt-this">\n${ex.slice(0, maxLen)}\n</golden-pattern>`,
        )
      }
    }

    // FM synthesis — pin Csound Manual + catalog models FIRST (before cap truncation).
    if (/\b(fm|foscil|fmbell|fmpercfl|modulat|carrier|modulator)\b/.test(q)) {
      if (/\b(wood\s*block|woodblock|clave|block|percussion|perc|drum)\b/.test(q)) {
        pushCatalogGolden('csoundmanual-fmpercfl', 'Csound Manual — fmpercfl (FM percussion; kc1/kc2 decay)')
        pushCatalogGolden('zuccobook-cap-10-6-wood', 'Zucco Book Cap 10.6 — modal wood plate')
      }
      if (/\b(bell|chime|glock|marimba)\b/.test(q)) {
        pushCatalogGolden('csoundmanual-fmbell', 'Csound Manual — fmbell (standard kc1/kc2 bell FM)')
        pushCatalogGolden('flossmanual-04d10-bell', 'FLOSS Manual — inharmonic FM bell (5:7 ratio)')
      }
      if (/\b(midi|keyboard|controller)\b/.test(q)) {
        parts.push(
          `<knowledge-doc source="Dr.C MIDI pattern">\n` +
          `For MIDI keyboard: massign 0, 1; iFreq cpsmidi or cpsmidinn(p4); iAmp ampmidi 1 or p5/127; ` +
          `CsOptions: -+rtmidi=NULL -M0 --midi-key-cps=4 --midi-velocity-amp=5. ` +
          `Adapt fmpercfl/fmbell from the golden patterns above — do NOT reinvent foscili wiring.\n</knowledge-doc>`,
        )
      }
    }

    // Elected Csound Models — foundational workshop authorities
    const electedGolden: [RegExp, string, string][] = [
      [/\b(wobble|gbuzz|jspline|distort)\b.*\b(bass|sub)\b|\b(bass|sub)\b.*\b(wobble|gbuzz)\b/, 'elected-bass-wobble-wobble', 'Thorin Kerr Bass Wobble'],
      [/\b(gendyc|stochastic|ffitch)\b/, 'elected-gendyc-gendycpiece', 'Richard Boulanger GendyC (2021)'],
      [/\b(sterrain|superwave|terrain)\b/, 'elected-sterrain-sterrain2', 'SuperWaveTerrain (DocB)'],
      [/\b(deep\s*note|thx|andy\s*moorer)\b/, 'elected-deepnote-deepnote', 'Steven Yi Deep Note'],
      [/\b(groovish|schedkwhen|microtonal)\b/, 'elected-groovish-groovish', 'Jim Aikin Groovish'],
      [/\b(dizi|sheng|hulusi|chinese\s*instrument|horner)\b/i, 'elected-chinese-dizi', 'Andrew Horner Chinese Instruments'],
    ]
    for (const [re, exId, label] of electedGolden) {
      if (re.test(q)) {
        const ex = csdExamples.get(exId)
        if (ex) {
          parts.push(
            `<golden-pattern source="Elected Model: ${label}">\n${ex.slice(0, 2400)}\n</golden-pattern>`,
          )
        }
      }
    }

    // McCurdy Haiku — generative ambient foundation (nine realtime pieces)
    const haikuGolden: [RegExp, string, string][] = [
      [/\b(haiku\s*(ii|2)|polyrhythm|inharmonic\s*bell)\b/i, 'mccurdy-haiku-ii', 'Haiku II — polyrhythmic bells'],
      [/\b(haiku\s*(iii|3)|wguid2)\b/i, 'mccurdy-haiku-iii', 'Haiku III — wguide2 resonances'],
      [/\b(haiku\s*(iv|4)|hsboscil)\b/i, 'mccurdy-haiku-iv', 'Haiku IV — hsboscil clusters'],
      [/\b(haiku\s*(v|5)|phaser2)\b/i, 'mccurdy-haiku-v', 'Haiku V — phaser2 resonances'],
      [/\b(haiku\s*(vi|6)|strum|wguid1)\b/i, 'mccurdy-haiku-vi', 'Haiku VI — strummed waveguides'],
      [/\b(haiku\s*(vii|7)|long\s*bell|bell\s*garden)\b/i, 'mccurdy-haiku-vii', 'Haiku VII — bell garden'],
      [/\b(haiku\s*(viii|8)|hilbert|stochastic\s*layer)\b/i, 'mccurdy-haiku-viii', 'Haiku VIII — stochastic layers'],
      [/\b(haiku\s*(ix|9)|arpeggio\s*cloud)\b/i, 'mccurdy-haiku-ix', 'Haiku IX — arpeggio clouds'],
      [/\b(haiku|mccurdy)\b.*\b(i|1|trombone|drone)\b|\b(haiku\s*i)\b/i, 'mccurdy-haiku-i', 'Haiku I — gbuzz drones'],
      [/\b(ambient|generative|soundscape|evolving|installation|alwayson|schedkwhennamed|no\s*score)\b/i, 'mccurdy-haiku-i', 'McCurdy Haiku — generative ambient'],
    ]
    for (const [re, exId, label] of haikuGolden) {
      if (re.test(q)) {
        const ex = csdExamples.get(exId)
        if (ex) {
          parts.push(
            `<golden-pattern source="McCurdy Haiku: ${label}">\n${ex.slice(0, 2600)}\n</golden-pattern>`,
          )
        }
        break
      }
    }

    // Granular synthesis — foundational models (high user interest)
    const granularGolden: [RegExp, string, string][] = [
      [/\b(truax|timout.*grain|reinit.*grain)\b/i, 'granular-brandtsegg-partikkel-starter-kit', 'Partikkel granular (Truax-style timout)'],
      [/\b(partikkel|brandtsegg|hadron|live\s*input\s*granular)\b/i, 'granular-brandtsegg-partikkel-starter-kit', 'Partikkel starter kit (live FX)'],
      [/\b(sndwarp|time\s*stretch|sound\s*warp)\b/i, 'granular-boulanger-sndwarpmidi', 'SndWarpMIDI'],
      [/\b(grainmidi|grain\s+density|classic\s*grain)\b/i, 'granular-boulanger-grainmidi', 'GrainMIDI (Dr.B)'],
      [/\b(fm.*grain|grain.*fm|grain\s+rate\s+fm)\b/i, 'granular-fm-rate-and-pitch', 'FM Grain rate+pitch'],
      [/\b(oversampl|anti.?alias).*\bgranular\b|\bgranular\b.*\boversampl\b/i, 'granular-brandtsegg-oversampling', 'Granular oversampling'],
      [/\b(granular|granule|grain\s+cloud|texture\s+granular)\b/i, 'granular-brandtsegg-partikkel-starter-kit', 'Granular synthesis'],
      [/\b(mikelson|ezine)\b.*\bgrain\b/i, 'granular-ezine-granula', 'Granula Ezine tutorial'],
    ]
    for (const [re, exId, label] of granularGolden) {
      if (re.test(q)) {
        const ex = csdExamples.get(exId)
        if (ex) {
          parts.push(
            `<golden-pattern source="Granular Model: ${label}">\n${ex.slice(0, 2800)}\n</golden-pattern>`,
          )
        }
        break
      }
    }

    // Physical / waveguide models — wg*, pluck, Karplus, handpan, pipa
    const physicalGolden: [RegExp, string, string][] = [
      [/\b(pipa|chinese\s*lute|ningxin|waveguide\s*pipa)\b/i, 'physical-ningxin-waveguide-pipa', 'Ningxin Waveguide Pipa'],
      [/\b(handpan|hang\s*drum|modal\s*percussion)\b/i, 'physical-handpan-v1', 'HandPan modal'],
      [/\b(bamboo\s*flute|gutwein|slide\s*flute)\b/i, 'physical-gutwein-bambooflute1', 'Gutwein bamboo flute'],
      [/\b(karplus|karplus.?strong|delayr.*delayw)\b/i, 'physical-karplusmath', 'KarplusMATH'],
      [/\b(wgflute|waveguide\s*flute|perry\s*cook\s*flute)\b/i, 'physical-wgflute', 'wgflute'],
      [/\b(wgpluck|wgpluck2|waveguide\s*pluck)\b/i, 'physical-wgpluck2', 'wgpluck2'],
      [/\b(wgbow|bowed\s*string|bowed\s*bar)\b/i, 'physical-wgbow', 'wgbow'],
      [/\b(wgclar|waveguide\s*clarinet)\b/i, 'physical-wgclar', 'wgclar'],
      [/\b(physical\s*model|waveguide|wguid)\b/i, 'physical-wgflute', 'Physical waveguide models'],
    ]
    for (const [re, exId, label] of physicalGolden) {
      if (re.test(q)) {
        const ex = csdExamples.get(exId)
        if (ex) {
          parts.push(
            `<golden-pattern source="Physical Model: ${label}">\n${ex.slice(0, 2800)}\n</golden-pattern>`,
          )
        }
        break
      }
    }

    // Generative Groovy — Jagwani + Marston workshop starters
    const generativeGolden: [RegExp, string, string][] = [
      [/\b(jagwani|aman\s*jagwani|subtractive\s*drum)\b/i, 'generative-jagwani-subtractive', 'Jagwani generative subtractive'],
      [/\b(jagwani.*fm|fm\s*generative|chowning)\b/i, 'generative-jagwani-fm', 'Jagwani FM generative'],
      [/\b(mumbai|samplebank)\b/i, 'generative-jagwani-mumbai', 'Jagwani Mumbai project'],
      [/\b(marston|genjam|in\s*the\s*park)\b/i, 'generative-marston-best-in-the-park-randomized-start', 'Marston In the Park'],
      [/\b(groovy|generative\s*groovy|metro.*schedkwhen.*generative)\b/i, 'generative-jagwani-subtractive', 'Generative Groovy'],
      [/\b(regular\s*beat|metered\s*beat|triads.*drum)\b/i, 'generative-marston-beat-metered4', 'Marston regular beat'],
    ]
    for (const [re, exId, label] of generativeGolden) {
      if (re.test(q)) {
        const ex = csdExamples.get(exId)
        if (ex) {
          parts.push(
            `<golden-pattern source="Generative Model: ${label}">\n${ex.slice(0, 2800)}\n</golden-pattern>`,
          )
        }
        break
      }
    }

    // Synthetic drum models — kits, generative, glitch, MS-20
    const drumGolden: [RegExp, string, string][] = [
      [/\b(dseq|joaquin.*drum|drum\s*machine\s*language)\b/i, 'drum-joaquin-dseq-quickstart', 'Joaquin dseq drum machine'],
      [/\b(loop\s*sequencer|16\s*step|step\s*sequencer).*\b(drum|beat)\b/i, 'drum-mccurdy-simple-loop-sequencer', 'McCurdy loop sequencer'],
      [/\b(generative\s*drum|random\s*drum|schedkwhen.*drum|metro.*drum)\b/i, 'drum-mccurdy-generative-05e04', 'McCurdy generative drums'],
      [/\b(amen\s*break|beat\s*mangl)\b/i, 'drum-amen-beat-mangler', 'Amen beat mangler'],
      [/\b(recursive\s*drum|event_i.*drum)\b/i, 'drum-lazzarini-recursive', 'Lazzarini recursive drum'],
      [/\b(drum\s*replacement|live\s*drum\s*replac)\b/i, 'drum-replacement-05l04', 'Drum replacement'],
      [/\b(guiro|tambourine|cabasa|percussion\s*opcode)\b/i, 'drum-percussion-opcodes', 'Percussion model opcodes'],
      [/\b(ms-?20|k35|yi.*drum|steven\s*yi)\b/i, 'drum-yi-k35-ms20', 'Yi K35 MS-20 drums'],
      [/\b(tonematrix|tone\s*matrix)\b/i, 'drum-kholomiov-tonematrix', 'Kholomiov tone matrix'],
      [/\b(glitch\s*drum|glitch\s*perc|kholomiov)\b/i, 'drum-kholomiov-dely-glitch', 'Kholomiov glitch drums'],
      [/\b(electric\s*drum\s*kit|synthesis.*drum\s*kit)\b/i, 'drum-electric-kit-1', 'Electric drum kit'],
      [/\b(full\s*kit|complete\s*drum\s*kit)\b/i, 'drum-fullkit', 'FullKit'],
      [/\b(kick\s*drum|synth\s*kick|808\s*kick)\b/i, 'drum-element-kick1', 'Synthesized kick'],
      [/\b(drum\s*machine|808|909|synthetic\s*drum|electronic\s*drum|kick|snare|hi-?hat|percussion\s*synth)\b/i, 'drum-drummachine', 'Synthetic drums'],
    ]
    for (const [re, exId, label] of drumGolden) {
      if (re.test(q)) {
        const ex = csdExamples.get(exId)
        if (ex) {
          parts.push(
            `<golden-pattern source="Drum Model: ${label}">\n${ex.slice(0, 2800)}\n</golden-pattern>`,
          )
        }
        break
      }
    }

    // Csound Catalog v2.5 — Dr. B selected instruments
    const catalogGolden: [RegExp, string, string][] = [
      [/\b(risset|endless|mutation|bell\s*function)\b/i, 'catalog-v25-risset-endless', 'Risset endless glissando'],
      [/\b(fof|choir|chant|perry\s*cook)\b/i, 'catalog-v25-drb-cook-fofchoir', 'Cook fof choir (Dr.B pick)'],
      [/\b(tb-?303|303\s*emu|analog\s*pad)\b/i, 'catalog-v25-drb-comajuncosas-tb303', 'Dr.B TB-303'],
      [/\b(karplus|pluck\s*bass|waveguide\s*pluck)\b/i, 'catalog-v25-drb-comajuncosas-karplusmath', 'Dr.B karplus'],
      [/\b(marimba|glockenspiel|celeste|harpsichord|varo|gm\s*style)\b/i, 'catalog-v25-varo-13marimba', 'Varo marimba'],
      [/\b(anagrain|smaragdis)\b/i, 'catalog-v25-smaragdis-anagrain', 'Smaragdis anagrain'],
      [/\b(phaser|string\s*pad|costello)\b/i, 'catalog-v25-costello-stringphaser', 'Costello string phaser'],
      [/\b(csound\s*catalog|catalog\s*v2|selected\s*instrument)\b/i, 'catalog-v25-drb-comajuncosas-analogpad1', 'Csound Catalog v2.5'],
    ]
    for (const [re, exId, label] of catalogGolden) {
      if (re.test(q)) {
        const ex = csdExamples.get(exId)
        if (ex) {
          parts.push(
            `<golden-pattern source="Csound Catalog v2.5: ${label}">\n${ex.slice(0, 2400)}\n</golden-pattern>`,
          )
        }
        break
      }
    }

    // Book-verified golden patterns (Boulanger workshop starters)
    const pushGoldenStarter = (filename: string, label: string) => {
      const golden = findGoldenStarter(filename)
      if (golden) {
        parts.push(
          `<golden-pattern source="${label}">\n` +
          `${readFileSync(golden, 'utf-8').slice(0, 2200)}\n</golden-pattern>`,
        )
      }
    }

    if (/\b(fm\s*bass|bass|pluck|ping-?pong|ostinato\s*bass)\b/i.test(q)) {
      pushGoldenStarter('pluck_bass_starter.csd', 'Dr.B ping-pong bass starter (verified Csound 7)')
    } else if (
      /\b(piano|epiano|electric\s*piano)\b/i.test(q) &&
      /\b(reverb|rev|wet)\b/i.test(q)
    ) {
      pushGoldenStarter('fm_piano_reverb_starter.csd', 'Dr.B FM piano + global reverb (ga bus, verified Csound 7)')
    } else if (/\b(global\s*reverb|reverb\s*bus|reverbsc)\b/i.test(q) && /\b(fm|piano|synth)\b/i.test(q)) {
      pushGoldenStarter('fm_piano_reverb_starter.csd', 'Dr.B FM + global reverb pattern (verified Csound 7)')
    } else if (/\b(reverb|wet)\b/i.test(q) && !/\b(delay|echo|ping-?pong)\b/i.test(q)) {
      pushGoldenStarter('pad_starter.csd', 'Dr.B pad with ga-bus reverb (verified Csound 7)')
    }

    if (/\b(trumpet|brass|flugel|cornet|trombone|bugle|fanfare)\b/i.test(q) && !/\b(bell|shimmer|chime|glock|clarinet|pad)\b/i.test(q)) {
      pushGoldenStarter('models/misc_synths/WaveshapeBrass.csd', 'Dr.B WaveshapeBrass — Rajmil Fischman beating-source brass')
    } else if (/\b(french\s*horn|horn\s*solo)\b/i.test(q) || (/\bhorn\b/i.test(q) && !/\b(alto|tenor|sax|english)\b/i.test(q))) {
      pushGoldenStarter('models/misc_synths/FrenchHorn.csd', 'Dr.B FrenchHorn — wavetable horn instr 25')
    } else if (/\b(clarinet|bass\s*clarinet)\b/i.test(q) && !/\b(brass|bell|pad|waveshape)\b/i.test(q)) {
      pushGoldenStarter('models/chowning/chowning_fm_clarinet.csd', 'Chowning FM clarinet — 9:8 ratio @ A440')
    } else if (/\b(shimmer|bell|chime)\b/i.test(q) && !/\b(simple|plain|2-?\s*operator|trumpet|brass)\b/i.test(q)) {
      pushGoldenStarter('fm_bell_starter.csd', 'Dr.B shimmer FM bell starter (verified Csound 7)')
    } else if (/\b(wood\s*block|woodblock|temple\s*block|clave)\b/i.test(q) && /\b(fm|percussion|perc|midi)\b/i.test(q)) {
      pushGoldenStarter('fm_woodblock_midi_starter.csd', 'Dr.B FM woodblock MIDI — fmpercfl kc1/kc2 (verified Csound 7)')
      pushCatalogGolden('csoundmanual-fmpercfl', 'Csound Manual — fmpercfl')
    } else if (/\b(wood\s*block|woodblock|temple\s*block)\b/i.test(q) && /\b(fm|percussion|perc)\b/i.test(q)) {
      pushGoldenStarter('fm_woodblock_midi_starter.csd', 'Dr.B FM woodblock — fmpercfl (verified Csound 7)')
    } else if (
      /\b(simple|plain|2-?\s*operator|two-?\s*operator|warm|resonant)\b/i.test(q) &&
      /\b(fm|synth|foscil)\b/i.test(q)
    ) {
      pushGoldenStarter('fm_starter.csd', 'Dr.B simple 2-op FM starter (verified Csound 7)')
    } else if (/\b(fm|foscil)\b/i.test(q) && !/\b(piano|reverb|wet)\b/i.test(q)) {
      pushGoldenStarter('fm_starter.csd', 'Dr.B FM starter (verified Csound 7)')
    }

    // Curated knowledge docs (antipatterns, patterns, syntax rules)
    const docHits = searchKnowledgeSources(query, isProPlus() ? 3 : 2)
    for (const doc of docHits) {
      parts.push(
        `<knowledge-doc source="${doc.source}">\n${doc.content.slice(0, 900)}\n</knowledge-doc>`,
      )
    }

    // Extracted book passages (The Csound Book) — richer than raw line windows
    const bookHits = searchPassages(query, isProPlus() ? 4 : 2)
    for (const p of bookHits) {
      parts.push(
        `<book-passage source="${p.source_book}" page="${p.source_page ?? ''}">\n${p.content.slice(0, 600)}\n</book-passage>`,
      )
    }

    // Always pin foscili when FM is mentioned (after catalog FM opcodes above).
    if (/\b(fm|bell|chime|foscil|modulat)\b/.test(q)) {
      const fmperc = opcodeMap.get('fmpercfl')
      const fmbell = opcodeMap.get('fmbell')
      if (fmperc) {
        parts.push(
          `<opcode name="fmpercfl" critical="true">` +
          `FM percussion — use for woodblock/clave hits. Syntax: ares fmpercfl xamp, kcps, kc1, kc2, kvdepth, kvrate. ` +
          `Decay kc2 with expsegr. ${fmperc.description}</opcode>`,
        )
      }
      if (fmbell) {
        parts.push(
          `<opcode name="fmbell" critical="true">` +
          `FM bell — textbook kc1/kc2 ratios. Syntax: ares fmbell xamp, kcps, kc1, kc2, kvdepth, kvrate. ` +
          `${fmbell.description}</opcode>`,
        )
      }
      const card = opcodeMap.get('foscili')
      if (card) {
        parts.push(
          `<opcode name="foscili" critical="true">` +
          `Syntax: ares foscili xamp, kcps, xcar, xmod, kndx, ifn — ONE FM opcode (Chowning). ` +
          `NOT two separate foscili lines. ${card.description}</opcode>`,
        )
      }
    }

    // Opcode lookups from query tokens
    const opcodeRe = /\b([a-z][a-z0-9_]{2,})\b/gi
    const matches = query.match(opcodeRe) || []
    const seen = new Set<string>(['foscili'])
    for (const m of matches) {
      const name = m.toLowerCase()
      if (seen.has(name)) continue
      seen.add(name)
      const card = opcodeMap.get(name)
      if (card) {
        parts.push(`<opcode name="${card.name}" category="${card.category}">${card.description}${card.seeAlso.length ? ` | See also: ${card.seeAlso.join(', ')}` : ''}</opcode>`)
        if (card.exampleIDs.length > 0) {
          const ex = csdExamples.get(card.exampleIDs[0])
          if (ex) {
            parts.push(`<example id="${card.exampleIDs[0]}">\n${ex.slice(0, 1200)}\n</example>`)
          }
        }
      }
    }

    // CsoundQt local examples (McCurdy Collection, FLOSS Manual Examples)
    const qtHits = searchCsoundQtExamples(query, isProPlus() ? 3 : 2)
    for (const ex of qtHits) {
      parts.push(
        `<catalog-example id="${ex.id}" source="CsoundQt ${ex.collection}">\n${ex.content.slice(0, 1500)}\n</catalog-example>`,
      )
    }

    // Catalog CSDs (FLOSS Manual, Lazzarini, Horner / Boulanger) — adapt before inventing
    const catalogExamples = searchExamples(query, isProPlus() ? 4 : 2)
    for (const ex of catalogExamples) {
      const src = ex.id.startsWith('granular-') ? 'Granular Models (Dr.B foundation)'
        : ex.id.startsWith('catalog-v25-drb') ? 'Csound Catalog v2.5 (Dr.B pick)'
        : ex.id.startsWith('catalog-v25') ? 'Csound Catalog v2.5 (selected)'
        : ex.id.startsWith('mccurdy-haiku-') ? 'McCurdy Haiku (generative ambient)'
        : ex.id.startsWith('elected-') ? 'Elected Model (Dr.B foundation)'
        : ex.id.startsWith('flossmanual') ? 'FLOSS Manual'
        : ex.id.startsWith('lazzarini') ? 'Lazzarini'
        : ex.id.startsWith('hornerbook') ? 'Csound Book (Horner)'
        : 'Csound Catalog'
      parts.push(
        `<catalog-example id="${ex.id}" source="${src}">\n${ex.content.slice(0, 1500)}\n</catalog-example>`,
      )
    }

    const chunks = search(query, isProPlus() ? 6 : 4)
    for (const chunk of chunks) {
      parts.push(`<reference source="${chunk.source}">\n${chunk.content.slice(0, isProPlus() ? 1000 : 800)}\n</reference>`)
    }

    let total = ''
    for (const p of parts) {
      if (total.length + p.length > cap) break
      total += p + '\n'
    }

    return total
  }
}
