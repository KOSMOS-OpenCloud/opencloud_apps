<template>
  <div class="assign-panel">
    <h3 v-if="targetFolders.length" class="assign-panel-title">Zielordner</h3>
    <div v-if="targetFolders.length" :class="['assign-panel-targets', { 'assign-panel-targets--compact': targetFolders.length > 4 }]">
      <button
        v-for="folder in targetFolders"
        :key="folder.id"
        :class="['assign-target', { 'assign-target--selected': selectedTarget === folder.id, 'assign-target--compact': targetFolders.length > 4, 'assign-target--return': folder.kind === 'return' }]"
        @click="$emit('select-target', folder.id)"
        :title="folder.label"
      >
        <span v-if="targetFolders.length <= 4" class="assign-target-icon">
          <svg v-if="folder.icon === 'money'" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="12" cy="12" r="3"/><path d="M2 10h2m16 0h2M2 14h2m16 0h2"/>
          </svg>
          <svg v-else-if="folder.icon === 'file-text'" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/>
          </svg>
          <svg v-else-if="folder.icon === 'return'" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <polyline points="9 14 4 9 9 4"/><path d="M20 20v-7a4 4 0 0 0-4-4H4"/>
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
    <div v-if="showAssign || showAssignRename || showFile" class="assign-btn-group">
      <oc-button
        v-if="showAssign"
        class="assign-btn"
        variation="primary"
        appearance="filled"
        :disabled="!canAssign || assigning || disabled"
        @click="$emit('assign')"
      >
        {{ assigning ? $gettext('Wird zugewiesen...') : (selectedIsReturn ? $gettext('Zurückgeben') : $gettext('Zuweisen')) }}
      </oc-button>
      <oc-button
        v-if="showAssignRename && hasDocTitle"
        class="assign-btn assign-btn--rename"
        variation="primary"
        appearance="outline"
        :disabled="!canAssign || assigning || disabled"
        @click="$emit('assign-rename')"
        :title="$gettext('Zuweisen und nach Dokumenttitel umbenennen')"
      >
        {{ $gettext('Zuweisen+') }}
      </oc-button>
      <oc-button
        v-if="showFile"
        class="assign-btn assign-btn--file"
        variation="primary"
        :appearance="showAssign ? 'outline' : 'filled'"
        :disabled="!hasDocument || filing || assigning || disabled"
        @click="$emit('file')"
        :title="$gettext('In einem Space ablegen (Verschieben nach)')"
      >
        {{ $gettext('Ablegen') }}
      </oc-button>
    </div>
    <oc-button
      class="delete-btn"
      variation="danger"
      appearance="outline"
      :disabled="deleting || disabled"
      @click="$emit('delete')"
    >
      {{ deleting ? $gettext('Wird gelöscht...') : $gettext('Löschen') }}
    </oc-button>
  </div>
</template>

<script lang="ts">
import { defineComponent, PropType, computed } from 'vue'
import { useGettext } from 'vue3-gettext'
import { TargetFolder, PosteingangAction } from '../types'

export default defineComponent({
  name: 'AssignPanel',
  props: {
    targetFolders: { type: Array as PropType<TargetFolder[]>, required: true },
    selectedTarget: { type: String, default: '' },
    assigning: { type: Boolean, default: false },
    deleting: { type: Boolean, default: false },
    disabled: { type: Boolean, default: false },
    hasDocTitle: { type: Boolean, default: false },
    actions: { type: Array as PropType<PosteingangAction[]>, required: true },
    hasDocument: { type: Boolean, default: false },
    filing: { type: Boolean, default: false }
  },
  emits: ['select-target', 'assign', 'assign-rename', 'delete', 'file'],
  setup(props) {
    const selectedFolder = computed(() => props.targetFolders.find(t => t.id === props.selectedTarget))
    const selectedIsReturn = computed(() => selectedFolder.value?.kind === 'return')
    const hasReturnTarget = computed(() => props.targetFolders.some(t => t.kind === 'return'))
    // Rückgabe-Ziele sind immer zuweisbar, auch wenn "assign" nicht freigeschaltet ist (Endpunkt)
    const showAssign = computed(() => props.actions.includes('assign') || hasReturnTarget.value)
    const canAssign = computed(() => !!selectedFolder.value && (props.actions.includes('assign') || selectedIsReturn.value))
    const showAssignRename = computed(() => props.actions.includes('assignRename'))
    const showFile = computed(() => props.actions.includes('file'))
    return { selectedIsReturn, showAssign, canAssign, showAssignRename, showFile }
  }
})
</script>

<style>
.assign-panel {
  padding: 16px;
  border-bottom: 1px solid var(--oc-role-outline-variant);
}

.assign-panel-title {
  font-size: 13px;
  font-weight: 600;
  margin: 0 0 12px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  color: var(--oc-role-on-surface-variant);
}

.assign-panel-targets {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 8px;
  margin-bottom: 12px;
}

.assign-panel-targets--compact {
  grid-template-columns: repeat(3, 1fr);
  gap: 4px;
}

.assign-target {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  padding: 12px 8px;
  background: var(--oc-role-surface-container);
  border: 2px solid var(--oc-role-outline-variant);
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.15s;
}

.assign-target:hover {
  border-color: var(--oc-role-primary);
  background: var(--oc-role-surface-container-high);
}

.assign-target--selected {
  border-color: var(--oc-role-primary);
  background: var(--oc-role-secondary-container);
}

.assign-target--return {
  border-style: dashed;
  border-color: var(--oc-role-tertiary, #b26a00);
  background: color-mix(in srgb, var(--oc-role-tertiary, #b26a00) 12%, var(--oc-role-surface-container));
}

.assign-target--return .assign-target-icon,
.assign-target--return .assign-target-label {
  color: var(--oc-role-tertiary, #b26a00);
}

.assign-target--return:hover,
.assign-target--return.assign-target--selected {
  border-color: var(--oc-role-tertiary, #b26a00);
  background: color-mix(in srgb, var(--oc-role-tertiary, #b26a00) 24%, var(--oc-role-surface-container));
}

.assign-target-icon {
  color: var(--oc-role-on-surface-variant);
}

.assign-target--selected .assign-target-icon {
  color: var(--oc-role-primary);
}

.assign-target-label {
  font-size: 12px;
  font-weight: 500;
  text-align: center;
}

.assign-target--compact {
  flex-direction: row;
  padding: 8px 6px;
  gap: 0;
}

.assign-target--compact .assign-target-label {
  font-size: 11px;
}

.assign-btn-group {
  display: flex;
  gap: 6px;
}

.assign-btn {
  flex: 1;
  padding: 10px;
  background: var(--oc-role-primary);
  color: var(--oc-role-on-primary);
  border: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.15s;
}

.assign-btn--rename,
.assign-btn--file {
  flex: 0 0 auto;
}

.assign-btn:hover:not(:disabled) {
  background: color-mix(in srgb, var(--oc-role-primary) 85%, black);
}

.assign-btn:disabled {
  background: var(--oc-role-surface-container-highest);
  color: var(--oc-role-on-surface-variant);
  cursor: default;
}

.delete-btn {
  width: 100%;
  margin-top: 8px;
}
</style>
