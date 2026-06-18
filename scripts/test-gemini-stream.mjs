import { createGoogleGenerativeAI } from '@ai-sdk/google'
import { streamText } from 'ai'
import { readFileSync } from 'fs'
import { homedir } from 'os'

async function main() {
  const key = JSON.parse(
    readFileSync(homedir() + '/Library/Application Support/drc/drc/config.json', 'utf8'),
  ).google

  const google = createGoogleGenerativeAI({
    apiKey: key,
    baseURL: 'https://generativelanguage.googleapis.com/v1beta',
  })
  const model = google('gemini-2.5-flash')

  try {
  const stream = streamText({
    model,
    messages: [{ role: 'user', content: 'Reply OK' }],
    maxTokens: 32,
  })
    let out = ''
    for await (const chunk of stream.textStream) out += chunk
    const finish = await stream.finishReason
    console.log('chars:', out.length, 'finish:', finish)
    if (!out.trim()) {
      console.log('raw:', JSON.stringify(await stream.response).slice(0, 800))
    }
  } catch (err) {
    console.log('ERR:', err.message?.slice(0, 400))
  }
}

main()
