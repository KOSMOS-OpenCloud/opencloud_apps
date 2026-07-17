import { Resource } from '@opencloud-eu/web-client'

// -- JSON Schema format as used by open_taki (docmeta_schema.json) --
// Loaded from .inbox/meta.json on the space at startup

export interface JsonSchemaProperty {
  type: string | string[]
  enum?: (string | null)[]
  pattern?: string
  properties?: Record<string, JsonSchemaProperty>
  required?: string[]
  items?: JsonSchemaProperty
  additionalProperties?: boolean
}

export interface JsonSchema extends JsonSchemaProperty {
  type: 'object'
  properties: Record<string, JsonSchemaProperty>
}

// -- App config from .inbox/<user>.conf or .inbox/default.conf --

export interface TargetFolder {
  id: string
  label: string
  icon: string
  path: string
}

export interface PosteingangConfig {
  spaceName: string
  sourceFolders: string[]
  targetFolders: TargetFolder[]
}

export interface DocumentEntry {
  resource: Resource
  sourceFolder: string
}

export const DEFAULT_CONFIG: PosteingangConfig = {
  spaceName: 'Posteingang',
  sourceFolders: ['Inbox', 'Rueckgabe'],
  targetFolders: []
}
