import { IpcMain } from 'electron'
import { generateText } from 'ai'
import { Provider } from '../provider/provider'
import { Log } from '../util/log'
import { usageFromSdk } from '../util/usage-cost'

// Extract the <CsoundSynthesizer>...</CsoundSynthesizer> block from a model
// response. Models occasionally leak code fences or a trailing sentence despite
// the prompt forbidding them, so we pull the block out defensively.
function extractCsd(raw: string): string | null {
  const m = raw.match(/<CsoundSynthesizer[\s\S]*?<\/CsoundSynthesizer>/i)
  return m ? m[0] : null
}

export function handleLlmIPC(ipcMain: IpcMain): void {
  ipcMain.handle('llm:adaptCsd', async (_event, prompt: string) => {
    const trimmed = String(prompt ?? '').trim()
    if (!trimmed) return { ok: false, error: 'Empty prompt' }

    const primary = Provider.defaultProvider()
    const chain = Provider.providerChain(primary, 'main')
    let lastError = 'All configured providers failed. Check keys in Settings.'

    for (let i = 0; i < chain.length; i++) {
      const { providerID, modelID } = chain[i]
      if (i > 0) {
        Log.info(`llm:adaptCsd fallback → ${Provider.providerLabel(providerID)} (${modelID})`)
      }

      let model
      try {
        model = Provider.getLanguageModel(providerID, modelID)
      } catch (err: any) {
        lastError = `Model unavailable: ${err.message}`
        if (i < chain.length - 1) continue
        return { ok: false, error: lastError, providerID }
      }

      Log.info(`llm:adaptCsd → ${providerID}/${modelID} (${trimmed.length} chars)`)

      try {
        const result = await generateText({
          model: model as any,
          messages: [{ role: 'user', content: trimmed }],
          temperature: 0.2,
          maxTokens: 8192,
        })

        if (!result.text.trim()) {
          lastError = Provider.emptyStreamMessage(providerID)
          Log.warn(`llm:adaptCsd → empty response from ${providerID}/${modelID}`)
          if (Provider.shouldTryNextProvider(null, true) && i < chain.length - 1) continue
          return { ok: false, error: lastError, providerID }
        }

        const csd = extractCsd(result.text)
        if (!csd) {
          Log.warn('llm:adaptCsd → response did not contain a CsoundSynthesizer block')
          return {
            ok: false,
            error: 'Model response missing <CsoundSynthesizer> block',
            raw: result.text.slice(0, 400),
            providerID,
          }
        }

        const usage = usageFromSdk(providerID, modelID, result.usage, 'player')
        return { ok: true, csd, usage: usage ?? undefined, providerID }
      } catch (err: any) {
        lastError = Provider.humanizeError(providerID, err)
        Log.error(`llm:adaptCsd error (${providerID}):`, err.message)
        if (Provider.shouldTryNextProvider(err, false) && i < chain.length - 1) continue
        return { ok: false, error: lastError, providerID }
      }
    }

    return { ok: false, error: lastError }
  })
}
