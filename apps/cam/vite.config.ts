import { defineConfig } from '@opencloud-eu/extension-sdk'

// App-ID cam: Route /cam, Kachel im Quick-Menü (Blitz) und Eintrag im App-Menü.
export default defineConfig({
  name: 'cam',
  build: {
    rolldownOptions: {
      output: {
        entryFileNames: 'js/[name]-[hash].mjs',
        chunkFileNames: 'js/[name]-[hash].mjs'
      }
    }
  }
})
