import { prepareOrchestraForWebapp, prepareCsdForWebappCompile } from '../../shared/csd-webapp-prepare'
import { mechanicalPlayerAdapt } from './mechanicalPlayerAdapt'
import { parseChannels, usesKeyboard } from './parseChannels'

/** Workshop / starter CSDs → Player-shaped web orchestra (chn_k, chnmix reverb bus). */
export function resolveWebappSourceCsd(csd: string): string {
  const trimmed = csd.trim()
  const adapted = mechanicalPlayerAdapt(trimmed)
  return adapted ?? trimmed
}

export function buildWebappManifest(csd: string) {
  const source = resolveWebappSourceCsd(csd)
  const orc = prepareOrchestraForWebapp(source)
  return {
    source,
    orc,
    channels: parseChannels(source),
    hasKeyboard: usesKeyboard(orc),
    hasReverbBus: /\binstr\s+99\b/.test(orc),
  }
}

export function prepareWebappCompileCsd(csd: string): string {
  return prepareCsdForWebappCompile(resolveWebappSourceCsd(csd))
}
