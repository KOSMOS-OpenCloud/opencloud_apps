<template>
  <main class="posteingang">
    <div v-if="!space" class="posteingang-empty">
      <template v-if="loadingList">Lade...</template>
      <template v-else>Space "{{ config.spaceName }}" nicht gefunden</template>
    </div>
    <div v-else class="posteingang-layout">
      <!-- Left: Document list -->
      <aside class="posteingang-panel posteingang-list">
        <h2 class="posteingang-panel-title">Dokumente</h2>
        <DocumentList
          :documents="documents"
          :selected="selectedDoc"
          :loading="loadingList"
          @select="onSelectDocument"
        />
      </aside>

      <!-- Middle: PDF preview -->
      <section class="posteingang-panel posteingang-preview">
        <PdfPreview
          v-if="selectedDoc"
          :url="pdfUrl"
          :loading="loadingPdf"
        />
        <div v-else class="posteingang-empty">
          Dokument auswaehlen
        </div>
      </section>

      <!-- Right: Actions + Metadata -->
      <aside class="posteingang-panel posteingang-actions">
        <AssignPanel
          :target-folders="config.targetFolders"
          :selected-target="selectedTarget"
          :assigning="assigning"
          @select-target="selectedTarget = $event"
          @assign="onAssign"
        />
        <MetadataPanel
          v-if="selectedDoc && selectedDoc.resource.extraProps"
          :schema="metaSchema"
          :values="selectedDoc.resource.extraProps"
        />
      </aside>
    </div>
  </main>
</template>

<script lang="ts">
import { defineComponent, ref, computed, onMounted } from 'vue'
import { useClientService, useSpacesStore, useUserStore, useMessages } from '@opencloud-eu/web-pkg'
import { SpaceResource } from '@opencloud-eu/web-client'
import DocumentList from './components/DocumentList.vue'
import PdfPreview from './components/PdfPreview.vue'
import AssignPanel from './components/AssignPanel.vue'
import MetadataPanel from './components/MetadataPanel.vue'
import { PosteingangConfig, DocumentEntry, JsonSchema, DEFAULT_CONFIG } from './types'

