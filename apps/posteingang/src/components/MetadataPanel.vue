<template>
  <div class="meta-panel">
    <div class="meta-panel-header">
      <h3 class="meta-panel-title">{{ $gettext('Metadaten') }}</h3>
      <div class="meta-panel-actions">
        <oc-button size="small" appearance="outline" :disabled="reindexing" @click="$emit('reindex')">
          {{ reindexing ? $gettext('Indexiert...') : $gettext('Reindex') }}
        </oc-button>
        <oc-button v-if="!editing" size="small" appearance="outline" @click="$emit('toggle-edit')">
          {{ $gettext('Bearbeiten') }}
        </oc-button>
        <oc-button v-else size="small" appearance="outline" @click="$emit('toggle-edit')">
          {{ $gettext('Abbrechen') }}
        </oc-button>
      </div>
    </div>
    <div v-if="schema && Object.keys(values).length > 0" class="meta-panel-scroll">
      <template v-for="(prop, key) in schema.properties" :key="key">
        <fieldset v-if="prop.type === 'object' && prop.properties && !isHidden(key as string)" class="meta-group">
          <legend class="meta-group-legend">{{ translateKey(key as string) }}</legend>
          <div v-for="(childProp, childKey) in prop.properties" :key="childKey" v-show="!isHidden(childKey as string)"
            class="meta-field" :class="{ 'meta-field--uncertain': isUncertain(key + '.' + childKey) }">
            <label class="meta-field-label">
              {{ translateKey(childKey as string) }}
              <span v-if="isUncertain(key + '.' + childKey)" class="meta-field-warn" :title="$gettext('Unsicher')">?</span>
            </label>
            <input v-if="editing" class="meta-field-input"
              :value="getValue(key, childKey) || ''"
              @input="$emit('update', key + '.' + childKey, ($event.target as HTMLInputElement).value || null)" />
            <div v-else class="meta-field-value" :class="{ 'meta-field-value--empty': getValue(key, childKey) == null }">
              {{ formatValue(getValue(key, childKey), childProp) }}
            </div>
          </div>
        </fieldset>

        <div v-else-if="prop.type === 'array' && !isHidden(key as string)" class="meta-field">
          <label class="meta-field-label">{{ translateKey(key as string) }}</label>
          <div class="meta-field-value" :class="{ 'meta-field-value--empty': !getTopValue(key)?.length }">
            {{ Array.isArray(getTopValue(key)) ? getTopValue(key).join(', ') : '\u2014' }}
          </div>
        </div>

        <div v-else-if="!isHidden(key as string)" class="meta-field">
          <label class="meta-field-label">{{ translateKey(key as string) }}</label>
          <input v-if="editing" class="meta-field-input"
            :value="getTopValue(key) || ''"
            @input="$emit('update', key as string, ($event.target as HTMLInputElement).value || null)" />
          <div v-else class="meta-field-value" :class="{ 'meta-field-value--empty': getTopValue(key) == null }">
            {{ formatValue(getTopValue(key), prop) }}
          </div>
        </div>
      </template>

      <oc-button v-if="editing" class="meta-save-btn" variation="primary" appearance="filled"
        :disabled="saving" @click="$emit('save')">
        {{ saving ? $gettext('Wird gespeichert...') : $gettext('Speichern') }}
      </oc-button>
    </div>
    <div v-else class="meta-panel-empty">
      {{ $gettext('Keine Metadaten vorhanden') }}
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent, PropType } from 'vue'
import { useGettext } from 'vue3-gettext'
import { JsonSchema, JsonSchemaProperty } from '../types'

export default defineComponent({
  name: 'MetadataPanel',
  props: {
    schema: { type: Object as PropType<JsonSchema | null>, default: null },
    values: { type: Object as PropType<Record<string, unknown>>, default: () => ({}) },
    reindexing: { type: Boolean, default: false },
    editing: { type: Boolean, default: false },
    saving: { type: Boolean, default: false }
  },
  emits: ['reindex', 'toggle-edit', 'update', 'save'],
  setup(props) {
    const { $gettext } = useGettext()

    const hiddenFields = new Set(['is_letterhead', 'uncertain', 'subject_inferred', 'meta_source'])

    function isHidden(key: string): boolean {
      return hiddenFields.has(key)
    }

    function translateKey(key: string): string {
      return $gettext(key.replace(/_/g, ' '))
    }

    function getTopValue(key: string): any {
      return props.values?.[key]
    }

    function getValue(group: string, key: string): any {
      return props.values?.[`${group}.${key}`] ?? null
    }

    function formatValue(val: any, prop: JsonSchemaProperty): string {
      if (val == null) return '\u2014'
      const t = Array.isArray(prop.type) ? prop.type[0] : prop.type
      if (t === 'boolean') return val ? $gettext('Ja') : $gettext('Nein')
      return String(val)
    }

    function isUncertain(dotPath: string): boolean {
      const uncertain = props.values?.uncertain
      return Array.isArray(uncertain) && uncertain.includes(dotPath)
    }

    return { getTopValue, getValue, formatValue, isUncertain, isHidden, translateKey }
  }
})
</script>

<style>
.meta-panel {
  padding: 0;
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.meta-panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  border-top: 1px solid var(--oc-role-outline, #e0e0e0);
  flex-shrink: 0;
}

.meta-panel-title {
  font-size: 13px;
  font-weight: 600;
  margin: 0;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  color: var(--oc-role-on-surface-variant, #666);
}

.meta-panel-actions {
  display: flex;
  gap: 4px;
}

.meta-panel-scroll {
  flex: 1;
  overflow: auto;
  padding: 0 16px 16px;
}

.meta-panel-empty {
  padding: 24px 16px;
  text-align: center;
  color: var(--oc-role-on-surface-variant, #999);
  font-size: 13px;
}

.meta-group {
  border: none;
  padding: 0;
  margin: 0 0 12px;
}

.meta-group-legend {
  font-size: 12px;
  font-weight: 600;
  color: var(--oc-role-primary, #1565c0);
  padding: 0;
  margin-bottom: 8px;
}

.meta-field {
  margin-bottom: 6px;
}

.meta-field--uncertain {
  background: var(--oc-role-warning-container, #fff8e1);
  margin-left: -6px;
  margin-right: -6px;
  padding: 2px 6px;
  border-radius: 3px;
}

.meta-field-label {
  display: block;
  font-size: 11px;
  font-weight: 500;
  color: var(--oc-role-on-surface-variant, #888);
  margin-bottom: 2px;
}

.meta-field-warn {
  color: var(--oc-role-error, #e65100);
  font-weight: 700;
}

.meta-field-value {
  font-size: 13px;
  color: var(--oc-role-on-surface, #333);
  padding: 2px 0;
}

.meta-field-value--empty {
  color: var(--oc-role-on-surface-variant, #ccc);
}

.meta-field-input {
  width: 100%;
  padding: 5px 8px;
  border: 1px solid var(--oc-role-outline, #ddd);
  border-radius: 4px;
  font-size: 13px;
  outline: none;
  box-sizing: border-box;
  background: var(--oc-role-surface, #fff);
  color: var(--oc-role-on-surface, #333);
}

.meta-field-input:focus {
  border-color: var(--oc-role-primary, #1565c0);
}

.meta-save-btn {
  margin-top: 12px;
  width: 100%;
}
</style>
