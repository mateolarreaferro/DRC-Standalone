import { useState, useRef, useEffect, type CSSProperties } from 'react'
import { useNavigate, useLocation } from 'react-router-dom'
import { useAppStore } from '../../stores/appStore'
import { useCsoundConsoleStore } from '../../stores/csoundConsoleStore'
import { audioFeedback } from '../../styles/audio-feedback'
import { TAB_META } from '../../lib/tabMeta'

const NAV_PATHS = ['/agent', '/apps', '/player', '/graph']

export default function Sidebar() {
  const navigate = useNavigate()
  const location = useLocation()
  const { theme, toggleTheme, audioFeedbackEnabled } = useAppStore()
  const userPinned = useCsoundConsoleStore((s) => s.userPinned)
  const toggleConsole = useCsoundConsoleStore((s) => s.toggle)
  const [hoverKey, setHoverKey] = useState<string | null>(null)
  const lastMainTab = useRef('/agent')

  useEffect(() => {
    if (location.pathname !== '/settings') {
      lastMainTab.current = location.pathname
    }
  }, [location.pathname])

  const consoleKey = 'console'

  const navItems = NAV_PATHS
    .map((p) => TAB_META.find((t) => t.path === p)!)
    .filter(Boolean)
  const settings = TAB_META.find((t) => t.path === '/settings')!

  const handleNav = (path: string, index: number) => {
    if (audioFeedbackEnabled) audioFeedback.navigate(index)
    navigate(path)
  }

  const handleThemeToggle = () => {
    if (audioFeedbackEnabled) audioFeedback.toggle(theme === 'dark')
    toggleTheme()
  }

  const themeKey = 'theme'
  const themeLabel = `Switch to ${theme === 'dark' ? 'light' : 'dark'} mode`
  const themeDesc = 'Toggle between the dark and light palette.'

  return (
    <div style={styles.sidebar}>
      {/* Logo */}
      <div style={styles.logoArea} className="drag-region">
        <span style={styles.logo}>Dr</span>
        <span style={styles.logoAccent}>C</span>
      </div>

      {/* Navigation */}
      <div style={styles.nav}>
        {navItems.map((item, i) => {
          const active = location.pathname === item.path
          return (
            <div
              key={item.path}
              style={styles.navCell}
              onMouseEnter={() => setHoverKey(item.path)}
              onMouseLeave={() => setHoverKey((k) => (k === item.path ? null : k))}
            >
              <button
                onClick={() => handleNav(item.path, i)}
                style={{
                  ...styles.navButton,
                  ...(active ? styles.navButtonActive : {}),
                }}
                aria-label={item.label}
                className="no-drag"
              >
                <span style={styles.navIcon}>{item.icon}</span>
              </button>
              {hoverKey === item.path && (
                <Tooltip label={item.label} desc={item.description} />
              )}
            </div>
          )
        })}
      </div>

      {/* Bottom controls */}
      <div style={styles.bottom}>
        <div
          style={styles.navCell}
          onMouseEnter={() => setHoverKey(consoleKey)}
          onMouseLeave={() => setHoverKey((k) => (k === consoleKey ? null : k))}
        >
          <button
            onClick={() => {
              if (audioFeedbackEnabled) audioFeedback.click()
              toggleConsole()
            }}
            style={{
              ...styles.navButton,
              ...(userPinned ? styles.navButtonActive : {}),
            }}
            aria-label="Csound output console"
            className="no-drag"
          >
            <span style={styles.navIcon}>&gt;_</span>
          </button>
          {hoverKey === consoleKey && (
            <Tooltip
              label={userPinned ? 'Hide Csound console' : 'Show Csound console'}
              desc="Hidden by default — opens on errors, or pin it on to keep visible."
            />
          )}
        </div>
        <div
          style={styles.navCell}
          onMouseEnter={() => setHoverKey(themeKey)}
          onMouseLeave={() => setHoverKey((k) => (k === themeKey ? null : k))}
        >
          <button
            onClick={handleThemeToggle}
            style={styles.navButton}
            aria-label={themeLabel}
            className="no-drag"
          >
            <span style={styles.navIcon}>{theme === 'dark' ? '○' : '●'}</span>
          </button>
          {hoverKey === themeKey && <Tooltip label={themeLabel} desc={themeDesc} />}
        </div>
        <div
          style={styles.navCell}
          onMouseEnter={() => setHoverKey(settings.path)}
          onMouseLeave={() => setHoverKey((k) => (k === settings.path ? null : k))}
        >
          <button
            onClick={() => {
              if (audioFeedbackEnabled) audioFeedback.click()
              if (location.pathname === settings.path) {
                navigate(lastMainTab.current || '/agent')
              } else {
                navigate('/settings')
              }
            }}
            style={{
              ...styles.navButton,
              ...(location.pathname === settings.path ? styles.navButtonActive : {}),
            }}
            aria-label={settings.label}
            className="no-drag"
          >
            <span style={styles.navIcon}>{settings.icon}</span>
          </button>
          {hoverKey === settings.path && (
            <Tooltip label={settings.label} desc={settings.description} />
          )}
        </div>
      </div>
    </div>
  )
}

