import { defineConfig } from '@opencloud-eu/extension-sdk'

export default defineConfig({
  name: 'web-app-photo-addon',
  build: {
    rolldownOptions: {
      output: {
        entryFileNames: 'js/[name]-[hash].mjs',
        chunkFileNames: 'js/[name]-[hash].mjs',
      },
    },
  },
  test: {
    exclude: ['**/e2e/**']
  }
})
