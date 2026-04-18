import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import { useAuthStore } from '@/stores/auth'
import { initPwa } from '@/pwa'
import './assets/main.css'

const app = createApp(App)
const pinia = createPinia()

app.use(pinia)

// Auth init musí prebehnúť PRED app.use(router), aby prvý guard run
// videl správny stav. init() je async, router.isReady() počká.
const auth = useAuthStore()
auth.init().finally(() => {
  app.use(router)
  router.isReady().then(() => {
    app.mount('#app')
    // SW registrujeme až po prvom mount — nezdržiava initial paint
    initPwa()
  })
})
