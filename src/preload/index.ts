import { contextBridge, ipcRenderer } from 'electron'

export interface StreamChunk {
  sessionID: string
  type: 'text' | 'tool_call' | 'tool_result' | 'narration' | 'suggestions' | 'error' | 'usage' | 'status'
  content: string
  toolName?: string
  toolArgs?: Record<string, unknown>
}

export interface StreamResult {
  sessionID: string
  error?: string
}

const api = {
  session: {
    create: (agentName: string) =>
      ipcRenderer.invoke('session:create', agentName),
    send: (sessionID: string, content: string, opts?: { retry?: boolean; variant?: boolean }) =>
      ipcRenderer.invoke('session:send', sessionID, content, opts),
    cancel: (sessionID: string) =>
      ipcRenderer.invoke('session:cancel', sessionID),
    list: () => ipcRenderer.invoke('session:list'),
    get: (id: string) => ipcRenderer.invoke('session:get', id),
  },

  stream: {
    onChunk: (cb: (chunk: StreamChunk) => void) => {
      const handler = (_: any, chunk: StreamChunk) => cb(chunk)
      ipcRenderer.on('stream:chunk', handler)
      return () => ipcRenderer.removeListener('stream:chunk', handler)
    },
    onComplete: (cb: (result: StreamResult) => void) => {
      const handler = (_: any, result: StreamResult) => cb(result)
      ipcRenderer.on('stream:complete', handler)
      return () => ipcRenderer.removeListener('stream:complete', handler)
    },
  },

  csound: {
    getEnvironment: () => ipcRenderer.invoke('csound:getEnvironment'),
    writeCsd: (content: string) =>
      ipcRenderer.invoke('csound:writeCsd', content),
    compile: (csdPath: string) =>
      ipcRenderer.invoke('csound:compile', csdPath),
    render: (csdPath: string, opts?: { output?: string }) =>
      ipcRenderer.invoke('csound:render', csdPath, opts),
    play: (csdPath: string, opts?: { realtime?: boolean }) =>
      ipcRenderer.invoke('csound:play', csdPath, opts),
    stop: () => ipcRenderer.invoke('csound:stop'),
    event: (line: string) => ipcRenderer.invoke('csound:event', line),
    setChannel: (name: string, value: number) =>
      ipcRenderer.invoke('csound:setChannel', name, value),
    onOutput: (cb: (chunk: { stream: 'stdout' | 'stderr' | 'info'; text: string }) => void) => {
      const handler = (_: unknown, chunk: { stream: 'stdout' | 'stderr' | 'info'; text: string }) => cb(chunk)
      ipcRenderer.on('csound:output', handler)
      return () => ipcRenderer.removeListener('csound:output', handler)
    },
    saveConsoleLog: (text: string) =>
      ipcRenderer.invoke('csound:saveConsoleLog', text),
  },

  retrieval: {
    search: (query: string, opts?: Record<string, unknown>) =>
      ipcRenderer.invoke('retrieval:search', query, opts),
    feedback: (chunkID: string, signal: string) =>
      ipcRenderer.invoke('retrieval:feedback', chunkID, signal),
  },

  graph: {
    getData: () => ipcRenderer.invoke('graph:getData'),
    getNode: (id: string) => ipcRenderer.invoke('graph:getNode', id),
    neighbors: (id: string) => ipcRenderer.invoke('graph:neighbors', id),
    ask: (question: string) => ipcRenderer.invoke('graph:ask', question),
  },

  export: {
    html: (sessionID: string, opts: Record<string, unknown>) =>
      ipcRenderer.invoke('export:html', sessionID, opts),
    openInCabbage: (content: string, title: string) =>
      ipcRenderer.invoke('export:openInCabbage', content, title),
    openInCsoundQt: (content: string, title: string) =>
      ipcRenderer.invoke('export:openInCsoundQt', content, title),
    openInBrowser: (content: string, title: string) =>
      ipcRenderer.invoke('export:openInBrowser', content, title),
    revealFile: (path: string) =>
      ipcRenderer.invoke('export:revealFile', path),
    stems: (sessionID: string) =>
      ipcRenderer.invoke('export:stems', sessionID),
    presetPack: (sessionID: string) =>
      ipcRenderer.invoke('export:presetPack', sessionID),
  },

  memory: {
    status: () => ipcRenderer.invoke('memory:status'),
    recall: (query: string) => ipcRenderer.invoke('memory:recall', query),
    save: (type: string, data: unknown) =>
      ipcRenderer.invoke('memory:save', type, data),
    getProfile: () => ipcRenderer.invoke('memory:profile'),
    feedback: (kind: string, payload?: Record<string, unknown>) =>
      ipcRenderer.invoke('memory:feedback', kind, payload ?? {}),
    lessons: () => ipcRenderer.invoke('memory:lessons'),
    deleteLesson: (id: string) => ipcRenderer.invoke('memory:deleteLesson', id),
  },

  config: {
    setApiKey: (provider: string, key: string) =>
      ipcRenderer.invoke('config:setApiKey', provider, key),
    deleteApiKey: (provider: string) =>
      ipcRenderer.invoke('config:deleteApiKey', provider),
    getApiKeys: () => ipcRenderer.invoke('config:getApiKeys'),
    testApiKey: (provider: string) =>
      ipcRenderer.invoke('config:testApiKey', provider),
    getCabbagePath: () => ipcRenderer.invoke('config:getCabbagePath'),
    setCabbagePath: (path: string) =>
      ipcRenderer.invoke('config:setCabbagePath', path),
    detectCabbage: () => ipcRenderer.invoke('config:detectCabbage'),
    chooseCabbagePath: () => ipcRenderer.invoke('config:chooseCabbagePath'),
    getCsoundQtPath: () => ipcRenderer.invoke('config:getCsoundQtPath'),
    setCsoundQtPath: (path: string) => ipcRenderer.invoke('config:setCsoundQtPath', path),
    detectCsoundQt: () => ipcRenderer.invoke('config:detectCsoundQt'),
    chooseCsoundQtPath: () => ipcRenderer.invoke('config:chooseCsoundQtPath'),
    getBrowserPath: () => ipcRenderer.invoke('config:getBrowserPath'),
    setBrowserPath: (path: string) => ipcRenderer.invoke('config:setBrowserPath', path),
    detectBrowser: () => ipcRenderer.invoke('config:detectBrowser'),
    listBrowsers: () => ipcRenderer.invoke('config:listBrowsers'),
    chooseBrowserPath: () => ipcRenderer.invoke('config:chooseBrowserPath'),
    listAudioDevices: () => ipcRenderer.invoke('config:listAudioDevices'),
    getAudioConfig: () => ipcRenderer.invoke('config:getAudioConfig'),
    setAudioDevice: (field: string, value: string) =>
      ipcRenderer.invoke('config:setAudioDevice', field, value),
    resetAudioDevices: () => ipcRenderer.invoke('config:resetAudioDevices'),
    sanitizeAudioDevices: () => ipcRenderer.invoke('config:sanitizeAudioDevices'),
    getOllama: () => ipcRenderer.invoke('config:getOllama'),
    setOllama: (patch: Record<string, unknown>) =>
      ipcRenderer.invoke('config:setOllama', patch),
    testOllama: () => ipcRenderer.invoke('config:testOllama'),
  },

  llm: {
    adaptCsd: (prompt: string) =>
      ipcRenderer.invoke('llm:adaptCsd', prompt),
  },

  workshop: {
    list: () => ipcRenderer.invoke('workshop:list'),
    listDemos: () => ipcRenderer.invoke('workshop:listDemos'),
    saveUserDemo: (payload: { title: string; content: string; id?: string }) =>
      ipcRenderer.invoke('workshop:saveUserDemo', payload),
    deleteUserDemo: (id: string) => ipcRenderer.invoke('workshop:deleteUserDemo', id),
    read: (id: string) => ipcRenderer.invoke('workshop:read', id),
    openHandout: () => ipcRenderer.invoke('workshop:openHandout'),
    revealHandout: () => ipcRenderer.invoke('workshop:revealHandout'),
  },
}

export type DrcAPI = typeof api

contextBridge.exposeInMainWorld('api', api)
