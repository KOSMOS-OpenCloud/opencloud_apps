<template>
  <main class="flex app-content size-full rounded-l-xl">
    <app-loading-spinner v-if="loading && !checks.length" />
    <div v-else class="admin-settings-wrapper flex w-full flex-1 h-full">
      <div class="relative grid grid-cols-1 flex-1 focus:outline-0 h-full overflow-y-auto">
        <div class="outline-0 z-0 flex flex-col">
          <div class="py-1 px-4 top-0 z-20 bg-role-surface sticky">
            <div class="flex justify-between items-center h-12">
              <oc-breadcrumb :items="breadcrumbs" />
              <oc-button
                appearance="raw"
                :aria-label="$gettext('Refresh')"
                @click="runAllChecks"
              >
                <oc-icon name="refresh" />
              </oc-button>
            </div>
          </div>

          <no-content-message v-if="!checks.length" icon="heart-pulse">
            <template #message>
              <span>{{ $gettext('No health checks configured') }}</span>
            </template>
          </no-content-message>

          <oc-table v-else :fields="fields" :data="tableData" :sticky="true">
            <template #status="{ item }">
              <oc-icon
                :name="statusIcon(item.status)"
                fill-type="fill"
                :color="statusColor(item.status)"
                size="medium"
              />
            </template>
            <template #info="{ item }">
              <span class="text-role-on-surface-variant text-sm">{{ item.info }}</span>
            </template>
          </oc-table>

          <div v-if="hasDetails" class="px-4 py-2">
            <template v-for="check in checks" :key="check.name">
              <details v-if="check.details" class="mb-2">
                <summary class="cursor-pointer text-role-on-surface-variant text-sm font-medium">
                  {{ check.name }} — {{ $gettext('Details') }}
                </summary>
                <pre class="health-details">{{ formatDetails(check.details) }}</pre>
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
} from '@opencloud-eu/web-pkg'
import { useGettext } from 'vue3-gettext'
import { computed, ref, onMounted, onUnmounted, inject } from 'vue'

interface CheckResult {
  name: string
  status: 'ok' | 'warn' | 'error' | 'pending'
  info: string
  details?: Record<string, unknown>
}

interface CheckConfig {
  name: string
  url: string
  extract?: string
}

const { $gettext } = useGettext()
const applicationConfig = inject<Record<string, unknown>>('applicationConfig', {})

const loading = ref(true)
const checks = ref<CheckResult[]>([])
let refreshTimer: ReturnType<typeof setInterval> | null = null

const breadcrumbs = computed(() => [{ text: $gettext('Health') }])

const fields = [
  { name: 'status', title: '', type: 'slot', width: '48px' },
  { name: 'name', title: $gettext('Service') },
  { name: 'info', title: $gettext('Info'), type: 'slot' },
]

const tableData = computed(() =>
  checks.value.map((c) => ({
    id: c.name,
    name: c.name,
    status: c.status,
    info: c.info,
  }))
)

const hasDetails = computed(() => checks.value.some((c) => c.details))

function statusIcon(status: string): string {
  if (status === 'ok') return 'checkbox-circle'
  if (status === 'warn') return 'error-warning'
  if (status === 'pending') return 'time'
  return 'close-circle'
}

function statusColor(status: string): string {
  if (status === 'ok') return 'var(--oc-role-on-surface)'
  if (status === 'warn') return 'var(--oc-role-warning, orange)'
  if (status === 'pending') return 'var(--oc-role-on-surface-variant)'
  return 'var(--oc-role-error)'
}

function formatDetails(details: Record<string, unknown>): string {
  return JSON.stringify(details, null, 2)
}

function getDefaultChecks(): CheckConfig[] {
  return [
    { name: 'OpenCloud', url: '/graph/v1.0/me', extract: 'displayName' },
    { name: 'microllm', url: '/ai-chat/health', extract: 'status' },
    { name: 'Taki', url: '/ai-chat/v1/models', extract: 'data.length' },
  ]
}

