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
  useAuthStore,
} from '@opencloud-eu/web-pkg'
import { useGettext } from 'vue3-gettext'
import { computed, ref, onMounted, onUnmounted } from 'vue'

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
const authStore = useAuthStore()

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
  const cfg = (window as any).__healthConfig as Record<string, unknown> | undefined
  const svcs = cfg?.services as ServiceConfig[] | undefined
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

// --- Taki: expand subsystems + backends into extra rows ---
function expandTaki(data: Record<string, unknown>): RowResult[] {
  const extra: RowResult[] = []
  const subsystems = data.subsystems as Array<Record<string, unknown>> | undefined
  if (Array.isArray(subsystems)) {
    for (const ss of subsystems) {
      extra.push({
        id: `Taki-ss-${ss.name}`,
        service: '',
        endpoint: String(ss.name || ''),
        status: ss.status === 'ok' ? 'ok' : 'error',
        info: `${ss.detail || ''}${ss.latency ? ' · ' + ss.latency : ''}`,
      })
    }
  }
  const backends = data.backends as Record<string, Record<string, unknown>> | undefined
  if (backends) {
    for (const [model, info] of Object.entries(backends)) {
      const bklist = info.backends as Array<Record<string, unknown>> | undefined
      const healthy = bklist?.filter((b) => b.healthy).length ?? 0
      const total = bklist?.length ?? 0
      extra.push({
        id: `Taki-bk-${model}`,
        service: '',
        endpoint: model,
        status: healthy === total ? 'ok' : healthy > 0 ? 'warn' : 'error',
        info: `${healthy}/${total} backends · ${info.requests ?? 0} req · ${info.errors ?? 0} err`,
      })
    }
  }
  return extra
}

// --- Search: expand index + enrich queues into extra rows ---
function expandSearch(data: Record<string, unknown>): RowResult[] {
  const extra: RowResult[] = []
  const iq = data.index_queue as Record<string, unknown> | undefined
  if (iq) {
    extra.push({
      id: 'Search-index-queue',
      service: '',
      endpoint: 'index queue',
      status: 'ok',
      info: `pending: ${iq.pending ?? 0} / ${iq.max ?? '?'} · processed: ${iq.processed ?? 0}`,
    })
  }
  const eq = data.enrich_queue as Record<string, unknown> | undefined
  if (eq) {
    const pending = Number(eq.pending ?? 0)
    extra.push({
      id: 'Search-enrich-queue',
      service: '',
      endpoint: 'enrich queue',
      status: pending > 100 ? 'warn' : 'ok',
      info: `pending: ${pending} / ${eq.max ?? '?'} · processed: ${eq.processed ?? 0}`,
    })
  }
  if (data.merger && typeof data.merger === 'object') {
    const m = data.merger as Record<string, unknown>
    extra.push({
      id: 'Search-merger',
      service: '',
      endpoint: 'merger',
      status: m.alive ? 'ok' : 'error',
      info: m.alive ? 'alive' : 'dead',
    })
  }
  return extra
}

// --- Aggregator: expand services[] (GET /graph/v1.0/extensions/health) into rows ---
function expandAggregator(data: Record<string, unknown>): RowResult[] {
  const extra: RowResult[] = []
  const services = data.services as Array<Record<string, unknown>> | undefined
  if (!Array.isArray(services)) return extra
  for (const s of services) {
    const name = String(s.name || '')
    const details = s.details as Record<string, unknown> | undefined
    let info = s.message ? String(s.message) : ''
    if (!info && details) {
      const parts: string[] = []
      for (const key of ['doc_count', 'points_count', 'segments_count']) {
        if (typeof details[key] === 'number') parts.push(`${key}: ${details[key]}`)
      }
      const iq = details.index_queue as Record<string, unknown> | undefined
      if (iq) parts.push(`index_queue: ${iq.pending ?? 0} pending`)
      if (parts.length) info = parts.join(' · ')
    }
    extra.push({
      id: `aggr-${name}`,
      service: '',
      endpoint: name,
      status: s.status === 'ok' ? 'ok' : 'error',
      info,
      details: details,
    })
  }
  return extra
}

