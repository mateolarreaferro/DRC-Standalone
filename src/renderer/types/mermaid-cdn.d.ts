declare module 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs' {
  const mermaid: {
    initialize: (config: Record<string, unknown>) => void
    run: (opts: { nodes: HTMLElement[] | NodeListOf<Element> }) => Promise<void>
  }
  export default mermaid
}
