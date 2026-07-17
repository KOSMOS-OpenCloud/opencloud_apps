<template>
  <div class="pdf-preview">
    <div v-if="loading" class="pdf-preview-loading">PDF wird geladen...</div>
    <iframe
      v-else-if="url"
      :src="url"
      class="pdf-preview-frame"
      type="application/pdf"
    />
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue'

export default defineComponent({
  name: 'PdfPreview',
  props: {
    url: { type: String, required: true },
    loading: { type: Boolean, default: false }
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

.pdf-preview-frame {
  flex: 1;
  width: 100%;
  border: none;
}
</style>
