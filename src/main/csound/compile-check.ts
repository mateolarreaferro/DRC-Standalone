import { readFileSync, writeFileSync } from 'fs'
import { join } from 'path'
import { spawn } from 'child_process'
import { withCsoundPath } from '../util/csound-path'
import {
  needsHoldScoreShortening,
  shortenHoldScoreForCompile,
  stripCsOptionsHandledByCli,
} from '../../shared/csd-offline-prepare'

export { needsHoldScoreShortening, shortenHoldScoreForCompile } from '../../shared/csd-offline-prepare'

export function compileCheckPath(csdPath: string, tempDir: string): string {
  const raw = readFileSync(csdPath, 'utf-8')
  let prepared = stripCsOptionsHandledByCli(raw)
  if (needsHoldScoreShortening(prepared)) {
    prepared = shortenHoldScoreForCompile(prepared)
  }
  const checkPath = join(tempDir, 'compile-check.csd')
  writeFileSync(checkPath, prepared, 'utf-8')
  return checkPath
}

export function runCsoundCompileCheck(
  csdPath: string,
  timeoutMs = 15_000,
): Promise<{ stdout: string; stderr: string; code: number | null }> {
  return new Promise((resolve, reject) => {
    const child = spawn('csound', ['-n', '-d', '-m0', csdPath], {
      env: withCsoundPath(),
      stdio: ['ignore', 'pipe', 'pipe'],
    })

    let stdout = ''
    let stderr = ''
    child.stdout?.on('data', (d) => { stdout += d.toString() })
    child.stderr?.on('data', (d) => { stderr += d.toString() })

    const timer = setTimeout(() => {
      child.kill('SIGKILL')
      reject(Object.assign(new Error(`Compile check timed out after ${timeoutMs / 1000}s`), {
        code: 'ETIMEDOUT',
        stdout,
        stderr,
      }))
    }, timeoutMs)

    child.on('error', (err) => {
      clearTimeout(timer)
      reject(err)
    })

    child.on('close', (code) => {
      clearTimeout(timer)
      resolve({ stdout, stderr, code })
    })
  })
}
