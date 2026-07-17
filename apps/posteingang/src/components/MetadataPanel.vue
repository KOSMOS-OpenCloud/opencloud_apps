<template>
  <div class="meta-panel">
    <div class="meta-panel-header">
      <h3 class="meta-panel-title">Metadaten</h3>
      <button class="meta-reindex-btn" :disabled="reindexing" @click="$emit('reindex')">
        {{ reindexing ? 'Indexiert...' : 'Reindex' }}
      </button>
    </div>
    <div v-if="schema && Object.keys(values).length > 0" class="meta-panel-scroll">
      <template v-for="(prop, key) in schema.properties" :key="key">
        <!-- Nested object (doc, sender) -->
        <fieldset v-if="prop.type === 'object' && prop.properties" class="meta-group">
          <legend class="meta-group-legend">{{ key }}</legend>
          <div v-for="(childProp, childKey) in prop.properties" :key="childKey"
            class="meta-field" :class="{ 'meta-field--uncertain': isUncertain(key + '.' + childKey) }">
            <label class="meta-field-label">
              {{ childKey }}
              <span v-if="isUncertain(key + '.' + childKey)" class="meta-field-warn" title="Unsicher">?</span>
            </label>
            <div class="meta-field-value" :class="{ 'meta-field-value--empty': getValue(key, childKey) == null }">
              {{ formatValue(getValue(key, childKey), childProp) }}
            </div>
          </div>
        </fieldset>

        <!-- Array (uncertain) -->
        <div v-else-if="prop.type === 'array'" class="meta-field">
          <label class="meta-field-label">{{ key }}</label>
          <div class="meta-field-value" :class="{ 'meta-field-value--empty': !getTopValue(key)?.length }">
            {{ Array.isArray(getTopValue(key)) ? getTopValue(key).join(', ') : '\u2014' }}
          </div>
        </div>

        <!-- Scalar (is_letterhead) -->
        <div v-else class="meta-field">
          <label class="meta-field-label">{{ key }}</label>
          <div class="meta-field-value" :class="{ 'meta-field-value--empty': getTopValue(key) == null }">
            {{ formatValue(getTopValue(key), prop) }}
          </div>
        </div>
      </template>
    </div>
    <div v-else class="meta-panel-empty">
      Keine Metadaten vorhanden
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent, PropType } from 'vue'
import { JsonSchema, JsonSchemaProperty } from '../types'

export default defineComponent({
  name: 'MetadataPanel',
  props: {
    schema: { type: Object as PropType<JsonSchema | null>, default: null },
    values: { type: Object as PropType<Record<string, unknown>>, default: () => ({}) },
    reindexing: { type: Boolean, default: false }
  },
  emits: ['reindex'],
  setup(props) {
    function getTopValue(key: string): any {
      return props.values?.[key]
    }

    function getValue(group: string, key: string): any {
      return props.values?.[`${group}.${key}`] ?? null
    }

    function formatValue(val: any, prop: JsonSchemaProperty): string {
      if (val == null) return '\u2014'
      const t = Array.isArray(prop.type) ? prop.type[0] : prop.type
      if (t === 'boolean') return val ? 'Ja' : 'Nein'
      return String(val)
    }

    function isUncertain(dotPath: string): boolean {
      const uncertain = props.values?.uncertain
      return Array.isArray(uncertain) && uncertain.includes(dotPath)
    }

    return { getTopValue, getValue, formatValue, isUncertain }
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
  border-top: 1px solid #e0e0e0;
  flex-shrink: 0;
}

.meta-panel-title {
  font-size: 13px;
  font-weight: 600;
  margin: 0;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  color: #666;
}

.meta-reindex-btn {
  background: none;
  border: 1px solid #ddd;
  border-radius: 4px;
  padding: 4px 12px;
  font-size: 12px;
  cursor: pointer;
  color: #1565c0;
}

.meta-reindex-btn:hover:not(:disabled) {
  background: #f5f9ff;
}

.meta-reindex-btn:disabled {
  opacity: 0.5;
  cursor: default;
}

.meta-panel-scroll {
  flex: 1;
  overflow: auto;
  padding: 0 16px 16px;
}

.meta-panel-empty {
  padding: 24px 16px;
  text-align: center;
  color: #999;
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
  color: #1565c0;
  padding: 0;
  margin-bottom: 8px;
}

.meta-field {
  margin-bottom: 6px;
}

.meta-field--uncertain {
  background: #fff8e1;
  margin-left: -6px;
  margin-right: -6px;
  padding: 2px 6px;
  border-radius: 3px;
}

.meta-field-label {
  display: block;
  font-size: 11px;
  font-weight: 500;
  color: #888;
  margin-bottom: 2px;
}

.meta-field-warn {
  color: #e65100;
  font-weight: 700;
}

.meta-field-value {
  font-size: 13px;
  color: #333;
  padding: 2px 0;
}

.meta-field-value--empty {
  color: #ccc;
}
</style>