function getConfiguredChecks(): CheckConfig[] {
  const cfg = applicationConfig?.checks as CheckConfig[] | undefined
  return Array.isArray(cfg) ? cfg : getDefaultChecks()
}

function extractValue(data: unknown, path: string): string {
  const parts = path.split('.')
  let current: unknown = data
  for (const part of parts) {
    if (current == null || typeof current !== 'object') return ''
    if (part === 'length' && Array.isArray(current)) return String(current.length)
    current = (current as Record<string, unknown>)[part]
  }
  if (current == null) return ''
  if (typeof current === 'number' || typeof current === 'string' || typeof current === 'boolean') {
    return String(current)
  }
  return ''
}

function buildInfoString(data: unknown, extractPath?: string): string {
  if (extractPath) {
    const val = extractValue(data, extractPath)
    if (val) return `${extractPath}: ${val}`
  }
  if (data && typeof data === 'object' && !Array.isArray(data)) {
    const obj = data as Record<string, unknown>
    // Auto-extract common health fields
    const interesting: string[] = []
    for (const key of ['status', 'version', 'points_count', 'doc_count', 'pending', 'uptime']) {
      if (key in obj) {
        const v = obj[key]
        if (typeof v === 'string' || typeof v === 'number' || typeof v === 'boolean') {
          interesting.push(`${key}: ${v}`)
        }
      }
    }
    if (interesting.length) return interesting.join(' · ')
  }
  return ''
}

async function runCheck(cfg: CheckConfig): Promise<CheckResult> {
  const result: CheckResult = { name: cfg.name, status: 'pending', info: '' }
  try {
    const isAbsolute = cfg.url.startsWith('http')
    const url = isAbsolute ? cfg.url : `${window.location.origin}${cfg.url}`
    const headers: Record<string, string> = {}
    if (!isAbsolute) {
      // Use the stored access token for same-origin requests
      const token = sessionStorage.getItem('oc_accessToken') || localStorage.getItem('oc_accessToken')
      if (token) headers['Authorization'] = `Bearer ${token}`
    }
    const res = await fetch(url, {
      headers,
      signal: AbortSignal.timeout(10000),
      credentials: isAbsolute ? 'omit' : 'same-origin',
    })
    if (!res.ok) {
      result.status = 'error'
      result.info = `HTTP ${res.status}`
      return result
    }
    const contentType = res.headers.get('content-type') || ''
    if (contentType.includes('json')) {
      const data = await res.json()
      result.status = 'ok'
      result.info = buildInfoString(data, cfg.extract)
      result.details = data as Record<string, unknown>
    } else {
      result.status = 'ok'
      result.info = `${res.status} OK`
    }
  } catch (e) {
    result.status = 'error'
    result.info = e instanceof Error ? e.message : String(e)
  }
  return result
}

async function runAllChecks() {
  const configs = getConfiguredChecks()
  checks.value = configs.map((c) => ({ name: c.name, status: 'pending', info: '' }))
  const results = await Promise.allSettled(configs.map(runCheck))
  checks.value = results.map((r, i) =>
    r.status === 'fulfilled' ? r.value : { name: configs[i].name, status: 'error' as const, info: 'check failed' }
  )
  loading.value = false
}

onMounted(() => {
  runAllChecks()
  refreshTimer = setInterval(runAllChecks, 30000)
})

onUnmounted(() => {
  if (refreshTimer) clearInterval(refreshTimer)
})
</script>

<style scoped>
.health-details {
  font-size: 0.75rem;
  margin-top: 0.25rem;
  padding: 0.5rem;
  border-radius: 0.25rem;
  overflow-x: auto;
  white-space: pre-wrap;
  word-break: break-word;
  background: var(--oc-role-surface-container, var(--oc-color-background-muted, #f4f4f4));
  color: var(--oc-role-on-surface, inherit);
  border: 1px solid var(--oc-role-outline-variant, var(--oc-color-input-border, #ccc));
}
</style>
