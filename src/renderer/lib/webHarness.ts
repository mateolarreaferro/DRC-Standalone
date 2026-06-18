// Deterministic web-app builder for the "Convert to Web App" path.
//
// The LLM no longer hand-writes the HTML. It emits a web-ready orchestra CSD
// (chn_k declarations = the control manifest); the host parses that manifest
// (parseChannels) and this module assembles a fixed, self-contained HTML page
// around it. Because WE own the runtime, the three long-standing complaints are
// structurally impossible:
//
//   - sliders are responsive  — every <input> writes the channel live via
//     setControlChannel, and the orchestra contract reads k-rate + port-smoothed
//   - there is always an on/off — a real master Start/Stop, not a one-shot button
//   - the UI is consistent     — one hand-designed template, identical every time
//
// The output is a single standalone document (no build step, no frameworks) so
// it renders in the artifact iframe AND exports/downloads to run anywhere.

import type { ChannelSpec } from './parseChannels'
import { buildSignalFlowStudy } from './signalFlowStudy'

export interface WebAppOptions {
  /** The `<CsInstruments>` body, used verbatim as the compileOrc() source. */
  orc: string
  /** Parsed chn_k manifest — one slider per spec. */
  channels: ChannelSpec[]
  /** Page title (and <h1>). */
  title: string
  /** True when the patch is note-based (orchestra references p4). */
  hasKeyboard: boolean
  /** True when the orchestra defines an always-on reverb bus (instr 99). */
  hasReverbBus: boolean
}

// Pinned to the Csound build the bundled reference apps are verified against
// (src/renderer/assets/apps/fm-bell.html).
const CSOUND_CDN =
  'https://cdn.jsdelivr.net/npm/@csound/browser@7.0.0-beta31/dist/csound.js'

// Theme — hardcoded (the exported file is standalone, so it can't use the app's
// CSS variables). Mirrors the app tokens: dark bg, sage accent.
const THEME = {
  bg: '#111110',
  panel: '#1a1a18',
  text: '#e0e0e0',
  muted: '#6b7670',
  accent: '#7cb8a4',
  border: '#2a2a28',
}

// Embed a JS string/value safely inside an inline <script>: JSON-encode, then
// neutralize any "</script>" or "<!--" sequences the source might contain.
function jsLiteral(value: unknown): string {
  return JSON.stringify(value).replace(/</g, '\\u003c')
}

function htmlEscape(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
}

function clampChannel(ch: ChannelSpec, v: number): number {
  return Math.min(ch.max, Math.max(ch.min, v))
}

/** Factory presets baked into the export — derived from chn_k conversion defaults. */
function buildFactoryPresets(channels: ChannelSpec[]): Record<string, Record<string, number>> {
  if (!channels.length) return {}

  const defaults: Record<string, number> = {}
  for (const ch of channels) defaults[ch.name] = ch.default

  const presets: Record<string, Record<string, number>> = {
    Default: { ...defaults },
  }

  const expressive = { ...defaults }
  for (const ch of channels) {
    const n = ch.name.toLowerCase()
    if (/reverb|mix|depth|wet|send|size/.test(n)) {
      expressive[ch.name] = clampChannel(ch, ch.default * 1.35 + ch.min * 0.1)
    } else if (/index|mod|bright|cutoff|reson|fm/.test(n)) {
      expressive[ch.name] = clampChannel(ch, ch.default * 1.25)
    } else if (/attack|att/.test(n)) {
      expressive[ch.name] = clampChannel(ch, ch.default * 0.55)
    } else if (/release|rel|decay|sustain/.test(n)) {
      expressive[ch.name] = clampChannel(ch, ch.default * 1.2 + (ch.max - ch.default) * 0.08)
    }
  }
  presets.Expressive = expressive

  const subtle = { ...defaults }
  for (const ch of channels) {
    const n = ch.name.toLowerCase()
    if (/reverb|mix|index|mod|amp|vol|depth|wet|send/.test(n)) {
      subtle[ch.name] = clampChannel(ch, ch.default * 0.6 + ch.min * 0.2)
    } else if (/attack|att/.test(n)) {
      subtle[ch.name] = clampChannel(ch, ch.default * 1.4)
    }
  }
  presets.Subtle = subtle

  return presets
}

function presetStorageKey(title: string, channels: ChannelSpec[]): string {
  const slug = title.replace(/[^a-zA-Z0-9]+/g, '-').replace(/^-+|-+$/g, '').toLowerCase().slice(0, 36) || 'app'
  let h = 0
  const sig = channels.map((c) => c.name).join(',')
  for (let i = 0; i < sig.length; i++) h = ((h << 5) - h + sig.charCodeAt(i)) | 0
  return `drcWebPresets_v1_${slug}_${Math.abs(h)}`
}

