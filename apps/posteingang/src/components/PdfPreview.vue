<template>
  <div class="pdf-preview">
    <div v-if="loading" class="pdf-preview-loading">PDF wird geladen...</div>
    <div v-else-if="url" class="pdf-preview-container">
      <div class="pdf-preview-toolbar">
        <button class="pdf-btn" :disabled="currentPage <= 1" @click="currentPage--">&#9664;</button>
        <span class="pdf-page-info">{{ currentPage }} / {{ totalPages }}</span>
        <button class="pdf-btn" :disabled="currentPage >= totalPages" @click="currentPage++">&#9654;</button>
        <button class="pdf-btn" @click="zoomOut">-</button>
        <span class="pdf-zoom-info">{{ Math.round(scale * 100) }}%</span>
        <button class="pdf-btn" @click="zoomIn">+</button>
      </div>
      <div class="pdf-preview-scroll" ref="scrollContainer">
        <canvas ref="canvasEl" class="pdf-preview-canvas" />
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, watch, onMounted, onBeforeUnmount, nextTick } from 'vue'
import * as pdfjsLib from 'pdfjs-dist'

// Use bundled worker
pdfjsLib.GlobalWorkerOptions.workerSrc = new URL(
  'pdfjs-dist/build/pdf.worker.min.mjs',
  import.meta.url
).toString()

export default defineComponent({
  name: 'PdfPreview',
  props: {
    url: { type: String, required: true },
    loading: { type: Boolean, default: false }
  },
  setup(props) {
    const canvasEl = ref<HTMLCanvasElement>()
    const scrollContainer = ref<HTMLDivElement>()
    const currentPage = ref(1)
    const totalPages = ref(0)
    const scale = ref(1.0)
    let pdfDoc: any = null

    async function loadPdf() {
      if (!props.url) return
      try {
        pdfDoc = await pdfjsLib.getDocument(props.url).promise
        totalPages.value = pdfDoc.numPages
        currentPage.value = 1
        await renderPage()
      } catch (err) {
        console.error('PDF load error:', err)
      }
    }

    async function renderPage() {
      if (!pdfDoc || !canvasEl.value) return
      const page = await pdfDoc.getPage(currentPage.value)
      const viewport = page.getViewport({ scale: scale.value })
      const canvas = canvasEl.value
      const ctx = canvas.getContext('2d')
      canvas.height = viewport.height
      canvas.width = viewport.width
      await page.render({ canvasContext: ctx, viewport }).promise
    }

    function zoomIn() {
      scale.value = Math.min(scale.value + 0.25, 3.0)
    }

    function zoomOut() {
      scale.value = Math.max(scale.value - 0.25, 0.5)
    }

    watch(() => props.url, () => {
      loadPdf()
    })

    watch(currentPage, () => {
      renderPage()
    })

    watch(scale, () => {
      renderPage()
    })

    onMounted(() => {
      if (props.url) loadPdf()
    })

    return {
      canvasEl,
      scrollContainer,
      currentPage,
      totalPages,
      scale,
      zoomIn,
      zoomOut
    }
  }
})
</script>

<style>
.pdf-preview {
  height: 100%;
  display: flex;
  flex-direction: column;
}

.pdf-preview-loading {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: #999;
  font-size: 14px;
}

.pdf-preview-container {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.pdf-preview-toolbar {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  background: #fafafa;
  border-bottom: 1px solid #e0e0e0;
  flex-shrink: 0;
}

.pdf-btn {
  background: #fff;
  border: 1px solid #ddd;
  border-radius: 4px;
  padding: 4px 10px;
  cursor: pointer;
  font-size: 13px;
  line-height: 1;
}

.pdf-btn:hover:not(:disabled) {
  background: #f0f0f0;
}

.pdf-btn:disabled {
  opacity: 0.4;
  cursor: default;
}

.pdf-page-info,
.pdf-zoom-info {
  font-size: 13px;
  color: #666;
  min-width: 50px;
  text-align: center;
}

.pdf-preview-scroll {
  flex: 1;
  overflow: auto;
  display: flex;
  justify-content: center;
  padding: 16px;
  background: #e8e8e8;
}

.pdf-preview-canvas {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
  background: #fff;
}
</style>
