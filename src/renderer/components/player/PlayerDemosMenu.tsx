import { useEffect, useMemo, useState, type CSSProperties, type RefObject } from 'react'
import { deletePlayerDemo, listPlayerDemos, type WorkshopStarterMeta } from '../../lib/workshopDemos'

interface PlayerDemosMenuProps {
  disabled?: boolean
  onLoad: (id: string) => void
  onDeleted?: (id: string) => void
  sectionRef?: RefObject<HTMLDivElement | null>
  refreshKey?: number
}

export default function PlayerDemosMenu({
  disabled,
  onLoad,
  onDeleted,
  sectionRef,
  refreshKey = 0,
}: PlayerDemosMenuProps) {
  const [demos, setDemos] = useState<WorkshopStarterMeta[]>([])
  const [selected, setSelected] = useState('')
  const [deleting, setDeleting] = useState(false)

  useEffect(() => {
    void listPlayerDemos().then(setDemos)
  }, [refreshKey])

  const groups = useMemo(() => {
    const map = new Map<string, WorkshopStarterMeta[]>()
    for (const demo of demos) {
      const group = demo.demoGroup ?? 'Demos'
      const list = map.get(group) ?? []
      list.push(demo)
      map.set(group, list)
    }
    return map
  }, [demos])

  const selectedMeta = demos.find((d) => d.id === selected)
  const canDelete = Boolean(selected?.startsWith('user_'))

  const handleDelete = async () => {
    if (!selected || !canDelete) return
    const name = selectedMeta?.title ?? 'this demo'
    if (!window.confirm(`Remove “${name}” from your demo menu?`)) return
    setDeleting(true)
    try {
      const r = await deletePlayerDemo(selected)
      if (!r.ok) {
        window.alert(r.error ?? 'Could not delete demo')
        return
      }
      setSelected('')
      onDeleted?.(selected)
      const next = await listPlayerDemos()
      setDemos(next)
    } finally {
      setDeleting(false)
    }
  }

  return (
    <div ref={sectionRef} style={styles.wrap}>
      <span style={styles.label}>Demos — No API Key Required</span>
      <select
        value={selected}
        onChange={(e) => {
          const id = e.target.value
          setSelected(id)
          if (id) onLoad(id)
        }}
        style={styles.select}
        disabled={disabled || demos.length === 0}
        title={selectedMeta?.description ?? 'Choose a bundled Csound model'}
      >
        <option value="">Choose a demo…</option>
        {[...groups.entries()].map(([group, items]) => (
          <optgroup key={group} label={group}>
            {items.map((d) => (
              <option key={d.id} value={d.id}>
                {d.title}
              </option>
            ))}
          </optgroup>
        ))}
      </select>
      <button
        type="button"
        style={styles.loadBtn}
        disabled={disabled || !selected}
        onClick={() => selected && onLoad(selected)}
      >
        Load demo
      </button>
      {canDelete && (
        <button
          type="button"
          style={styles.deleteBtn}
          disabled={disabled || deleting}
          onClick={() => void handleDelete()}
          title="Remove this saved demo from My Demos"
        >
          {deleting ? 'Deleting…' : 'Delete'}
        </button>
      )}
    </div>
  )
}

const styles: Record<string, CSSProperties> = {
  wrap: {
    display: 'flex',
    alignItems: 'center',
    gap: 8,
    flexWrap: 'wrap',
  },
  label: {
    fontSize: 12,
    fontWeight: 600,
    color: 'var(--text-secondary)',
    whiteSpace: 'nowrap',
  },
  select: {
    minWidth: 200,
    maxWidth: 280,
    padding: '6px 10px',
    borderRadius: 8,
    border: '1px solid var(--border)',
    background: 'var(--bg-primary)',
    color: 'var(--text-primary)',
    fontSize: 12,
    fontFamily: 'var(--font-primary)',
  },
  loadBtn: {
    padding: '6px 12px',
    borderRadius: 8,
    border: '1px solid var(--border)',
    background: 'var(--bg-tertiary)',
    color: 'var(--text-primary)',
    fontSize: 12,
    fontFamily: 'var(--font-primary)',
    cursor: 'pointer',
    whiteSpace: 'nowrap',
  },
  deleteBtn: {
    padding: '6px 12px',
    borderRadius: 8,
    border: '1px solid #c44',
    background: 'transparent',
    color: '#e66',
    fontSize: 12,
    fontFamily: 'var(--font-primary)',
    cursor: 'pointer',
    whiteSpace: 'nowrap',
  },
}
