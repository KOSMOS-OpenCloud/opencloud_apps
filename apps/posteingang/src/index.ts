import { defineWebApplication } from '@opencloud-eu/web-pkg'
import translations from '../l10n/translations.json'
import App from './App.vue'
import { useGettext } from 'vue3-gettext'

const applicationId = 'posteingang'

export default defineWebApplication({
  setup() {
    const { $gettext } = useGettext()

    const routes = [
      {
        name: 'posteingang',
        path: '/',
        component: App,
        meta: {
          authContext: 'user',
          title: $gettext('Posteingang')
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
