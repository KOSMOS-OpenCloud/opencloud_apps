<template>
  <div class="assign-panel">
    <h3 class="assign-panel-title">Zielordner</h3>
    <div class="assign-panel-targets">
      <button
        v-for="folder in targetFolders"
        :key="folder.id"
        :class="['assign-target', { 'assign-target--selected': selectedTarget === folder.id }]"
        @click="$emit('select-target', folder.id)"
        :title="folder.label"
      >
        <span class="assign-target-icon">
          <svg v-if="folder.icon === 'money'" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="12" cy="12" r="3"/><path d="M2 10h2m16 0h2M2 14h2m16 0h2"/>
          </svg>
          <svg v-else-if="folder.icon === 'file-text'" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/>
          </svg>
          <svg v-else-if="folder.icon === 'mail'" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <rect x="2" y="4" width="20" height="16" rx="2"/><polyline points="22 6 12 13 2 6"/>
          </svg>
          <svg v-else width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/>
          </svg>
        </span>
        <span class="assign-target-label">{{ folder.label }}</span>
      </button>
    </div>
    <oc-button
      class="assign-btn"
      variation="primary"
      appearance="filled"
      :disabled="!selectedTarget || assigning || disabled"
      @click="$emit('assign')"
    >
      {{ assigning ? $gettext('Wird zugewiesen...') : $gettext('Zuweisen') }}
    </oc-button>
  </div>
</template>

<script lang="ts">
import { defineComponent, PropType } from 'vue'
import { useGettext } from 'vue3-gettext'
import { TargetFolder } from '../types'

export default defineComponent({
  name: 'AssignPanel',
  props: {
    targetFolders: { type: Array as PropType<TargetFolder[]>, required: true },
    selectedTarget: { type: String, default: '' },
    assigning: { type: Boolean, default: false },
    disabled: { type: Boolean, default: false }
  },
  emits: ['select-target', 'assign']
})
</script>

<style>
.assign-panel {
  padding: 16px;
  border-bottom: 1px solid #e0e0e0;
}

.assign-panel-title {
  font-size: 13px;
  font-weight: 600;
  margin: 0 0 12px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  color: #666;
}

.assign-panel-targets {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 8px;
  margin-bottom: 12px;
}

.assign-target {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  padding: 12px 8px;
  background: #fafafa;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.15s;
}

.assign-target:hover {
  border-color: #90caf9;
  background: #f5f9ff;
}

.assign-target--selected {
  border-color: #1565c0;
  background: #e3f2fd;
}

.assign-target-icon {
  color: #555;
}

.assign-target--selected .assign-target-icon {
  color: #1565c0;
}

.assign-target-label {
  font-size: 12px;
  font-weight: 500;
  text-align: center;
}

.assign-btn {
  width: 100%;
  padding: 10px;
  background: #1565c0;
  color: #fff;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.15s;
}

.assign-btn:hover:not(:disabled) {
  background: #0d47a1;
}

.assign-btn:disabled {
  background: #bbb;
  cursor: default;
}
</style>
