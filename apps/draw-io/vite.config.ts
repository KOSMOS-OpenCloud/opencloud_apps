import { defineConfig } from '@opencloud-eu/extension-sdk'

export default defineConfig({
  name: 'draw-io-editor',
  test: {
    exclude: ['**/e2e/**']
  }
})
