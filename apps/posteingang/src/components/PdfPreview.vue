<template>
  <div class="pdf-preview">
    <div v-if="loading" class="pdf-preview-loading">PDF wird geladen...</div>
    <object
      v-else-if="url"
      :data="url"
      :type="objectType"
      class="pdf-preview-object"
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
  },
  setup() {
    const isSafari =
      navigator.userAgent?.includes('Safari') && !navigator.userAgent?.includes('Chrome')
    const objectType = isSafari ? undefined : 'application/pdf'
    return { objectType }
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

.pdf-preview-object {
  flex: 1;
  width: 100%;
  height: 100%;
  overflow: hidden;
}
</style>
