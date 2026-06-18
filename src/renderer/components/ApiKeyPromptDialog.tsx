import { type CSSProperties } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { OPENROUTER_OPTION, PROVIDER_OPTIONS } from '../lib/providerGuide'

interface Props {
  onClose: () => void
}

/** Shown when the user tries to generate before configuring an LLM provider. */
export default function ApiKeyPromptDialog({ onClose }: Props) {
  const navigate = useNavigate()
  const groq = PROVIDER_OPTIONS.find((p) => p.id === 'groq')!
  const gemini = PROVIDER_OPTIONS.find((p) => p.id === 'google')!

  const goSettings = () => {
    navigate('/settings')
    onClose()
  }

  return (
    <div style={styles.backdrop} role="dialog" aria-modal="true" aria-label="API key needed">
      <div style={styles.modal}>
        <h2 style={styles.title}>Set up a model for the Agent</h2>
        <p style={styles.body}>
          The Agent needs a configured model — not a URL pasted in chat.
        </p>
        <div style={styles.localBox}>
          <strong>Using Ollama?</strong> If <strong>Test</strong> already worked in Settings:
          <ol style={styles.steps}>
            <li>Open <strong>Settings → Local LLM server</strong></li>
            <li>Turn <strong>Use local LLM for Agent</strong> <strong>On</strong> (Test alone is not enough)</li>
            <li>Return to Agent and send your Csound prompt</li>
          </ol>
          Server URL (<code style={styles.code}>http://127.0.0.1:11434</code>) belongs in Settings, not here.
        </div>
        <p style={styles.body}>
          <strong>Other options:</strong> one <strong>OpenRouter</strong> key · free cloud <strong>Groq</strong> / <strong>Gemini</strong>
          {' '}· no model: <strong>Web Apps</strong> or <strong>Player → Workshop demo</strong>.
        </p>
        <div style={styles.links}>
          <a href={OPENROUTER_OPTION.signupUrl} target="_blank" rel="noopener noreferrer" style={styles.extLink}>
            Get {OPENROUTER_OPTION.label} key →
          </a>
          <a href={groq.signupUrl} target="_blank" rel="noopener noreferrer" style={styles.extLink}>
            Get free {groq.label} key →
          </a>
          <a href={gemini.signupUrl} target="_blank" rel="noopener noreferrer" style={styles.extLink}>
            Get free {gemini.label} key →
          </a>
        </div>
        <div style={styles.footer}>
          <button style={styles.ghost} onClick={onClose}>Not now</button>
          <button
            style={styles.ghost}
            onClick={() => {
              onClose()
              navigate('/player')
            }}
          >
            Player demo
          </button>
          <Link to="/settings" style={styles.linkBtn} onClick={onClose}>
            Open Settings
          </Link>
          <button style={styles.primary} onClick={goSettings}>Add key in Settings</button>
        </div>
      </div>
    </div>
  )
}

const styles: Record<string, CSSProperties> = {
  backdrop: {
    position: 'fixed',
    inset: 0,
    zIndex: 850,
    background: 'rgba(0, 0, 0, 0.45)',
    backdropFilter: 'blur(6px)',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  modal: {
    width: 'min(480px, 94vw)',
    padding: '28px 32px',
    borderRadius: 16,
    border: 'var(--border-width) solid var(--border)',
    background: 'var(--bg-primary)',
    boxShadow: 'var(--shadow-elevated)',
  },
  title: {
    margin: '0 0 10px',
    fontSize: 18,
    fontWeight: 500,
    color: 'var(--text-primary)',
  },
  body: {
    margin: '0 0 10px',
    fontSize: 14,
    lineHeight: 1.55,
    color: 'var(--text-secondary)',
  },
  localBox: {
    margin: '12px 0',
    padding: '12px 14px',
    borderRadius: 10,
    border: '1px solid var(--border)',
    background: 'var(--bg-secondary)',
    fontSize: 13,
    lineHeight: 1.55,
    color: 'var(--text-secondary)',
  },
  steps: {
    margin: '8px 0 0',
    paddingLeft: 20,
  },
  code: {
    fontFamily: 'var(--font-mono)',
    fontSize: 12,
  },
  links: {
    display: 'flex',
    flexDirection: 'column',
    gap: 6,
    marginTop: 14,
  },
  extLink: {
    fontSize: 12,
    color: 'var(--accent)',
    textDecoration: 'none',
  },
  footer: {
    display: 'flex',
    alignItems: 'center',
    gap: 8,
    marginTop: 22,
    flexWrap: 'wrap',
  },
  ghost: {
    padding: '9px 14px',
    borderRadius: 10,
    border: 'none',
    background: 'transparent',
    color: 'var(--text-muted)',
    fontSize: 13,
    cursor: 'pointer',
    fontFamily: 'var(--font-primary)',
  },
  linkBtn: {
    padding: '9px 14px',
    borderRadius: 10,
    border: 'var(--border-width) solid var(--border)',
    background: 'transparent',
    color: 'var(--text-secondary)',
    fontSize: 13,
    textDecoration: 'none',
    marginLeft: 'auto',
  },
  primary: {
    padding: '9px 18px',
    borderRadius: 10,
    border: 'none',
    background: 'var(--accent)',
    color: 'var(--bg-primary)',
    fontSize: 13,
    fontWeight: 500,
    cursor: 'pointer',
    fontFamily: 'var(--font-primary)',
  },
}