function buildInfo(data: unknown, check: CheckConfig): string {
  if (check.extract) {
    const val = extractValue(data, check.extract)
    if (val) {
      return check.suffix ? `${val} ${check.suffix}` : `${check.extract}: ${val}`
    }
  }
  if (data && typeof data === 'object' && !Array.isArray(data)) {
    const obj = data as Record<string, unknown>
    const parts: string[] = []
    for (const key of ['status', 'version']) {
      if (key in obj && (typeof obj[key] === 'string' || typeof obj[key] === 'number')) {
        parts.push(`${key}: ${obj[key]}`)
      }
    }
    for (const key of ['doc_count', 'points_count', 'segments_count']) {
      if (key in obj && typeof obj[key] === 'number') {
        parts.push(`${key}: ${obj[key]}`)
      }
    }
    if ('result' in obj && typeof obj.result === 'object' && obj.result) {
      const r = obj.result as Record<string, unknown>
      for (const key of ['status', 'points_count', 'segments_count']) {
        if (key in r && r[key] != null) parts.push(`${key}: ${r[key]}`)
      }
    }
    if ('queue' in obj && typeof obj.queue === 'object' && obj.queue) {
      const q = obj.queue as Record<string, unknown>
      const inflight = q.in_flight ?? q.pending ?? ''
      const max = q.max ?? ''
      if (inflight !== '' && max !== '') parts.push(`queue: ${inflight}/${max}`)
    }
    if (parts.length) return parts.join(' · ')
  }
  return ''
}

async function runCheck(svcName: string, check: CheckConfig, isFirstCheck: boolean): Promise<RowResult[]> {
  const mainRow: RowResult = {
    id: `${svcName}-${check.label}`,
    service: isFirstCheck ? svcName : '',
    endpoint: check.label,
    status: 'pending',
    info: '',
  }
  try {
    const url = `${window.location.origin}${check.url}`
    const token = (authStore as any).accessToken
    const headers: Record<string, string> = {}
    if (token) headers['Authorization'] = `Bearer ${token}`

    const res = await fetch(url, {
      headers,
      credentials: 'omit',
      signal: AbortSignal.timeout(10000),
    })
    if (!res.ok) {
      mainRow.status = 'error'
      mainRow.info = `HTTP ${res.status}`
      return [mainRow]
    }
    const contentType = res.headers.get('content-type') || ''
    if (contentType.includes('json')) {
      const data = await res.json()
      mainRow.status = 'ok'
      mainRow.info = buildInfo(data, check)
      mainRow.details = data as Record<string, unknown>

      // Expand known service responses into sub-rows
      if (svcName === 'Taki') return [mainRow, ...expandTaki(data)]
      if (svcName === 'Search') return [mainRow, ...expandAggregator(data)]
    } else {
      const text = await res.text()
      mainRow.status = 'ok'
      mainRow.info = text.trim().slice(0, 80) || 'OK'
    }
  } catch (e) {
    mainRow.status = 'error'
    mainRow.info = e instanceof Error ? e.message : String(e)
  }
  return [mainRow]
}

async function runAllChecks() {
  const services = getServices()
  // Build placeholder rows — show table immediately
  const initial: RowResult[] = []
  const checkMeta: Array<{ svcName: string; check: CheckConfig; isFirst: boolean; startIdx: number }> = []
  for (const svc of services) {
    for (let i = 0; i < svc.checks.length; i++) {
      checkMeta.push({ svcName: svc.name, check: svc.checks[i], isFirst: i === 0, startIdx: initial.length })
      initial.push({
        id: `${svc.name}-${svc.checks[i].label}`,
        service: i === 0 ? svc.name : '',
        endpoint: svc.checks[i].label,
        status: 'pending',
        info: '',
      })
    }
  }
  rows.value = initial
  loading.value = false

  // Fire all checks in parallel, splice results (may be multi-row) as they resolve
  for (const cm of checkMeta) {
    runCheck(cm.svcName, cm.check, cm.isFirst).then((resultRows) => {
      const current = [...rows.value]
      // Find the placeholder row by id
      const idx = current.findIndex((r) => r.id === `${cm.svcName}-${cm.check.label}`)
      if (idx >= 0) {
        current.splice(idx, 1, ...resultRows)
        rows.value = current
      }
    })
  }
}

onMounted(() => {
  runAllChecks()
  refreshTimer = setInterval(runAllChecks, 60000)
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
