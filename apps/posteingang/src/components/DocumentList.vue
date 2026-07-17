<template>
  <div class="doc-list">
    <div v-if="loading" class="doc-list-loading">Lade Dokumente...</div>
    <div v-else-if="documents.length === 0" class="doc-list-empty">Keine Dokumente</div>
    <ul v-else class="doc-list-items">
      <li
        v-for="doc in documents"
        :key="doc.resource.id"
        :class="['doc-list-item', { 'doc-list-item--selected': selected?.resource.id === doc.resource.id }]"
        @click="$emit('select', doc)"
      >
        <div class="doc-list-item-icon">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
            <polyline points="14 2 14 8 20 8"/>
          </svg>
        </div>
        <div class="doc-list-item-info">
          <div class="doc-list-item-name" :title="doc.resource.name">{{ doc.resource.name }}</div>
          <div class="doc-list-item-meta">
            <span class="doc-list-item-folder">{{ doc.sourceFolder }}</span>
            <span v-if="doc.resource.size" class="doc-list-item-size">{{ formatSize(doc.resource.size) }}</span>
          </div>
        </div>
      </li>
    </ul>
  </div>
</template>

<script lang="ts">
import { defineComponent, PropType } from 'vue'
import { DocumentEntry } from '../types'

export default defineComponent({
  name: 'DocumentList',
  props: {
    documents: { type: Array as PropType<DocumentEntry[]>, required: true },
    selected: { type: Object as PropType<DocumentEntry | null>, default: null },
    loading: { type: Boolean, default: false }
  },
  emits: ['select'],
  setup() {
    function formatSize(bytes: number): string {
      if (bytes < 1024) return bytes + ' B'
      if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB'
      return (bytes / (1024 * 1024)).toFixed(1) + ' MB'
    }
    return { formatSize }
  }
})
</script>

<style>
.doc-list {
  height: 100%;
}

.doc-list-loading,
.doc-list-empty {
  padding: 24px 16px;
  text-align: center;
  color: #999;
  font-size: 13px;
}

.doc-list-items {
  list-style: none;
  margin: 0;
  padding: 0;
}

.doc-list-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 16px;
  cursor: pointer;
  border-bottom: 1px solid #f0f0f0;
  transition: background 0.15s;
}

.doc-list-item:hover {
  background: #f5f7fa;
}

.doc-list-item--selected {
  background: #e3f2fd;
  border-left: 3px solid #1565c0;
  padding-left: 13px;
}

.doc-list-item-icon {
  color: #c62828;
  flex-shrink: 0;
}

.doc-list-item-info {
  min-width: 0;
  flex: 1;
}

.doc-list-item-name {
  font-size: 13px;
  font-weight: 500;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.doc-list-item-meta {
  display: flex;
  gap: 8px;
  font-size: 11px;
  color: #999;
  margin-top: 2px;
}

.doc-list-item-folder {
  background: #f0f0f0;
  padding: 1px 6px;
  border-radius: 3px;
}
</style>
