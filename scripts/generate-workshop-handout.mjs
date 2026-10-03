#!/usr/bin/env node
/**
 * Generate workshop PDFs for LAC 2026.
 *   npm run generate:workshop-handout   → LAC-2026-one-slide.pdf (overview handout)
 *   npm run generate:install-slide      → LAC-2026-Install-Slide.pdf (projector setup slide)
 */

import { mkdirSync, writeFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import PDFDocument from 'pdfkit'

const REPO = dirname(dirname(fileURLToPath(import.meta.url)))
const OUT_DIR = join(REPO, 'resources/workshop')
const INSTALL_SLIDE = process.argv.includes('--install-slide')
const OUT_FILE = join(OUT_DIR, INSTALL_SLIDE ? 'LAC-2026-Install-Slide.pdf' : 'LAC-2026-one-slide.pdf')

const LINKS = [
  ['Repos', [
    ['Standalone', 'github.com/mateolarreaferro/Dr.C-Standalone'],
    ['Releases', 'github.com/mateolarreaferro/Dr.C-Standalone/releases'],
    ['Terminal', 'github.com/mateolarreaferro/Dr.C'],
  ]],
  ['Csound', [
    ['CS7 releases', 'github.com/csound/csound/releases'],
    ['Manual', 'flossmanual.csound.com'],
    ['Opcodes', 'csound.com/manual/opcodesIndex'],
    ['CsoundQt 7', 'github.com/CsoundQt/CsoundQt/releases'],
  ]],
  ['Agent keys', [
    ['OpenRouter (one key)', 'openrouter.ai/keys'],
    ['Anthropic direct', 'console.anthropic.com/settings/keys'],
    ['OpenAI direct', 'platform.openai.com/api-keys'],
    ['Groq free', 'console.groq.com/keys'],
    ['Gemini free', 'aistudio.google.com/apikey'],
  ]],
  ['Local LLM', [
    ['Ollama', 'ollama.com/download'],
    ['Model', 'ollama pull qwen2.5-coder:7b'],
  ]],
]

const INSTALL_LINKS = [
  ['Csound 7', 'github.com/csound/csound/releases'],
  ['Node.js 22', 'nodejs.org'],
  ['Standalone releases', 'github.com/mateolarreaferro/Dr.C-Standalone/releases'],
  ['Dr.C Terminal', 'github.com/mateolarreaferro/Dr.C'],
  ['CsoundQt 7', 'github.com/CsoundQt/CsoundQt/releases'],
  ['Cabbage', 'cabbageaudio.com/download'],
  ['Audacity', 'audacityteam.org/download'],
  ['Reaper', 'reaper.fm/download.php'],
  ['Full guide', 'PARTICIPANTS.md in repo'],
]

function drawHandoutPage(doc) {
  const W = doc.page.width
  const margin = 36
  let y = margin

  doc.fillColor('#1a1a2e')
  doc.font('Helvetica-Bold').fontSize(28).text('Dr.C @ LAC 2026', margin, y, { width: W - margin * 2 })
  y += 36
  doc.font('Helvetica').fontSize(13).fillColor('#444')
  doc.text('macOS & Linux only  ·  Csound 7  ·  Standalone v1.3.1', margin, y)
  y += 28

  doc.moveTo(margin, y).lineTo(W - margin, y).strokeColor('#ccc').stroke()
  y += 16

  const colW = (W - margin * 2 - 24) / 2
  const leftX = margin
  const rightX = margin + colW + 24
  let leftY = y
  let rightY = y

  doc.font('Helvetica-Bold').fontSize(12).fillColor('#1a1a2e')
  doc.text('Get started', leftX, leftY, { width: colW })
  leftY += 18
  doc.font('Helvetica').fontSize(10).fillColor('#222')
  const steps = [
    '1. Install Csound 7 → csound --version shows 7.x',
    '2. Get Dr.C — Releases (DMG/AppImage) or git clone lac-2026-csound7',
    '3. Launch — Dr.C-Workshop-Attendee (free) or Dr.C-Standalone (instructor)',
    '4. Agent model — Ollama (free, local) OR your Anthropic/OpenAI key',
    '5. No key? Agent → Load workshop FM bell · Player → Workshop demo · Web Apps',
  ]
  for (const s of steps) {
    doc.text(s, leftX, leftY, { width: colW, lineGap: 2 })
    leftY += doc.heightOfString(s, { width: colW, lineGap: 2 }) + 6
  }

  leftY += 8
  doc.font('Helvetica-Bold').fontSize(11).text('Try this prompt', leftX, leftY, { width: colW })
  leftY += 14
  doc.font('Courier').fontSize(8).fillColor('#333')
  const prompt =
    'make a plain Csound CSD only — no Cabbage. Shimmering FM bell: two inharmonic oscili modulators into a carrier, expsegr decay, global reverb bus (instr 99). Score: descending bell melody (~15 s).'
  doc.text(prompt, leftX, leftY, { width: colW, lineGap: 1 })

  doc.font('Helvetica-Bold').fontSize(12).fillColor('#1a1a2e')
  doc.text('Links', rightX, rightY, { width: colW })
  rightY += 18

  for (const [section, items] of LINKS) {
    doc.font('Helvetica-Bold').fontSize(10).fillColor('#2d4a7a').text(section, rightX, rightY, { width: colW })
    rightY += 13
    doc.font('Helvetica').fontSize(9).fillColor('#222')
    for (const [label, url] of items) {
      doc.text(`${label}: ${url}`, rightX, rightY, { width: colW, lineGap: 1 })
      rightY += doc.heightOfString(`${label}: ${url}`, { width: colW }) + 2
    }
    rightY += 6
  }

  const footY = doc.page.height - margin - 14
  doc.font('Helvetica').fontSize(9).fillColor('#666')
  doc.text(
    'Settings → Copy workshop links  ·  Full guide: PARTICIPANTS.md & LOCAL-LLM.md in repo',
    margin,
    footY,
    { width: W - margin * 2, align: 'center' },
  )
}

function drawInstallSlide(doc) {
  const W = doc.page.width
  const margin = 40
  let y = margin

  doc.fillColor('#1a1a2e')
  doc.font('Helvetica-Bold').fontSize(32).text('LAC 2026 — Dr.C Workshop Setup', margin, y, { width: W - margin * 2 })
  y += 40
  doc.font('Helvetica').fontSize(14).fillColor('#444')
  doc.text('macOS & Linux  ·  branch lac-2026-csound7  ·  Csound 7 required', margin, y)
  y += 30

  doc.moveTo(margin, y).lineTo(W - margin, y).strokeColor('#ccc').stroke()
  y += 18

  const colW = (W - margin * 2 - 28) / 2
  const leftX = margin
  const rightX = margin + colW + 28
  let leftY = y
  let rightY = y

  doc.font('Helvetica-Bold').fontSize(13).fillColor('#1a1a2e').text('Install steps', leftX, leftY, { width: colW })
  leftY += 20
  doc.font('Helvetica').fontSize(11).fillColor('#222')

  const steps = [
    '1. Csound 7 — csound --version must show 7.x',
    '2. Node.js 22 (+ Bun for Dr.C Terminal)',
    '3. Get Dr.C — GitHub Releases (DMG / AppImage) or git clone',
    '4. Launch — Workshop-Attendee (free) or Standalone (instructor)',
    '5. Verify — cd Dr.C-Standalone && npm test',
    '6. Agent (optional) — Ollama local OR API key in Settings',
  ]
  for (const s of steps) {
    doc.text(s, leftX, leftY, { width: colW, lineGap: 3 })
    leftY += doc.heightOfString(s, { width: colW, lineGap: 3 }) + 8
  }

  leftY += 6
  doc.font('Helvetica-Bold').fontSize(12).fillColor('#2d4a7a').text('macOS', leftX, leftY, { width: colW })
  leftY += 16
  doc.font('Helvetica').fontSize(10).fillColor('#222')
  const macNotes = [
    '• Csound 7 .pkg/.dmg → ~/Applications/Csound/ · ln -sf to ~/bin/csound',
    '• Node 22 from nodejs.org (or Homebrew node@22)',
    '• Double-click launchers/*.command (chmod +x if needed)',
    '• Unsigned app: Right-click → Open',
  ]
  for (const line of macNotes) {
    doc.text(line, leftX, leftY, { width: colW, lineGap: 2 })
    leftY += doc.heightOfString(line, { width: colW, lineGap: 2 }) + 4
  }

  doc.font('Helvetica-Bold').fontSize(13).fillColor('#1a1a2e').text('Linux notes', rightX, rightY, { width: colW })
  rightY += 20
  doc.font('Helvetica').fontSize(10).fillColor('#222')
  const linuxNotes = [
    '• Ubuntu 22.04 apt csound = 6.17 — build CS7 from source or use releases',
    '• Node 22: deb.nodesource.com/setup_22.x',
    '• chmod +x launchers/*.sh scripts/*.sh',
    '• ./launchers/Dr.C-Workshop-Attendee.sh or Dr.C-Standalone.sh',
    '• Headless SSH: npm test works; GUI needs DISPLAY',
  ]
  for (const line of linuxNotes) {
    doc.text(line, rightX, rightY, { width: colW, lineGap: 2 })
    rightY += doc.heightOfString(line, { width: colW, lineGap: 2 }) + 4
  }

  rightY += 10
  doc.font('Helvetica-Bold').fontSize(12).fillColor('#2d4a7a').text('Optional tools (recommended)', rightX, rightY, { width: colW })
  rightY += 16
  doc.font('Helvetica').fontSize(10).fillColor('#222')
  const optional = [
    '• CsoundQt 7 — Csound IDE (macOS DMG; Linux AppImage)',
    '• Cabbage — live plugin UI (macOS DMG)',
    '• Audacity — listen/edit WAV exports',
    '• Reaper — lightweight DAW host',
  ]
  for (const line of optional) {
    doc.text(line, rightX, rightY, { width: colW, lineGap: 2 })
    rightY += doc.heightOfString(line, { width: colW, lineGap: 2 }) + 4
  }

  const footY = doc.page.height - margin - 36
  doc.moveTo(margin, footY - 8).lineTo(W - margin, footY - 8).strokeColor('#ddd').stroke()
  doc.font('Helvetica').fontSize(8).fillColor('#555')
  const linkLine = INSTALL_LINKS.map(([label, url]) => `${label}: ${url}`).join('   ·   ')
  doc.text(linkLine, margin, footY, { width: W - margin * 2, align: 'center', lineGap: 2 })
}

mkdirSync(OUT_DIR, { recursive: true })

const doc = new PDFDocument({ size: 'LETTER', layout: 'landscape', margin: 36 })
const chunks = []
doc.on('data', (c) => chunks.push(c))
doc.on('end', () => {
  writeFileSync(OUT_FILE, Buffer.concat(chunks))
  console.log(`Wrote ${OUT_FILE}`)
})

if (INSTALL_SLIDE) {
  drawInstallSlide(doc)
} else {
  drawHandoutPage(doc)
}
doc.end()
