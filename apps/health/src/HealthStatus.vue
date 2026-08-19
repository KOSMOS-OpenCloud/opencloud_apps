<template>
  <main class="flex app-content size-full rounded-l-xl">
    <app-loading-spinner v-if="loading && !rows.length" />
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

          <no-content-message v-if="!rows.length && !loading" icon="heart-pulse">
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
            <template #service="{ item }">
              <span v-if="item.service" class="font-medium">{{ item.service }}</span>
            </template>
            <template #endpoint="{ item }">
              <span class="text-role-on-surface-variant text-sm">{{ item.endpoint }}</span>
            </template>
            <template #info="{ item }">
              <span class="text-role-on-surface-variant text-sm">{{ item.info }}</span>
            </template>
          </oc-table>

          <div v-if="hasDetails" class="px-4 py-2">
            <template v-for="row in rows" :key="row.id">
              <details v-if="row.details" class="mb-2">
                <summary class="cursor-pointer text-role-on-surface-variant text-sm font-medium">
                  {{ row.service || '' }} {{ row.endpoint }} — {{ $gettext('Raw JSON') }}
                </summary>
                <pre class="health-details">{{ formatJson(row.details) }}</pre>
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
import { computed, ref, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'

interface CheckConfig {
  url: string
  label: string
  extract?: string
  suffix?: string
}

interface ServiceConfig {
  name: string
  checks: CheckConfig[]
}

interface RowResult {
  id: string
  service: string
  endpoint: string
  status: 'ok' | 'warn' | 'error' | 'pending'
  info: string
  details?: Record<string, unknown>
}

const { $gettext } = useGettext()
const route = useRoute()

const loading = ref(true)
const rows = ref<RowResult[]>([])
let refreshTimer: ReturnType<typeof setInterval> | null = null

const breadcrumbs = computed(() => [{ text: $gettext('Health') }])

const fields = [
  { name: 'status', title: '', type: 'slot', width: '48px' },
  { name: 'service', title: $gettext('Service'), type: 'slot', width: '140px' },
  { name: 'endpoint', title: $gettext('Endpoint'), type: 'slot', width: '180px' },
  { name: 'info', title: $gettext('Info'), type: 'slot' },
]

const tableData = computed(() =>
  rows.value.map((r) => ({
    id: r.id,
    service: r.service,
    endpoint: r.endpoint,
    status: r.status,
    info: r.info,
  }))
)

const hasDetails = computed(() => rows.value.some((r) => r.details))

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

function formatJson(data: Record<string, unknown>): string {
  return JSON.stringify(data, null, 2)
}

function getDefaultServices(): ServiceConfig[] {
  return [
    { name: 'OpenCloud', checks: [{ url: '/graph/v1.0/me', label: '/graph/v1.0/me', extract: 'displayName' }] },
    { name: 'microllm', checks: [{ url: '/ai-chat/health', label: '/health', extract: 'status' }] },
  ]
}

function getServices(): ServiceConfig[] {
  const meta = route.meta?.healthConfig as Record<string, unknown> | undefined
  const svcs = meta?.services as ServiceConfig[] | undefined
  if (Array.isArray(svcs) && svcs.length > 0) return svcs
  return getDefaultServices()
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
  return String(current)
}

function buildInfo(data: unknown, check: CheckConfig): string {
  // Explicit extract path
  if (check.extract) {
    const val = extractValue(data, check.extract)
    if (val) {
      return check.suffix ? `${val} ${check.suffix}` : `${check.extract}: ${val}`
    }
  }
  // Auto-extract interesting fields from flat object
  if (data && typeof data === 'object' && !Array.isArray(data)) {
    const obj = data as Record<string, unknown>
    const parts: string[] = []
    // Common health fields
    for (const key of ['status', 'version', 'title']) {
      if (key in obj && (typeof obj[key] === 'string' || typeof obj[key] === 'number')) {
        parts.push(`${key}: ${obj[key]}`)
      }
    }
    // Numeric counters
    for (const key of ['points_count', 'vectors_count', 'doc_count', 'pending', 'segments_count']) {
      if (key in obj && typeof obj[key] === 'number') {
        parts.push(`${key}: ${obj[key]}`)
      }
    }
    // Nested result (qdrant style)
    if ('result' in obj && typeof obj.result === 'object' && obj.result) {
      const r = obj.result as Record<string, unknown>
      for (const key of ['status', 'points_count', 'vectors_count', 'segments_count']) {
        if (key in r && r[key] != null) {
          parts.push(`${key}: ${r[key]}`)
        }
      }
    }
    // Nested queue (taki style)
    if ('queue' in obj && typeof obj.queue === 'object' && obj.queue) {
      const q = obj.queue as Record<string, unknown>
      const inflight = q.in_flight ?? q.pending ?? ''
      const max = q.max ?? ''
      if (inflight !== '' && max !== '') parts.push(`queue: ${inflight}/${max}`)
    }
    // Subsystems (taki style)
    if ('subsystems' in obj && typeof obj.subsystems === 'object' && obj.subsystems) {
      const ss = obj.subsystems as Record<string, Record<string, unknown>>
      const ssParts: string[] = []
      for (const [k, v] of Object.entries(ss)) {
        if (v && typeof v === 'object' && 'status' in v) {
          ssParts.push(`${k}: ${v.status}`)
        }
      }
      if (ssParts.length) parts.push(ssParts.join(' · '))
    }
    // Stats style (request counts)
    for (const key of ['total_requests', 'total_errors', 'avg_latency_ms']) {
      if (key in obj && typeof obj[key] === 'number') {
        parts.push(`${key}: ${obj[key]}`)
      }
    }
    if (parts.length) return parts.join(' · ')
  }
  return ''
}

function getAccessToken(): string {
  // OpenCloud stores the token in the oidc user object
  for (const key of Object.keys(sessionStorage)) {
    if (key.startsWith('oidc.user:')) {
      try {
        const user = JSON.parse(sessionStorage.getItem(key) || '{}')
        if (user.access_token) return user.access_token
      } catch { /* ignore */ }
    }
  }
  return ''
}

async function runCheck(svcName: string, check: CheckConfig, isFirstCheck: boolean): Promise<RowResult> {
  const result: RowResult = {
    id: `${svcName}-${check.label}`,
    service: isFirstCheck ? svcName : '',
    endpoint: check.label,
    status: 'pending',
    info: '',
  }
  try {
    const url = `${window.location.origin}${check.url}`
    const token = getAccessToken()
    const headers: Record<string, string> = {}
    if (token) headers['Authorization'] = `Bearer ${token}`

    const res = await fetch(url, {
      headers,
      credentials: 'omit',
      signal: AbortSignal.timeout(10000),
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
      result.info = buildInfo(data, check)
      result.details = data as Record<string, unknown>
    } else {
      const text = await res.text()
      result.status = 'ok'
      result.info = text.trim().slice(0, 80) || 'OK'
    }
  } catch (e) {
    result.status = 'error'
    result.info = e instanceof Error ? e.message : String(e)
  }
  return result
}

async function runAllChecks() {
  const services = getServices()
  // Build placeholder rows
  const placeholders: RowResult[] = []
  for (const svc of services) {
    for (let i = 0; i < svc.checks.length; i++) {
      placeholders.push({
        id: `${svc.name}-${svc.checks[i].label}`,
        service: i === 0 ? svc.name : '',
        endpoint: svc.checks[i].label,
        status: 'pending',
        info: '',
      })
    }
  }
  rows.value = placeholders

  // Run all checks in parallel
  const allChecks: Promise<RowResult>[] = []
  for (const svc of services) {
    for (let i = 0; i < svc.checks.length; i++) {
      allChecks.push(runCheck(svc.name, svc.checks[i], i === 0))
    }
  }
  const results = await Promise.allSettled(allChecks)
  rows.value = results.map((r, idx) =>
    r.status === 'fulfilled' ? r.value : { ...placeholders[idx], status: 'error' as const, info: 'check failed' }
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
