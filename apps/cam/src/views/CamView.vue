<template>
  <main class="ext:flex ext:flex-col ext:size-full ext:items-center ext:gap-4 ext:p-4">
    <div class="ext:flex ext:items-center ext:gap-3 ext:w-full ext:max-w-3xl">
      <oc-icon name="camera" size="medium" />
      <h1 class="ext:m-0 ext:text-lg ext:font-semibold ext:flex-1">{{ $gettext('Kamera') }}</h1>
      <span class="ext:text-sm ext:text-role-on-surface-variant ext:font-mono">{{ targetFolder }}</span>
    </div>

    <div v-if="error" class="ext:w-full ext:max-w-3xl ext:p-3 ext:rounded-sm ext:bg-role-error-container ext:text-role-on-error-container">
      {{ error }}
    </div>

    <!-- Sucher: Video der Kamera; Canvas nur für die Aufnahme -->
    <div class="ext:relative ext:w-full ext:max-w-3xl ext:aspect-video ext:bg-role-surface-container-highest ext:rounded-lg ext:overflow-hidden">
      <video ref="videoRef" autoplay playsinline muted class="ext:size-full ext:object-cover" :class="{ 'ext:scale-x-[-1]': facingMode === 'user' }" />
      <div v-if="flash" class="ext:absolute ext:inset-0 ext:bg-role-on-surface ext:opacity-70" />
      <canvas ref="canvasRef" class="ext:hidden" />
    </div>

    <div class="ext:flex ext:items-center ext:gap-6">
      <oc-button appearance="raw" :aria-label="$gettext('Kamera wechseln')" v-oc-tooltip="$gettext('Kamera wechseln')" :disabled="!stream" @click="flip">
        <oc-icon name="camera-switch" size="large" fill-type="line" />
      </oc-button>
      <oc-button appearance="filled" variation="primary" class="ext:rounded-full ext:size-16 ext:justify-center" :aria-label="$gettext('Foto aufnehmen')" :disabled="!stream || saving" @click="shoot">
        <oc-icon name="camera-lens" size="large" fill-type="fill" />
      </oc-button>
      <oc-button appearance="raw" :aria-label="$gettext('Ordner öffnen')" v-oc-tooltip="$gettext('Ordner öffnen')" :disabled="!photos.length" @click="openFolder">
        <oc-icon name="folder-image" size="large" fill-type="line" />
      </oc-button>
    </div>

    <p class="ext:m-0 ext:text-sm ext:text-role-on-surface-variant">
      <span v-if="saving">{{ $gettext('Speichern …') }}</span>
      <span v-else-if="photos.length">{{ $ngettext('%{n} Foto gespeichert', '%{n} Fotos gespeichert', photos.length, { n: String(photos.length) }) }}</span>
      <span v-else>{{ $gettext('Fotos landen in Persönlich unter Fotos/Jahr/Monat.') }}</span>
    </p>

    <!-- Aufgenommene Fotos dieser Sitzung -->
    <ul v-if="photos.length" class="ext:flex ext:flex-wrap ext:gap-2 ext:m-0 ext:p-0 ext:list-none ext:w-full ext:max-w-3xl">
      <li v-for="photo in photos" :key="photo.name" class="ext:w-24">
        <img :src="photo.url" :alt="photo.name" class="ext:w-24 ext:h-16 ext:object-cover ext:rounded-sm" />
        <span class="ext:block ext:text-xs ext:truncate ext:text-role-on-surface-variant" :title="photo.name">{{ photo.name }}</span>
      </li>
    </ul>
  </main>
</template>

<script lang="ts">
import { computed, defineComponent, onBeforeUnmount, onMounted, ref } from 'vue'
import { useGettext } from 'vue3-gettext'
import {
  createFileRouteOptions,
  useClientService,
  useMessages,
  useRouter,
  useSpacesStore
} from '@opencloud-eu/web-pkg'

interface Photo {
  name: string
  url: string
}

const pad = (value: number) => String(value).padStart(2, '0')

