<template>
  <main class="mermaid-editor">
    <div class="mermaid-editor-container">
      <div class="mermaid-editor-source">
        <textarea
          ref="sourceEl"
          v-model="content"
          class="mermaid-editor-textarea"
          spellcheck="false"
          :readonly="isReadOnly"
          @input="onInput"
        />
      </div>
      <div class="mermaid-editor-preview">
        <div ref="previewEl" class="mermaid-editor-render" />
      </div>
    </div>
  </main>
</template>

<script lang="ts">
import { defineComponent, ref, onMounted, watch, nextTick, PropType } from 'vue'
import { Resource } from '@opencloud-eu/web-client'
import mermaid from 'mermaid'

export default defineComponent({
  name: 'MermaidEditor',
  props: {
    resource: {
      type: Object as PropType<Resource>,
      required: true
    },
    currentContent: {
      type: String,
      required: true
    },
    isReadOnly: {
      type: Boolean,
      required: true
    },
    isDirty: {
      type: Boolean,
      required: true
    }
  },
  emits: ['update:currentContent', 'update:isDirty'],
  setup(props, { emit }) {
    const content = ref('')
    const previewEl = ref<HTMLElement>()
    let renderCounter = 0

    onMounted(async () => {
      mermaid.initialize({
        startOnLoad: false,
        theme: 'base',
        securityLevel: 'loose',
        themeVariables: {
          primaryColor: '#e3f2fd',
          primaryTextColor: '#222',
          primaryBorderColor: '#90caf9',
          lineColor: '#666',
          secondaryColor: '#f5f5f5',
          tertiaryColor: '#fff'
        }
      })

      content.value = props.currentContent || `graph TD
    A[Start] --> B{Decision}
    B -->|Yes| C[OK]
    B -->|No| D[Cancel]
`
      await renderDiagram()
    })

    async function renderDiagram() {
      if (!previewEl.value) return
      try {
        renderCounter++
        const id = `mermaid-${renderCounter}`
        const { svg } = await mermaid.render(id, content.value)
        previewEl.value.innerHTML = svg
      } catch {
        previewEl.value.innerHTML = '<p style="color: #c62828; padding: 1rem;">Syntax error in diagram</p>'
      }
    }

    function onInput() {
      emit('update:currentContent', content.value)
      emit('update:isDirty', true)
    }

    watch(content, async () => {
      await nextTick()
      await renderDiagram()
    })

    watch(() => props.currentContent, (val) => {
      if (val !== content.value) {
        content.value = val
      }
    })

    return { content, previewEl, onInput }
  }
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
