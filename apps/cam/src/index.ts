import { defineWebApplication, type AppMenuItemExtension, type Extension } from '@opencloud-eu/web-pkg'
import { computed } from 'vue'
import { useGettext } from 'vue3-gettext'
import CamView from './views/CamView.vue'
import './style.css'

// Kamera: Fotos mit der Gerätekamera aufnehmen, Ablage Personal/Fotos/<Jahr>/<Monat>/IMG_<Zeit>.jpg.
// Erreichbar über das Quick-Menü (Blitz in der Topbar, opencloud_web kosmos ab 2026-11-08) und das App-Menü.
const applicationId = 'cam'

export default defineWebApplication({
  setup() {
    const { $gettext } = useGettext()

    const routes = [
      {
        path: '/',
        name: 'cam',
        component: CamView,
        meta: { authContext: 'user', title: $gettext('Kamera') }
      }
    ]

    const extensions = computed<Extension[]>(() => [
      {
        id: 'cam.app-menu',
        type: 'appMenuItem',
        extensionPointIds: ['app.runtime.header.app-menu'],
        label: () => $gettext('Kamera'),
        icon: 'camera',
        color: '#37474F',
        path: `/${applicationId}`,
        priority: 70
      } as AppMenuItemExtension,
      // Typ quickMenuItem nicht importiert: web-pkg 4.x aus npm kennt ihn nicht, die Hülle schon
      {
        id: 'cam.quick-menu',
        type: 'quickMenuItem',
        extensionPointIds: ['app.runtime.header.quick-menu'],
        label: () => $gettext('Kamera'),
        icon: 'camera',
        priority: 15,
        path: `/${applicationId}`
      } as unknown as Extension
    ])

    return {
      appInfo: { name: $gettext('Kamera'), id: applicationId, icon: 'camera', color: '#37474F' },
      routes,
      extensions
    }
  }
})