export default defineComponent({
  name: 'Posteingang',
  components: { DocumentList, PdfPreview, AssignPanel, MetadataPanel },
  setup() {
    const clientService = useClientService()
    const spacesStore = useSpacesStore()
    const userStore = useUserStore()
    const { showMessage, showErrorMessage } = useMessages()

    const config = ref<PosteingangConfig>({ ...DEFAULT_CONFIG })
    const metaSchema = ref<JsonSchema | null>(null)
    const documents = ref<DocumentEntry[]>([])
    const selectedDoc = ref<DocumentEntry | null>(null)
    const selectedTarget = ref<string>('')
    const loadingList = ref(false)
    const loadingPdf = ref(false)
    const assigning = ref(false)
    const pdfUrl = ref('')

    const space = computed<SpaceResource | undefined>(() => {
      return spacesStore.spaces.find(
        (s: SpaceResource) => s.driveType === 'project' && s.name === config.value.spaceName
      )
    })

    function getUsername(): string {
      return userStore.user?.onPremisesSamAccountName
        || userStore.user?.displayName
        || 'default'
    }

    function readText(body: any): string {
      return typeof body === 'string'
        ? body
        : new TextDecoder().decode(body as ArrayBuffer)
    }

    async function loadConfig() {
      if (!space.value) return
      const username = getUsername()

      for (const name of [`${username}.conf`, 'default.conf']) {
        try {
          const response = await clientService.webdav.getFileContents(space.value, {
            path: `/.inbox/${name}`
          })
          config.value = { ...DEFAULT_CONFIG, ...JSON.parse(readText(response.body)) }
          break
        } catch {
          // try next
        }
      }
    }

    /** Load .inbox/meta.json — open_taki docmeta_schema.json format */
    async function loadMetaSchema() {
      if (!space.value) return
      try {
        const response = await clientService.webdav.getFileContents(space.value, {
          path: '/.inbox/meta.json'
        })
        metaSchema.value = JSON.parse(readText(response.body)) as JsonSchema
      } catch {
        metaSchema.value = null
      }
    }

    async function loadDocuments() {
      if (!space.value) return
      loadingList.value = true
      documents.value = []

      for (const folder of config.value.sourceFolders) {
        try {
          const { resource, children } = await clientService.webdav.listFiles(
            space.value,
            { path: `/${folder}` }
          )
          if (children) {
            for (const child of children) {
              if (child.mimeType === 'application/pdf' || child.extension === 'pdf') {
                documents.value.push({ resource: child, sourceFolder: folder })
              }
            }
          }
        } catch {
          // Folder may not exist
        }
      }
      loadingList.value = false
    }

    async function loadPdfUrl(doc: DocumentEntry) {
      if (!space.value) return
      loadingPdf.value = true
      try {
        console.log('[posteingang] loadPdfUrl resource:', doc.resource.name, doc.resource.path, doc.resource.webDavPath)
        const url = await clientService.webdav.getFileUrl(space.value, doc.resource)
        console.log('[posteingang] getFileUrl result:', url)
        pdfUrl.value = url
      } catch (err) {
        console.error('[posteingang] getFileUrl error:', err)
        showErrorMessage({ title: 'PDF konnte nicht geladen werden' })
      }
      loadingPdf.value = false
    }

    function onSelectDocument(doc: DocumentEntry) {
      selectedDoc.value = doc
      selectedTarget.value = ''
      loadPdfUrl(doc)
    }

    async function onAssign() {
      if (!space.value || !selectedDoc.value || !selectedTarget.value) return
      const target = config.value.targetFolders.find(t => t.id === selectedTarget.value)
      if (!target) return

      assigning.value = true
      try {
        const sourcePath = selectedDoc.value.resource.path
        const targetPath = `/${target.path}/${selectedDoc.value.resource.name}`
        await clientService.webdav.moveFiles(
          space.value,
          { path: sourcePath },
          space.value,
          { path: targetPath }
        )

        showMessage({ title: `Zugewiesen an: ${target.label}` })
        documents.value = documents.value.filter(d => d !== selectedDoc.value)
        selectedDoc.value = null
        selectedTarget.value = ''
        if (pdfUrl.value) {
          URL.revokeObjectURL(pdfUrl.value)
          pdfUrl.value = ''
        }
      } catch {
        showErrorMessage({ title: 'Zuweisung fehlgeschlagen' })
      }
      assigning.value = false
    }

    onMounted(async () => {
      await loadConfig()
      await loadMetaSchema()
      await loadDocuments()
    })

    return {
      config,
      metaSchema,
      space,
      documents,
      selectedDoc,
      selectedTarget,
      loadingList,
      loadingPdf,
      assigning,
      pdfUrl,
      onSelectDocument,
      onAssign
    }
  }
})
</script>

<style>
.posteingang {
  position: fixed;
  inset: 0;
  top: var(--oc-topbar-height, 52px);
  overflow: hidden;
  font-family: inherit;
  z-index: 1;
}

.posteingang-layout {
  display: flex;
  height: 100%;
  gap: 1px;
  background: #e0e0e0;
}

.posteingang-panel {
  background: #fff;
  overflow: auto;
}

.posteingang-panel-title {
  font-size: 14px;
  font-weight: 600;
  padding: 12px 16px;
  margin: 0;
  border-bottom: 1px solid #e0e0e0;
  background: #fafafa;
  position: sticky;
  top: 0;
  z-index: 1;
}

.posteingang-list {
  flex: 0 0 280px;
  min-width: 200px;
}

.posteingang-preview {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
}

.posteingang-actions {
  flex: 0 0 320px;
  min-width: 260px;
  display: flex;
  flex-direction: column;
}

.posteingang-empty {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: #999;
  font-size: 14px;
}
</style>