export function buildWebApp(opts: WebAppOptions): string {
  const title = (opts.title || 'Csound Web App').trim()
  const safeTitle = htmlEscape(title)
  const hasControls = opts.channels.length > 0
  const factoryPresets = buildFactoryPresets(opts.channels)
  const presetsKey = presetStorageKey(title, opts.channels)
  const study = buildSignalFlowStudy({
    title,
    source: opts.orc,
    channels: opts.channels,
    hasKeyboard: opts.hasKeyboard,
    hasReverbBus: opts.hasReverbBus,
  })

  return `<!doctype html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>${safeTitle}</title>
<style>
${STYLES}
</style>
</head>
<body>
<div class="wrap">
  <h1>${safeTitle}</h1>
  <p class="sub">Csound web app, made with DrC</p>

  <div class="btn-row">
    <button id="power" class="power">Start Audio</button>
    <button id="studyBtn" class="aux-btn" type="button">Study flow</button>
    <button id="panicBtn" class="aux-btn" type="button" hidden>Panic</button>
    <button id="randBtn" class="rand-btn" type="button" hidden>Randomize</button>
  </div>
  <div id="status" class="status">Press Start Audio to load the engine.</div>

  <div id="vizPanel" class="panel viz" hidden>
    <div class="panel-title">Waveform &amp; Spectrum</div>
    <div class="viz-row">
      <canvas id="waveCanvas" class="viz-canvas"></canvas>
      <canvas id="fftCanvas" class="viz-canvas"></canvas>
    </div>
  </div>

  <div id="presetPanel" class="panel presets"${hasControls ? '' : ' hidden'}>
    <div class="panel-title">Presets</div>
    <div class="preset-bar">
      <select id="presetSelect"><option value="">— select —</option></select>
      <button id="savePresetBtn" type="button">Save</button>
      <button id="delPresetBtn" type="button" class="del-btn">Delete</button>
    </div>
  </div>

  <div id="controls" class="controls"></div>

  <div id="keyboard" class="keyboard" hidden>
    <div class="kb-label">Piano keyboard — click keys or use your computer keyboard</div>
    <div class="piano-scroll">
      <div id="keys" class="piano"></div>
    </div>
    <div id="octaveLabels" class="piano-octaves"></div>
  </div>
</div>

<div id="studyOverlay" class="study-overlay" hidden>
  <div class="study-modal" role="dialog" aria-labelledby="studyTitle">
    <div class="study-head">
      <div>
        <h2 id="studyTitle">Study — signal flow</h2>
        <p class="study-sub">${safeTitle}</p>
      </div>
      <button id="studyClose" type="button" class="study-close" aria-label="Close">×</button>
    </div>
    <ul id="studySummary" class="study-summary"></ul>
    <div class="study-tabs">
      <button type="button" class="study-tab active" data-tab="architecture">Architecture</button>
      <button type="button" class="study-tab" data-tab="signal">Signal flow</button>
      <button type="button" class="study-tab" data-tab="controls">Controls</button>
    </div>
    <div id="studyDiagram" class="study-diagram"></div>
    <p class="study-foot">Auto-generated for study — compare with the orchestra in Dr.C.</p>
  </div>
</div>

<script>
const ORC = ${jsLiteral(opts.orc)};
const CHANNELS = ${jsLiteral(opts.channels)};
const HAS_KEYBOARD = ${opts.hasKeyboard ? 'true' : 'false'};
const HAS_REVERB_BUS = ${opts.hasReverbBus ? 'true' : 'false'};
const HAS_CONTROLS = ${hasControls ? 'true' : 'false'};
const PRESETS_KEY = ${jsLiteral(presetsKey)};
const FACTORY_PRESETS = ${jsLiteral(factoryPresets)};
const STUDY = ${jsLiteral(study)};
const CSOUND_CDN = ${jsLiteral(CSOUND_CDN)};

${RUNTIME}
</script>
</body>
</html>`
}

