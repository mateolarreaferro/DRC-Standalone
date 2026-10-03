#!/usr/bin/env node
/**
 * Verify better-sqlite3 loads under Electron (required for Dr.C memory / 👍 learning).
 * Exit 0 = OK. Exit 1 = rebuild needed — run: npx electron-builder install-app-deps
 */
import { spawnSync } from 'child_process'
import { fileURLToPath } from 'url'
import { dirname, join } from 'path'

const root = join(dirname(fileURLToPath(import.meta.url)), '..')
const electronBin = join(root, 'node_modules', 'electron', 'cli.js')

const probe = spawnSync(
  process.execPath,
  [electronBin, '-e', `
    process.env.ELECTRON_RUN_AS_NODE = '1';
    try {
      require('better-sqlite3')(':memory:');
      console.log('OK');
      process.exit(0);
    } catch (e) {
      console.error('FAIL:', e.message);
      process.exit(1);
    }
  `],
  { cwd: root, env: { ...process.env, ELECTRON_RUN_AS_NODE: '1' }, encoding: 'utf8' },
)

if (probe.status === 0 && probe.stdout?.includes('OK')) {
  console.log('Dr.C memory module: OK (better-sqlite3 loads in Electron)')
  process.exit(0)
}

console.error('')
console.error('Dr.C memory module: OFF — better-sqlite3 failed to load in Electron.')
console.error(probe.stderr?.trim() || probe.stdout?.trim() || 'unknown error')
console.error('')
console.error('Fix (from the Dr.C-Standalone folder):')
console.error('  npx electron-builder install-app-deps')
console.error('')
console.error('Without this, 👍/👎 feedback and remembered preferences will not persist.')
process.exit(1)
