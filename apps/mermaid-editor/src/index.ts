import {
  ApplicationInformation,
  AppWrapperRoute,
  defineWebApplication
} from '@opencloud-eu/web-pkg'
import translations from '../l10n/translations.json'
import App from './App.vue'
import { useGettext } from 'vue3-gettext'

const applicationId = 'mermaid-editor'

export default defineWebApplication({
  setup() {
    const { $gettext } = useGettext()

    const routes = [
      {
        name: 'mermaid-editor',
        path: '/:driveAliasAndItem(.*)?',
        component: AppWrapperRoute(App, { applicationId }),
        meta: {
          authContext: 'hybrid',
          patchCleanPath: true
        }
      }
    ]

    const appInfo: ApplicationInformation = {
      name: $gettext('Mermaid Editor'),
      id: applicationId,
      icon: 'flow-chart',
      color: '#FF3670',
      defaultExtension: 'mmd',
      extensions: [
        {
          extension: 'mmd',
          routeName: 'mermaid-editor',
          newFileMenu: {
            menuTitle() {
              return $gettext('Mermaid diagram')
            }
          }
        },
        {
          extension: 'mermaid',
          routeName: 'mermaid-editor'
        }
      ]
    }

    return {
      appInfo,
      routes,
      translations
    }
  }
})