// ── Inlined CSS ──────────────────────────────────────────────────────────────
const STYLES = `
* { margin: 0; padding: 0; box-sizing: border-box; }
body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  background: ${THEME.bg};
  color: ${THEME.text};
  padding: 24px 16px;
  min-height: 100vh;
}
.wrap { max-width: 720px; margin: 0 auto; }
h1 { font-size: 1.6em; font-weight: 600; letter-spacing: -0.01em; }
.sub { color: ${THEME.muted}; font-size: 0.82em; margin: 4px 0 22px; }

.btn-row { display: flex; gap: 8px; margin-bottom: 0; }
.btn-row .power { flex: 1; }

.power {
  display: block; width: 100%;
  background: ${THEME.accent}; color: #0d0d0c;
  border: none; border-radius: 12px;
  padding: 14px; font-size: 1em; font-weight: 700;
  cursor: pointer; transition: filter .15s, opacity .15s;
}
.power:hover { filter: brightness(1.08); }
.power:disabled { opacity: .45; cursor: progress; }
.power.running { background: ${THEME.panel}; color: ${THEME.accent}; border: 1px solid ${THEME.accent}; }

.rand-btn {
  flex: 0 0 auto; padding: 14px 16px;
  background: #3d4a42; color: ${THEME.accent};
  border: 1px solid ${THEME.border}; border-radius: 12px;
  font-size: 0.82em; font-weight: 600; cursor: pointer;
}
.rand-btn:hover { filter: brightness(1.08); }

.aux-btn {
  flex: 0 0 auto; padding: 14px 16px;
  background: #3d2a2a; color: #e08c8c;
  border: 1px solid ${THEME.border}; border-radius: 12px;
  font-size: 0.82em; font-weight: 600; cursor: pointer;
}
.aux-btn:hover { filter: brightness(1.08); }

.viz-row { display: flex; gap: 10px; }
.viz-canvas {
  flex: 1; min-width: 0; height: 72px; width: 100%;
  background: #0d0d0c; border-radius: 8px; border: 1px solid ${THEME.border};
}

.panel {
  background: ${THEME.panel}; border: 1px solid ${THEME.border};
  border-radius: 14px; padding: 16px 18px; margin: 16px 0 0;
}
.panel.hidden { display: none; }
.panel-title {
  font-size: 0.72em; letter-spacing: .1em; text-transform: uppercase;
  color: ${THEME.muted}; margin-bottom: 10px; font-weight: 600;
}
.preset-bar { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
.preset-bar select {
  flex: 1; min-width: 140px;
  background: #232321; color: ${THEME.text};
  border: 1px solid ${THEME.border}; border-radius: 8px;
  padding: 8px 10px; font-size: 0.85em;
}
.preset-bar button {
  padding: 8px 14px; border-radius: 8px; border: 1px solid ${THEME.border};
  background: #232321; color: ${THEME.text}; font-size: 0.82em;
  font-weight: 600; cursor: pointer;
}
.preset-bar button:hover { background: #2c2c2a; }
.preset-bar button.del-btn { color: #e08c8c; }

.status {
  text-align: center; font-size: 0.82em; color: ${THEME.muted};
  margin: 12px 0 20px; min-height: 1.2em;
}
.status.error { color: #e08c8c; }
.status.ready { color: ${THEME.accent}; }

.controls {
  background: ${THEME.panel}; border: 1px solid ${THEME.border};
  border-radius: 14px; padding: 20px 22px; margin-top: 16px;
}
.controls:empty { display: none; }
.ctl { margin-bottom: 18px; }
.ctl:last-child { margin-bottom: 0; }
.ctl-top { display: flex; justify-content: space-between; align-items: baseline; margin-bottom: 7px; }
.ctl-label { font-size: 0.86em; color: ${THEME.text}; }
.ctl-val {
  font-family: "SF Mono", "Fira Code", ui-monospace, monospace;
  font-size: 0.82em; font-weight: 600; color: ${THEME.accent};
}
input[type="range"] {
  -webkit-appearance: none; appearance: none;
  width: 100%; height: 5px; border-radius: 3px;
  background: ${THEME.border}; outline: none; cursor: pointer;
}
input[type="range"]::-webkit-slider-thumb {
  -webkit-appearance: none; width: 17px; height: 17px; border-radius: 50%;
  background: ${THEME.accent}; cursor: pointer; transition: transform .1s;
}
input[type="range"]::-webkit-slider-thumb:active { transform: scale(1.15); }
input[type="range"]::-moz-range-thumb {
  width: 17px; height: 17px; border-radius: 50%; border: none;
  background: ${THEME.accent}; cursor: pointer;
}

.keyboard {
  margin-top: 16px; background: ${THEME.panel};
  border: 1px solid ${THEME.border}; border-radius: 14px; padding: 18px;
}
.kb-label { font-size: 0.74em; letter-spacing: .12em; text-transform: uppercase; color: ${THEME.muted}; margin-bottom: 12px; }
.piano-scroll {
  overflow-x: auto; overflow-y: hidden; padding-bottom: 2px;
  -webkit-overflow-scrolling: touch;
}
.piano {
  position: relative; height: 100px; margin: 0 auto;
  user-select: none;
}
.piano .key {
  position: absolute; top: 0; bottom: auto;
  display: flex; flex-direction: column; align-items: center; justify-content: flex-end;
  padding-bottom: 8px;
  cursor: pointer; user-select: none; box-sizing: border-box;
  transition: background .05s, box-shadow .05s, transform .05s;
}
.piano .key.white {
  width: 31px; height: 100px;
  background: linear-gradient(to bottom, #eceae4 0%, #d8d6d0 100%);
  border: 1px solid ${THEME.border}; border-top: none;
  border-radius: 0 0 4px 4px; z-index: 1;
  color: #4a4a48;
}
.piano .key.white:hover { background: linear-gradient(to bottom, #f5f3ed 0%, #e0ded8 100%); }
.piano .key.white.active {
  background: linear-gradient(to bottom, ${THEME.accent} 0%, #5a9a86 100%);
  color: #0d0d0c; transform: translateY(1px);
  box-shadow: inset 0 2px 8px rgba(0,0,0,0.15);
}
.piano .key.black {
  width: 20px; height: 62px;
  background: linear-gradient(to bottom, #2a2a28 0%, #121210 100%);
  border: 1px solid #0a0a09; border-top: none;
  border-radius: 0 0 3px 3px; z-index: 2;
  color: #888880; padding-bottom: 5px;
}
.piano .key.black:hover { background: linear-gradient(to bottom, #353533 0%, #1a1a18 100%); }
.piano .key.black.active {
  background: linear-gradient(to bottom, #6a9a88 0%, #3d5a50 100%);
  color: #e8f5f0; transform: translateY(1px);
  box-shadow: inset 0 2px 6px rgba(0,0,0,0.3);
}
.piano .key-bind {
  font-size: 9px; font-weight: 700;
  font-family: "SF Mono", "Fira Code", ui-monospace, monospace;
  opacity: .85; line-height: 1; pointer-events: none;
}
.piano-octaves {
  position: relative; height: 16px; margin: 4px auto 0;
  font-size: 10px;
  font-family: "SF Mono", "Fira Code", ui-monospace, monospace;
  color: ${THEME.muted};
}
.piano-octaves span { position: absolute; top: 2px; }

.study-overlay {
  position: fixed; inset: 0; z-index: 1000;
  background: rgba(0,0,0,0.65); display: flex; align-items: center; justify-content: center;
  padding: 20px;
}
.study-overlay[hidden] { display: none; }
.study-modal {
  width: min(900px, 96vw); max-height: 90vh; overflow: auto;
  background: ${THEME.panel}; border: 1px solid ${THEME.border}; border-radius: 14px;
  padding: 18px 20px 14px;
}
.study-head { display: flex; justify-content: space-between; align-items: flex-start; gap: 12px; }
.study-head h2 { font-size: 1.15em; margin: 0; font-weight: 600; }
.study-sub { margin: 4px 0 0; font-size: 0.78em; color: ${THEME.muted}; }
.study-close {
  width: 32px; height: 32px; border-radius: 8px; border: 1px solid ${THEME.border};
  background: #232321; color: ${THEME.text}; font-size: 1.2em; cursor: pointer;
}
.study-summary {
  margin: 12px 0 0; padding-left: 18px; font-size: 0.78em; color: ${THEME.muted}; line-height: 1.45;
}
.study-tabs { display: flex; gap: 6px; flex-wrap: wrap; margin: 14px 0 10px; }
.study-tab {
  padding: 6px 12px; border-radius: 8px; border: 1px solid ${THEME.border};
  background: #232321; color: ${THEME.text}; font-size: 0.78em; cursor: pointer;
}
.study-tab.active { background: #3d4a42; color: ${THEME.accent}; border-color: ${THEME.accent}; font-weight: 600; }
.study-diagram {
  min-height: 120px; background: #0d0d0c; border: 1px solid ${THEME.border};
  border-radius: 10px; padding: 12px; overflow: auto;
}
.study-foot { margin: 10px 0 0; font-size: 0.72em; color: ${THEME.muted}; text-align: center; }
`

