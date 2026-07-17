import { defineWebApplication } from '@opencloud-eu/web-pkg'
import { defineStore } from 'pinia'
import { ref } from 'vue'
import translations from '../l10n/translations.json'
import App from './App.vue'
import { useGettext } from 'vue3-gettext'

const applicationId = 'posteingang'

// Same store ID as folderviews — Pinia shares the singleton
const useAppMenuStore = defineStore('appMenu', () => {
  const items = ref<any[]>([])
  function register(entry: any) {
    if (items.value.some((e: any) => e.spaceAlias === entry.spaceAlias)) return
    items.value.push(entry)
  }
  return { items, register }
})

export default defineWebApplication({
  setup() {
    const { $gettext } = useGettext()

    // Register in the app menu
    const appMenuStore = useAppMenuStore()
    appMenuStore.register({
      label: $gettext('Posteingang'),
      icon: 'inbox-unarchive',
      color: '#1565C0',
      spaceAlias: 'project/posteingang',
      appMode: true,
      priority: 40,
      routeName: 'posteingang'
    })

    const routes = [
      {
        name: 'posteingang',
        path: '/:driveAliasAndItem(.*)?',
        component: App,
        meta: {
          authContext: 'user',
          title: $gettext('Posteingang'),
          patchCleanPath: true
        }
      }
    ]

    const appInfo = {
      name: $gettext('Posteingang'),
      id: applicationId,
      icon: 'inbox-unarchive',
      color: '#1565C0'
    }

    return {
      appInfo,
      routes,
      translations
    }
  }
})