function Tooltip({ label, desc }: { label: string; desc: string }) {
  return (
    <div style={styles.tooltip} role="tooltip">
      <div style={styles.tooltipLabel}>{label}</div>
      <div style={styles.tooltipDesc}>{desc}</div>
    </div>
  )
}

const styles: Record<string, CSSProperties> = {
  sidebar: {
    width: 72,
    height: '100vh',
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    background: 'var(--bg-secondary)',
    borderRight: 'var(--border-width) solid var(--border)',
    paddingTop: 48,
    paddingBottom: 16,
    flexShrink: 0,
    position: 'relative',
    zIndex: 5,
  },
  logoArea: {
    marginBottom: 32,
    textAlign: 'center',
  },
  logo: {
    fontFamily: 'var(--font-primary)',
    fontSize: 18,
    fontWeight: 600,
    color: 'var(--text-primary)',
    letterSpacing: '0.04em',
  },
  logoAccent: {
    fontFamily: 'var(--font-primary)',
    fontSize: 18,
    fontWeight: 300,
    color: 'var(--accent)',
    letterSpacing: '0.04em',
  },
  nav: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    gap: 4,
    flex: 1,
  },
  navCell: {
    position: 'relative',
  },
  navButton: {
    width: 44,
    height: 44,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    border: 'none',
    background: 'transparent',
    borderRadius: 12,
    color: 'var(--text-muted)',
    transition: 'all var(--transition-fast)',
  },
  navButtonActive: {
    background: 'var(--accent-muted)',
    color: 'var(--accent)',
  },
  navIcon: {
    fontSize: 20,
  },
  bottom: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    gap: 4,
  },
  tooltip: {
    position: 'absolute',
    left: 'calc(100% + 10px)',
    top: '50%',
    transform: 'translateY(-50%)',
    width: 260,
    padding: '10px 14px',
    background: 'var(--bg-tertiary)',
    border: 'var(--border-width) solid var(--border)',
    borderRadius: 10,
    boxShadow: 'var(--shadow-elevated)',
    zIndex: 10,
    pointerEvents: 'none',
    // Opacity-only — drc-fade-in animates transform too, which would override
    // the static translateY(-50%) centering and make the tooltip pop in below
    // its final spot before snapping up.
    animation: 'drc-fade-opacity 120ms ease',
  },
  tooltipLabel: {
    fontSize: 13,
    fontWeight: 500,
    color: 'var(--text-primary)',
    marginBottom: 4,
  },
  tooltipDesc: {
    fontSize: 12,
    color: 'var(--text-muted)',
    lineHeight: 1.5,
  },
}