// ── Inlined runtime (plain JS; no backticks, no template interpolation, so it
// survives being embedded in the TS template literal above unescaped) ─────────
const RUNTIME = `
var csound = null;
var running = false;
var starting = false;
var active = {};
var keyEls = {};

var powerBtn = document.getElementById("power");
var statusEl = document.getElementById("status");
var controlsEl = document.getElementById("controls");
var keyboardEl = document.getElementById("keyboard");
var keysEl = document.getElementById("keys");
var presetSelect = document.getElementById("presetSelect");
var savePresetBtn = document.getElementById("savePresetBtn");
var delPresetBtn = document.getElementById("delPresetBtn");
var randBtn = document.getElementById("randBtn");
var panicBtn = document.getElementById("panicBtn");
var vizPanel = document.getElementById("vizPanel");
var controlEls = {};
var analyser = null;
var animFrame = null;
var midiReady = false;

function setStatus(msg, cls) {
  statusEl.textContent = msg;
  statusEl.className = "status" + (cls ? " " + cls : "");
}

// Bound an await so a stalled network/WASM load never hangs forever on a loading
// status — whichever loses the race rejects with a clear, user-visible message.
function withTimeout(promise, ms, label) {
  return Promise.race([
    promise,
    new Promise(function (_, reject) {
      setTimeout(function () {
        reject(new Error(label + " timed out after " + (ms / 1000) + "s — check your network connection and press Start Audio again."));
      }, ms);
    })
  ]);
}

// ── Slider value mapping. Exponential channels with a positive floor get a log
// response so wide ranges (20Hz..20kHz, 1ms..2s) feel right at the low end. ──
function isExp(ch) { return ch.curve === "exp" && ch.min > 0; }
function sliderToValue(ch, raw) {
  if (isExp(ch)) { return ch.min * Math.pow(ch.max / ch.min, raw / 1000); }
  return raw;
}
function valueToSlider(ch, val) {
  if (isExp(ch)) {
    return Math.round((Math.log(val / ch.min) / Math.log(ch.max / ch.min)) * 1000);
  }
  return val;
}
function fmtValue(val, ch) {
  var d = ch.step >= 1 ? 0 : ch.step >= 0.1 ? 1 : ch.step >= 0.01 ? 2 : 3;
  var s = val.toFixed(d);
  return ch.unit ? s + " " + ch.unit : s;
}

function readSliderValue(ch, slider) {
  return sliderToValue(ch, Number(slider.value));
}

function writeSliderValue(ch, slider, out, val) {
  var v = Math.min(ch.max, Math.max(ch.min, val));
  if (isExp(ch)) slider.value = String(valueToSlider(ch, v));
  else slider.value = String(v);
  out.textContent = fmtValue(v, ch);
  if (running && csound) csound.setControlChannel(ch.name, v);
}

function buildControl(ch) {
  var row = document.createElement("div");
  row.className = "ctl";
  var top = document.createElement("div");
  top.className = "ctl-top";
  var label = document.createElement("span");
  label.className = "ctl-label";
  label.textContent = ch.label;
  var out = document.createElement("span");
  out.className = "ctl-val";
  out.textContent = fmtValue(ch.default, ch);
  var slider = document.createElement("input");
  slider.type = "range";
  slider.id = "ctl_" + ch.name;
  if (isExp(ch)) {
    slider.min = "0"; slider.max = "1000"; slider.step = "1";
    slider.value = String(valueToSlider(ch, ch.default));
  } else {
    slider.min = String(ch.min); slider.max = String(ch.max);
    slider.step = String(ch.step); slider.value = String(ch.default);
  }
  slider.addEventListener("input", function () {
    var val = readSliderValue(ch, slider);
    out.textContent = fmtValue(val, ch);
    if (running && csound) csound.setControlChannel(ch.name, val);
  });
  top.appendChild(label); top.appendChild(out);
  row.appendChild(top); row.appendChild(slider);
  controlsEl.appendChild(row);
  controlEls[ch.name] = { slider: slider, out: out, ch: ch };
}

for (var i = 0; i < CHANNELS.length; i++) { buildControl(CHANNELS[i]); }
if (HAS_CONTROLS && randBtn) randBtn.hidden = false;

// ── Presets (localStorage snapshots of all chn_k slider values) ─────────────
function getPresets() {
  try { return JSON.parse(localStorage.getItem(PRESETS_KEY)) || {}; }
  catch (e) { return {}; }
}
function savePresetsToStorage(p) {
  localStorage.setItem(PRESETS_KEY, JSON.stringify(p));
}
function refreshPresetList(sel) {
  if (!presetSelect) return;
  var p = getPresets(), names = Object.keys(p).sort();
  presetSelect.innerHTML = '<option value="">— select —</option>';
  for (var i = 0; i < names.length; i++) {
    var o = document.createElement("option");
    o.value = names[i]; o.textContent = names[i];
    if (names[i] === sel) o.selected = true;
    presetSelect.appendChild(o);
  }
}
function getCurrentSettings() {
  var s = {};
  for (var i = 0; i < CHANNELS.length; i++) {
    var ch = CHANNELS[i], el = controlEls[ch.name];
    if (el) s[ch.name] = readSliderValue(ch, el.slider);
  }
  return s;
}
function applySettings(s) {
  for (var i = 0; i < CHANNELS.length; i++) {
    var ch = CHANNELS[i], el = controlEls[ch.name];
    if (el && s[ch.name] !== undefined) writeSliderValue(ch, el.slider, el.out, Number(s[ch.name]));
  }
}
function savePreset() {
  var n = prompt("Preset name:");
  if (!n || !n.trim()) return;
  n = n.trim();
  var p = getPresets();
  p[n] = getCurrentSettings();
  savePresetsToStorage(p);
  refreshPresetList(n);
}
function loadPreset() {
  if (!presetSelect) return;
  var n = presetSelect.value;
  if (!n) return;
  var p = getPresets();
  if (p[n]) applySettings(p[n]);
}
function deletePreset() {
  if (!presetSelect) return;
  var n = presetSelect.value;
  if (!n) { alert("Select a preset first."); return; }
  if (!confirm('Delete "' + n + '"?')) return;
  var p = getPresets();
  delete p[n];
  savePresetsToStorage(p);
  refreshPresetList("");
}
function randomizeControls() {
  for (var i = 0; i < CHANNELS.length; i++) {
    var ch = CHANNELS[i], el = controlEls[ch.name];
    if (!el) continue;
    var n = ch.name.toLowerCase();
    if (/volume|amplitude|amp|level|gain/.test(n) && ch.default > 0) continue;
    var t = Math.random();
    var val = isExp(ch)
      ? ch.min * Math.pow(ch.max / ch.min, t)
      : ch.min + (ch.max - ch.min) * t;
    writeSliderValue(ch, el.slider, el.out, val);
  }
}
function initFactoryPresets() {
  if (!HAS_CONTROLS) return;
  var p = getPresets(), f = FACTORY_PRESETS;
  for (var k in f) { if (!p[k]) p[k] = f[k]; }
  savePresetsToStorage(p);
  refreshPresetList("");
}
if (savePresetBtn) savePresetBtn.addEventListener("click", savePreset);
if (delPresetBtn) delPresetBtn.addEventListener("click", deletePreset);
if (presetSelect) presetSelect.addEventListener("change", loadPreset);
if (randBtn) randBtn.addEventListener("click", randomizeControls);
initFactoryPresets();

// ── Output visualizer (AnalyserNode tap — fm-synth pattern) ─────────────────
function startVisualizerLoop() {
  if (!analyser) return;
  var wC = document.getElementById("waveCanvas");
  var fC = document.getElementById("fftCanvas");
  if (!wC || !fC) return;
  var wX = wC.getContext("2d");
  var fX = fC.getContext("2d");
  var bLen = analyser.frequencyBinCount;
  var tD = new Uint8Array(bLen);
  var fD = new Uint8Array(bLen);

  function draw() {
    animFrame = requestAnimationFrame(draw);
    var dpr = window.devicePixelRatio || 1;
    if (wC.width !== wC.clientWidth * dpr) {
      wC.width = wC.clientWidth * dpr;
      wC.height = wC.clientHeight * dpr;
      fC.width = fC.clientWidth * dpr;
      fC.height = fC.clientHeight * dpr;
    }
    var w = wC.width, h = wC.height, fw = fC.width, fh = fC.height;
    analyser.getByteTimeDomainData(tD);
    analyser.getByteFrequencyData(fD);

    wX.fillStyle = "rgba(13,13,12,0.35)";
    wX.fillRect(0, 0, w, h);
    wX.lineWidth = 2 * dpr;
    wX.strokeStyle = "#7cb8a4";
    wX.beginPath();
    var sl = w / bLen;
    for (var i = 0; i < bLen; i++) {
      var y = (tD[i] / 128) * h / 2;
      if (i === 0) wX.moveTo(0, y);
      else wX.lineTo(i * sl, y);
    }
    wX.stroke();

    fX.fillStyle = "rgba(13,13,12,0.35)";
    fX.fillRect(0, 0, fw, fh);
    var bars = Math.floor(bLen * 0.4), bW = fw / bars;
    for (var j = 0; j < bars; j++) {
      var val = fD[j] / 255, bH = val * fh;
      fX.fillStyle = "hsla(158,32%," + Math.round(40 + val * 28) + "%," + (0.55 + val * 0.4) + ")";
      fX.fillRect(j * bW, fh - bH, bW > 2 ? bW - 1 : bW, bH);
    }
  }
  draw();
}

function stopVisualizer() {
  if (animFrame) { cancelAnimationFrame(animFrame); animFrame = null; }
  if (vizPanel) vizPanel.hidden = true;
}

// ── Piano keyboard (3 octaves — matches Dr.C Player PianoKeyboard.tsx) ────
var PIANO_START_OCT = 3;
var PIANO_OCTAVES = 3;
var LOW_MIDI = PIANO_START_OCT * 12;
var HIGH_MIDI = (PIANO_START_OCT + PIANO_OCTAVES) * 12 - 1;
var WHITE_W = 32;
var BLACK_SHIFT = 12;

var PIANO_PATTERN = [
  { t: "w", s: 0 }, { t: "b", s: 1 }, { t: "w", s: 2 }, { t: "b", s: 3 }, { t: "w", s: 4 },
  { t: "w", s: 5 }, { t: "b", s: 6 }, { t: "w", s: 7 }, { t: "b", s: 8 }, { t: "w", s: 9 },
  { t: "b", s: 10 }, { t: "w", s: 11 }
];

var MIDI_TO_KEY = {
  36:"q",37:"1",38:"2",39:"3",40:"4",41:"5",42:"6",43:"7",44:"8",45:"9",46:"0",47:"-",
  48:"z",49:"s",50:"x",51:"d",52:"c",53:"f",54:"v",55:"g",56:"b",57:"h",58:"n",59:"j",
  60:"a",61:"w",62:"e",63:"r",64:"d",65:"f",66:"t",67:"g",68:"y",69:"h",70:"u",71:"j"
};

function keyLabelForMidi(m) {
  var k = MIDI_TO_KEY[m];
  return k ? k.toUpperCase() : "";
}
function midiForKey(k) {
  var key = k.length === 1 ? k.toLowerCase() : k;
  var matches = [];
  for (var mk in MIDI_TO_KEY) {
    if (MIDI_TO_KEY[mk] === key) matches.push(Number(mk));
  }
  var inRange = matches.filter(function (m) { return m >= LOW_MIDI && m <= HIGH_MIDI; });
  if (!inRange.length) return undefined;
  if (inRange.length === 1) return inRange[0];
  var mid = Math.floor((LOW_MIDI + HIGH_MIDI) / 2);
  inRange.sort(function (a, b) { return Math.abs(a - mid) - Math.abs(b - mid); });
  return inRange[0];
}

function midiToFreq(m) { return 440 * Math.pow(2, (m - 69) / 12); }
function tagFor(m) { return "1." + String(m).padStart(3, "0"); }

function bindKeyEl(el, midi) {
  el.addEventListener("mousedown", function (e) { e.preventDefault(); noteOn(midi); });
  el.addEventListener("mouseup", function () { noteOff(midi); });
  el.addEventListener("mouseleave", function () { noteOff(midi); });
  el.addEventListener("touchstart", function (e) { e.preventDefault(); noteOn(midi); }, { passive: false });
  el.addEventListener("touchend", function (e) { e.preventDefault(); noteOff(midi); }, { passive: false });
}

function buildKeyboard() {
  keysEl.innerHTML = "";
  keysEl.className = "piano";
  var whiteCount = 0;

  for (var oct = 0; oct < PIANO_OCTAVES; oct++) {
    for (var ki = 0; ki < PIANO_PATTERN.length; ki++) {
      var spec = PIANO_PATTERN[ki];
      var midi = (PIANO_START_OCT + oct) * 12 + spec.s;
      var el = document.createElement("div");
      el.className = "key " + (spec.t === "w" ? "white" : "black");
      el.dataset.midi = String(midi);

      if (spec.t === "w") {
        el.style.left = (whiteCount * WHITE_W) + "px";
        whiteCount++;
      } else {
        el.style.left = (whiteCount * WHITE_W - BLACK_SHIFT) + "px";
      }

      var bind = keyLabelForMidi(midi);
      if (bind) el.innerHTML = '<span class="key-bind">' + bind + '</span>';
      bindKeyEl(el, midi);
      keysEl.appendChild(el);
      keyEls[midi] = el;
    }
  }
  keysEl.style.width = (whiteCount * WHITE_W) + "px";

  var octEl = document.getElementById("octaveLabels");
  if (octEl) {
    octEl.innerHTML = "";
    octEl.style.width = (whiteCount * WHITE_W) + "px";
    for (var o = 0; o < PIANO_OCTAVES; o++) {
      var span = document.createElement("span");
      span.textContent = "C" + (PIANO_START_OCT + o);
      span.style.left = (o * 7 * WHITE_W + 2) + "px";
      octEl.appendChild(span);
    }
  }

  document.addEventListener("keydown", function (e) {
    if (e.repeat || e.metaKey || e.ctrlKey || e.altKey) return;
    var midi = midiForKey(e.key);
    if (midi !== undefined) { e.preventDefault(); noteOn(midi); }
  });
  document.addEventListener("keyup", function (e) {
    var midi = midiForKey(e.key);
    if (midi !== undefined) { e.preventDefault(); noteOff(midi); }
  });
}

// Web keyboard sends Hz in p4 and 0..1 velocity in p5 — not MIDI note numbers.
function adaptOrcForWebKeyboard(orc) {
  var b = orc;
  b = b.replace(/\\bcpsmidinn\\s*\\(\\s*p4\\s*\\)/gi, "p4");
  b = b.replace(/\\bcpsmidinn\\s*\\(\\s*p5\\s*\\)/gi, "p5");
  b = b.replace(/^\\s*(\\w+)\\s+cpsmidinn\\s+p4\\b([^\\n]*)/gim, "$1 = p4$2");
  b = b.replace(/^\\s*(\\w+)\\s+cpsmidinn\\s+p5\\b([^\\n]*)/gim, "$1 = p5$2");
  b = b.replace(/^\\s*(\\w+)\\s+cpsmidib\\s+\\d+\\b([^\\n;]*)/gim, "$1 = p4$2");
  b = b.replace(/^\\s*(\\w+)\\s+cpsmidib\\s+p4\\b([^\\n;]*)/gim, "$1 = p4$2");
  b = b.replace(/^\\s*iamp\\s+ampmidi\\s+([^\\n;]+)/gim, "iAmp = p5 * ($1)");
  b = b.replace(/^\\s*ilevl\\s+ampmidi\\s+([^\\n;]+)/gim, "iAmp = p5 * ($1)");
  b = b.replace(/^\\s*iveloc\\s+ampmidi\\s+([^\\n;]+)/gim, "iveloc = p5 * ($1)");
  b = b.replace(/^\\s*(\\w+)\\s+ampmidi\\s+([^\\n;]+)/gim, "$1 = p5 * ($2)");
  b = b.replace(/\\bp5\\s*\\/\\s*127\\b/g, "p5");
  return b;
}

function noteOn(m, vel) {
  if (!running || !csound || active[m]) return;
  active[m] = true;
  var v = vel !== undefined ? Math.min(1, Math.max(0, vel / 127)) : 0.8;
  csound.inputMessage("i " + tagFor(m) + " 0 -1 " + midiToFreq(m).toFixed(4) + " " + v.toFixed(4));
  if (keyEls[m]) keyEls[m].classList.add("active");
}
function noteOff(m) {
  if (!active[m]) return;
  delete active[m];
  if (csound) csound.inputMessage("i -" + tagFor(m) + " 0 0.01");
  if (keyEls[m]) keyEls[m].classList.remove("active");
}
function allNotesOff() {
  for (var m in active) { noteOff(Number(m)); }
}

function panicNotes() {
  allNotesOff();
  // Fractal Explorer pattern: kill all voice instances immediately (long tails).
  if (csound && running) csound.inputMessage("turnoff2 1, 0, 0");
}

function bindMidiInput(input) {
  input.onmidimessage = function (message) {
    var data = message.data;
    var cmdType = data[0] & 0xf0;
    var note = data[1];
    var velocity = data[2];
    if (cmdType === 0x90 && velocity > 0) noteOn(note, velocity);
    else if (cmdType === 0x80 || (cmdType === 0x90 && velocity === 0)) noteOff(note);
  };
}

function initMIDI() {
  if (!HAS_KEYBOARD || !navigator.requestMIDIAccess) return;
  navigator.requestMIDIAccess().then(function (access) {
    var inputs = access.inputs.values();
    var input;
    while (!(input = inputs.next()).done) bindMidiInput(input.value);
    access.onstatechange = function (event) {
      if (event.port.type === "input" && event.port.state === "connected")
        bindMidiInput(event.port);
    };
    midiReady = true;
    if (running) setStatus("Ready — keyboard, USB MIDI, or sliders.", "ready");
  }).catch(function () {});
}

if (HAS_KEYBOARD) {
  keyboardEl.hidden = false;
  buildKeyboard();
  if (panicBtn) panicBtn.hidden = false;
  if (panicBtn) panicBtn.addEventListener("click", panicNotes);
  initMIDI();
}

// ── Study flow (Mermaid block diagrams) ─────────────────────────────────────
var studyOverlay = document.getElementById("studyOverlay");
var studyDiagram = document.getElementById("studyDiagram");
var studySummary = document.getElementById("studySummary");
var studyBtn = document.getElementById("studyBtn");
var studyClose = document.getElementById("studyClose");
var studyTab = "architecture";
var studyMermaidLoaded = false;

function studyCodeForTab(tab) {
  if (tab === "signal") return STUDY.signalFlowMermaid;
  if (tab === "controls") return STUDY.controlsMermaid;
  return STUDY.architectureMermaid;
}

function renderStudyTab() {
  if (!studyDiagram) return;
  var code = studyCodeForTab(studyTab);
  studyDiagram.innerHTML = '<pre class="mermaid">' + code.replace(/</g, '&lt;') + '</pre>';
  if (!studyMermaidLoaded) {
    studyDiagram.querySelector('pre').textContent = code;
    import("https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs").then(function (mod) {
      studyMermaidLoaded = true;
      mod.default.initialize({ startOnLoad: false, theme: "dark", securityLevel: "loose" });
      return mod.default.run({ nodes: studyDiagram.querySelectorAll(".mermaid") });
    }).catch(function () {
      studyDiagram.innerHTML = "<pre style='font-size:11px;white-space:pre-wrap;color:#ccc'>" + code + "</pre>";
    });
  } else {
    import("https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs").then(function (mod) {
      return mod.default.run({ nodes: studyDiagram.querySelectorAll(".mermaid") });
    });
  }
}

function openStudy() {
  if (!studyOverlay || !studySummary) return;
  studySummary.innerHTML = "";
  for (var i = 0; i < STUDY.summary.length; i++) {
    var li = document.createElement("li");
    li.textContent = STUDY.summary[i];
    studySummary.appendChild(li);
  }
  studyOverlay.hidden = false;
  renderStudyTab();
}
function closeStudy() { if (studyOverlay) studyOverlay.hidden = true; }

if (studyBtn) studyBtn.addEventListener("click", openStudy);
if (studyClose) studyClose.addEventListener("click", closeStudy);
if (studyOverlay) studyOverlay.addEventListener("click", function (e) {
  if (e.target === studyOverlay) closeStudy();
});
var studyTabBtns = document.querySelectorAll(".study-tab");
for (var st = 0; st < studyTabBtns.length; st++) {
  studyTabBtns[st].addEventListener("click", function () {
    for (var j = 0; j < studyTabBtns.length; j++) studyTabBtns[j].classList.remove("active");
    this.classList.add("active");
    studyTab = this.getAttribute("data-tab") || "architecture";
    renderStudyTab();
  });
}

// ── Master Start / Stop ─────────────────────────────────────────────────────
async function start() {
  if (running || starting) return;
  starting = true;
  powerBtn.disabled = true;
  try {
    setStatus("Loading Csound from CDN...", "");
    var mod = await withTimeout(import(CSOUND_CDN), 20000, "Loading Csound from CDN");
    var Csound = mod.Csound;
    setStatus("Creating audio engine...", "");
    csound = await withTimeout(Csound({ useWorker: false, useSPN: false, outputChannelCount: 2 }), 20000, "Starting the audio engine");
    await csound.setOption("-odac");
    await csound.setOption("-m0");
    var orcBody = adaptOrcForWebKeyboard(ORC);
    setStatus("Compiling orchestra...", "");
    // WASM7 API: compileOrc + start + inputMessage (see fm-bell.html / fm-synth.html).
    // Do not use -Lstdin or readScore here — that path triggers longjmp 255 on start().
    var compileStatus = await csound.compileOrc(orcBody);
    if (compileStatus !== undefined && compileStatus !== 0) {
      throw new Error("the orchestra has a Csound syntax error (code " + compileStatus + "). See the browser console for the parser message.");
    }
    setStatus("Starting audio engine...", "");
    await csound.start();
    // Push current slider values (user may have moved knobs before Start).
    for (var i = 0; i < CHANNELS.length; i++) {
      var ch = CHANNELS[i], el = controlEls[ch.name];
      var val = el ? readSliderValue(ch, el.slider) : ch.default;
      await csound.setControlChannel(ch.name, val);
    }
    if (HAS_REVERB_BUS) await csound.inputMessage("i 99 0 -1");
    if (!HAS_KEYBOARD) await csound.inputMessage("i 1 0 -1");

    try {
      var ctx = await csound.getAudioContext();
      if (ctx) {
        analyser = ctx.createAnalyser();
        analyser.fftSize = 2048;
        analyser.smoothingTimeConstant = 0.8;
        var node = await csound.getNode();
        if (node) {
          node.connect(analyser);
          analyser.connect(ctx.destination);
          if (vizPanel) vizPanel.hidden = false;
          startVisualizerLoop();
        }
      }
    } catch (ve) { console.log("Visualizer:", ve.message); }

    running = true;
    starting = false;
    powerBtn.textContent = "Stop";
    powerBtn.classList.add("running");
    powerBtn.disabled = false;
    if (HAS_KEYBOARD) {
      setStatus(midiReady ? "Ready — keyboard, USB MIDI, or sliders." : "Ready — play the keyboard or drag a slider.", "ready");
    } else {
      setStatus("Running — drag a slider to shape the sound.", "ready");
    }
  } catch (err) {
    starting = false;
    powerBtn.disabled = false;
    setStatus("Error: " + (err && err.message ? err.message : err), "error");
    console.error(err);
  }
}

async function stop() {
  allNotesOff();
  running = false;
  stopVisualizer();
  analyser = null;
  if (csound) {
    try { await csound.stop(); } catch (e) {}
    try { if (csound.destroy) await csound.destroy(); } catch (e) {}
  }
  csound = null;
  active = {};
  powerBtn.textContent = "Start Audio";
  powerBtn.classList.remove("running");
  setStatus("Stopped. Press Start Audio to resume.", "");
}

powerBtn.addEventListener("click", function () {
  if (running) { stop(); } else { start(); }
});
`
