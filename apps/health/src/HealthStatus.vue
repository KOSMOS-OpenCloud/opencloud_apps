<template>
  <main class="flex app-content size-full rounded-l-xl">
    <app-loading-spinner v-if="loading && !services.length" />
    <div v-else class="admin-settings-wrapper flex w-full flex-1 h-full">
      <div class="relative grid grid-cols-1 flex-1 focus:outline-0 h-full overflow-y-auto">
        <div class="outline-0 z-0 flex flex-col">
          <div class="py-1 px-4 top-0 z-20 bg-role-surface sticky">
            <div class="flex justify-between items-center h-12">
              <oc-breadcrumb :items="breadcrumbs" />
              <oc-button
                appearance="raw"
                :aria-label="$gettext('Refresh')"
                @click="fetchHealth"
              >
                <oc-icon name="refresh" />
              </oc-button>
            </div>
          </div>

          <no-content-message v-if="!services.length" icon="heart-pulse">
            <template #message>
              <span>{{ $gettext('No health data available') }}</span>
            </template>
          </no-content-message>

          <oc-table v-else :fields="fields" :data="tableData" :sticky="true">
            <template #status="{ item }">
              <oc-icon
                :name="item.status === 'ok' ? 'checkbox-circle' : 'close-circle'"
                fill-type="fill"
                :color="item.status === 'ok' ? 'var(--oc-role-on-surface)' : 'var(--oc-role-error)'"
                size="medium"
              />
            </template>
            <template #message="{ item }">
              <span v-if="item.message" class="text-role-on-surface-variant">
                {{ item.message }}
              </span>
            </template>
          </oc-table>

          <div v-if="services.length" class="px-4 py-2">
            <template v-for="svc in services" :key="svc.name">
              <details v-if="svc.details" class="mb-2">
                <summary class="cursor-pointer text-role-on-surface-variant text-sm font-medium">
                  {{ svc.name }} — {{ $gettext('Details') }}
                </summary>
                <pre class="text-xs mt-1 p-2 bg-role-surface-variant rounded overflow-x-auto">{{ formatDetails(svc.details) }}</pre>
              </details>
            </template>
          </div>
        </div>
      </div>
    </div>
  </main>
</template>

<script setup lang="ts">
import {
  AppLoadingSpinner,
  NoContentMessage,
  useClientService,
} from '@opencloud-eu/web-pkg'
import { useGettext } from 'vue3-gettext'
import { computed, ref, onMounted, onUnmounted } from 'vue'

interface ServiceHealth {
  name: string
  status: string
  message?: string
  details?: Record<string, unknown>
}

const { $gettext } = useGettext()
const clientService = useClientService()
const http = clientService.httpAuthenticated

const loading = ref(true)
const services = ref<ServiceHealth[]>([])
let refreshTimer: ReturnType<typeof setInterval> | null = null

const breadcrumbs = computed(() => [{ text: $gettext('Health') }])

const fields = [
  { name: 'status', title: '', type: 'slot', width: '48px' },
  { name: 'name', title: $gettext('Service') },
  { name: 'message', title: $gettext('Message'), type: 'slot' },
]

const tableData = computed(() =>
  services.value.map((svc) => ({
    id: svc.name,
    name: svc.name,
    status: svc.status,
    message: svc.message || '',
  }))
)

function formatDetails(details: Record<string, unknown>): string {
  return JSON.stringify(details, null, 2)
}

async function fetchHealth() {
  try {
    const { data } = await http.get('/graph/v1.0/extensions/health')
    services.value = (data as { services: ServiceHealth[] }).services || []
  } catch (e) {
    services.value = [
      { name: 'api', status: 'error', message: String(e) },
    ]
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchHealth()
  refreshTimer = setInterval(fetchHealth, 30000)
})

onUnmounted(() => {
  if (refreshTimer) clearInterval(refreshTimer)
})
</script>

