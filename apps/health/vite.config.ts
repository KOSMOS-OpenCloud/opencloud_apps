import { defineConfig } from '@opencloud-eu/extension-sdk'

export default defineConfig({
  name: 'health',
  build: {
    outDir: 'dist',
    rolldownOptions: {
      output: {
        entryFileNames: 'js/[name]-[hash].mjs',
        chunkFileNames: 'js/[name]-[hash].mjs',
      },
    },
  },
})
