import { defineWebApplication, useRouter, useSpacesStore } from '@opencloud-eu/web-pkg'
import translations from '../l10n/translations.json'
import App from './App.vue'
import { useGettext } from 'vue3-gettext'
import { computed, markRaw } from 'vue'

const applicationId = 'posteingang'

export default defineWebApplication({
  setup() {
    const { $gettext } = useGettext()
    const router = useRouter()

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

    const extensions = computed(() => [
      {
        id: `com.kosmos-eu.${applicationId}.app-menu-item`,
        type: 'appMenuItem' as const,
        label: () => $gettext('Posteingang'),
        icon: 'inbox-unarchive',
        color: '#1565C0',
        priority: 40,
        handler: () => {
          const spacesStore = useSpacesStore()
          const posteingangSpace = spacesStore.spaces.find(
            (s: any) => s.driveType === 'project' && s.name === 'Posteingang'
          )
          const alias = posteingangSpace?.driveAlias || 'project/posteingang'
          router.push({
            name: 'posteingang',
            params: { driveAliasAndItem: alias },
            query: { appMode: 'true' }
          })
        }
      }
    ])

    return {
      appInfo,
      routes,
      translations,
      extensions
    }
  }
})