export default defineComponent({
  name: 'CamView',
  setup() {
    const { $gettext, $ngettext } = useGettext()
    const clientService = useClientService()
    const spacesStore = useSpacesStore()
    const router = useRouter()
    const { showErrorMessage } = useMessages()

    const videoRef = ref<HTMLVideoElement | null>(null)
    const canvasRef = ref<HTMLCanvasElement | null>(null)
    const stream = ref<MediaStream | null>(null)
    const facingMode = ref<'user' | 'environment'>('environment')
    const error = ref('')
    const saving = ref(false)
    const flash = ref(false)
    const photos = ref<Photo[]>([])

    // Zielordner: Personal/Fotos/<Jahr>/<Monat> zum Zeitpunkt der Aufnahme
    const folderFor = (date: Date) => `Fotos/${date.getFullYear()}/${pad(date.getMonth() + 1)}`
    const targetFolder = computed(() => folderFor(new Date()))

    const stop = () => {
      stream.value?.getTracks().forEach((track) => track.stop())
      stream.value = null
    }

    const start = async () => {
      stop()
      error.value = ''
      try {
        stream.value = await navigator.mediaDevices.getUserMedia({
          video: { facingMode: facingMode.value, width: { ideal: 1920 }, height: { ideal: 1080 } },
          audio: false
        })
        if (videoRef.value) {
          videoRef.value.srcObject = stream.value
        }
      } catch (e) {
        error.value = $gettext('Kamera nicht verfügbar: %{reason}', { reason: (e as Error).message })
      }
    }

    const flip = () => {
      facingMode.value = facingMode.value === 'user' ? 'environment' : 'user'
      void start()
    }

    // Ordnerkette anlegen; 405 = gibt es schon
    const ensureFolder = async (space: any, path: string) => {
      const parts = path.split('/')
      for (let i = 1; i <= parts.length; i++) {
        const partial = parts.slice(0, i).join('/')
        try {
          await clientService.webdav.createFolder(space, { path: partial, fetchFolder: false })
        } catch (e) {
          const status = (e as { statusCode?: number })?.statusCode
          if (status !== 405 && status !== 409) {
            throw e
          }
        }
      }
    }

    const shoot = async () => {
      const video = videoRef.value
      const canvas = canvasRef.value
      const space = spacesStore.personalSpace
      if (!video || !canvas || !stream.value) return
      if (!space) {
        showErrorMessage({ title: $gettext('Kein persönlicher Speicherbereich') })
        return
      }
      canvas.width = video.videoWidth
      canvas.height = video.videoHeight
      const context = canvas.getContext('2d')
      if (!context) return
      if (facingMode.value === 'user') {
        // Spiegelung des Suchers nicht ins Foto übernehmen
        context.translate(canvas.width, 0)
        context.scale(-1, 1)
      }
      context.drawImage(video, 0, 0, canvas.width, canvas.height)
      context.setTransform(1, 0, 0, 1, 0, 0)
      flash.value = true
      window.setTimeout(() => (flash.value = false), 120)

      const blob: Blob | null = await new Promise((resolve) => canvas.toBlob(resolve, 'image/jpeg', 0.92))
      if (!blob) return
      const now = new Date()
      const folder = folderFor(now)
      const name = `IMG_${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}_${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}.jpg`
      saving.value = true
      try {
        await ensureFolder(space, folder)
        await clientService.webdav.putFileContents(space, {
          path: `${folder}/${name}`,
          content: await blob.arrayBuffer()
        })
        photos.value.unshift({ name: `${folder}/${name}`, url: URL.createObjectURL(blob) })
      } catch (e) {
        showErrorMessage({ title: $gettext('Foto konnte nicht gespeichert werden'), errors: [e as Error] })
      } finally {
        saving.value = false
      }
    }

    const openFolder = () => {
      const space = spacesStore.personalSpace
      if (!space) return
      const routeOptions = createFileRouteOptions(space, { path: folderFor(new Date()) })
      router.push({ name: 'files-spaces-generic', ...routeOptions })
    }

    onMounted(start)
    onBeforeUnmount(() => {
      stop()
      photos.value.forEach((photo) => URL.revokeObjectURL(photo.url))
    })

    return { $gettext, $ngettext, videoRef, canvasRef, stream, facingMode, error, saving, flash, photos, targetFolder, flip, shoot, openFolder }
  }
})
</script>
