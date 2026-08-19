import {
  defineWebApplication,
  Extension,
  SidebarNavExtension,
  useAbility,
} from '@opencloud-eu/web-pkg'
import { computed } from 'vue'
import HealthStatus from './HealthStatus.vue'
import { useGettext } from 'vue3-gettext'

const applicationId = 'admin-settings/health'

export default defineWebApplication({
  setup({ applicationConfig }) {
    const { $gettext } = useGettext()
    const { can } = useAbility()

    const healthConfig = (applicationConfig as Record<string, unknown>) ?? {}

    const extensions = computed<Extension[]>(() => {
      if (!can('read-all', 'Setting')) return []

      return [
        {
          id: 'health.admin.nav',
          extensionPointIds: ['app.admin-settings.navItems'],
          type: 'sidebarNav',
          navItem: {
            name: $gettext('Health'),
            icon: 'heart-pulse',
            route: { path: `/${applicationId}` },
            isVisible: () => can('read-all', 'Setting'),
            priority: 90,
          },
        } as SidebarNavExtension,
      ]
    })

    const routes = [
      {
        name: 'health',
        path: '/',
        component: HealthStatus,
        meta: {
          authContext: 'user',
          title: $gettext('Health'),
          healthConfig,
        },
      },
    ]

    return {
      appInfo: {
        name: $gettext('Health'),
        id: applicationId,
        icon: 'heart-pulse',
        color: '#C62828',
      },
      routes,
      extensions,
    }
  },
})
