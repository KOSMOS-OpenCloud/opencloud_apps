<template>
  <div class="posteingang-picker" tabindex="0">
    <div v-if="isLoading" class="posteingang-picker-loading">Lade...</div>
    <iframe
      v-show="!isLoading"
      ref="iframeRef"
      class="posteingang-picker-frame"
      title="Ablegen"
      :src="iframeSrc"
      tabindex="0"
      @load="onLoad"
    ></iframe>
  </div>
</template>

<script lang="ts">
// Nachbau von LocationPickerModal (web-pkg im kosmos-Kern): Dateiansicht im Embed-Modus,
// die Auswahl kommt per postMessage 'opencloud-embed:select'. Eigene Kopie, weil das
// web-pkg 4.3.0, gegen das die App gebaut wird, die Komponente noch nicht kennt.
import { defineComponent, PropType, ref, unref, onMounted, onBeforeUnmount } from 'vue'
import { useModals } from '@opencloud-eu/web-pkg'
import { Resource } from '@opencloud-eu/web-client'

export default defineComponent({
  name: 'LocationPicker',
  props: {
    modal: { type: Object as PropType<{ id: string }>, required: true },
    startPath: { type: String, required: true },
    submitButtonTitle: { type: String, default: '' },
    callbackFn: { type: Function as PropType<(resources: Resource[]) => void>, required: true }
  },
  setup(props) {
    const { removeModal } = useModals()
    const iframeRef = ref<HTMLIFrameElement>()
    const isLoading = ref(true)

    const iframeUrl = new URL(props.startPath, window.location.origin)
    iframeUrl.searchParams.append('hide-logo', 'true')
    iframeUrl.searchParams.append('embed', 'true')
    iframeUrl.searchParams.append('embed-target', 'location')
    iframeUrl.searchParams.append('embed-delegate-authentication', 'false')
    if (props.submitButtonTitle) {
      iframeUrl.searchParams.append('embed-submit-button-title', props.submitButtonTitle)
    }
    const iframeSrc = iframeUrl.href

    const onLoad = () => {
      isLoading.value = false
      unref(iframeRef)?.contentWindow?.focus()
    }

    const isFromOwnIframe = (event: MessageEvent): boolean => {
      const iframeWindow = unref(iframeRef)?.contentWindow
      return !!iframeWindow && event.source === iframeWindow && event.origin === window.location.origin
    }

    const onMessage = (event: MessageEvent) => {
      if (!isFromOwnIframe(event)) return
      if (event.data?.name === 'opencloud-embed:cancel') {
        removeModal(props.modal.id)
        return
      }
      if (event.data?.name !== 'opencloud-embed:select') return
      let resources = event.data.data?.resources
      if (Array.isArray(event.data.data)) {
        resources = event.data.data
      }
      if (!resources?.length) return
      props.callbackFn(resources)
      removeModal(props.modal.id)
    }

    onMounted(() => window.addEventListener('message', onMessage))
    onBeforeUnmount(() => window.removeEventListener('message', onMessage))

    return { iframeRef, isLoading, iframeSrc, onLoad }
  }
})
</script>

<style>
.posteingang-picker {
  height: 100%;
}
.posteingang-picker-frame {
  width: 100%;
  height: 100%;
  border: 0;
}
.posteingang-picker-loading {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: var(--oc-role-on-surface-variant);
}
.posteingang-picker-modal {
  overflow: hidden;
  max-width: 90vw;
}
.posteingang-picker-modal .oc-modal-body {
  padding: 0;
}
.posteingang-picker-modal .oc-modal-body-message {
  margin: 0;
  height: 70vh;
}
</style>
