<template>
  <main class="mermaid-editor">
    <div class="mermaid-editor-container">
      <div class="mermaid-editor-source">
        <textarea
          ref="sourceEl"
          v-model="source"
          class="mermaid-editor-textarea"
          spellcheck="false"
          @input="onInput"
        />
      </div>
      <div class="mermaid-editor-preview">
        <div ref="previewEl" class="mermaid-editor-render" />
      </div>
    </div>
  </main>
</template>

<script setup lang="ts">
import { ref, onMounted, watch, nextTick } from 'vue'
import { useAppDefaults } from '@opencloud-eu/web-pkg'
import mermaid from 'mermaid'

const { currentFileContext, getFileContents, putFileContents } = useAppDefaults({ applicationId: 'mermaid-editor' })

const source = ref('')
const previewEl = ref<HTMLElement>()
const sourceEl = ref<HTMLTextAreaElement>()
let saveTimeout: ReturnType<typeof setTimeout> | null = null
let renderCounter = 0

const defaultContent = `graph TD
    A[Start] --> B{Decision}
    B -->|Yes| C[OK]
    B -->|No| D[Cancel]
`

onMounted(async () => {
  mermaid.initialize({
    startOnLoad: false,
    theme: 'default',
    securityLevel: 'loose'
  })

  if (currentFileContext.value?.path) {
    try {
      const response = await getFileContents(currentFileContext.value)
      source.value = typeof response === 'string' ? response : (response as any).body || ''
    } catch {
      source.value = defaultContent
    }
  } else {
    source.value = defaultContent
  }

  await renderDiagram()
})

async function renderDiagram() {
  if (!previewEl.value) return

  try {
    renderCounter++
    const id = `mermaid-render-${renderCounter}`
    const { svg } = await mermaid.render(id, source.value)
    previewEl.value.innerHTML = svg
  } catch {
    previewEl.value.innerHTML = '<p style="color: #c62828; padding: 1rem;">Syntax error in diagram</p>'
  }
}

function onInput() {
  if (saveTimeout) clearTimeout(saveTimeout)
  saveTimeout = setTimeout(save, 1500)
}

async function save() {
  if (!currentFileContext.value?.path) return
  try {
    await putFileContents(currentFileContext.value, source.value)
  } catch (e) {
    console.error('[mermaid-editor] save failed:', e)
  }
}

watch(source, async () => {
  await nextTick()
  await renderDiagram()
})
</script>

<style>
.mermaid-editor {
  width: 100%;
  height: 100%;
  overflow: hidden;
}

.mermaid-editor-container {
  display: flex;
  height: 100%;
  gap: 4px;
}

.mermaid-editor-source {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
}

.mermaid-editor-textarea {
  width: 100%;
  height: 100%;
  resize: none;
  border: 1px solid #e0e0e0;
  padding: 1rem;
  font-family: 'Fira Code', 'Consolas', monospace;
  font-size: 14px;
  line-height: 1.5;
  outline: none;
  background: #fafafa;
}

.mermaid-editor-textarea:focus {
  border-color: #1976d2;
}

.mermaid-editor-preview {
  flex: 1;
  min-width: 0;
  overflow: auto;
  border: 1px solid #e0e0e0;
  background: white;
}

.mermaid-editor-render {
  padding: 1rem;
  display: flex;
  justify-content: center;
  align-items: flex-start;
  min-height: 100%;
}

.mermaid-editor-render svg {
  max-width: 100%;
}
</style>
