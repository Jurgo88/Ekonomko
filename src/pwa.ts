import { ref } from 'vue'
import { registerSW } from 'virtual:pwa-register'

/**
 * Prompt-based SW update handling.
 *
 * `needRefresh` je true, keď je pripravená nová verzia aplikácie a
 * komponent (PwaUpdatePrompt.vue) zobrazí toast s tlačidlom Obnoviť.
 * `offlineReady` je true po prvom nainštalovaní SW — appka je pripravená
 * fungovať offline.
 */
export const needRefresh = ref(false)
export const offlineReady = ref(false)

let updateSW: ((reloadPage?: boolean) => Promise<void>) | undefined

export function initPwa(): void {
  if (typeof window === 'undefined') return

  updateSW = registerSW({
    immediate: true,
    onNeedRefresh() {
      needRefresh.value = true
    },
    onOfflineReady() {
      offlineReady.value = true
    },
    onRegisterError(err) {
      console.error('[pwa] SW registration failed', err)
    },
  })
}

/** Aplikuje update a preloaduje stránku. */
export async function applyUpdate(): Promise<void> {
  if (!updateSW) return
  await updateSW(true)
}

/** Zavrie offline-ready toast. */
export function dismissOfflineReady(): void {
  offlineReady.value = false
}

/** Zavrie need-refresh toast (update prídu nabudúce). */
export function dismissNeedRefresh(): void {
  needRefresh.value = false
}
