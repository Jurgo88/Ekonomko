import { ref, readonly } from 'vue'

const isDarkRef = ref(false)

export function initTheme() {
  const stored = localStorage.getItem('theme')
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
  isDarkRef.value = stored !== null ? stored === 'dark' : prefersDark
  document.documentElement.classList.toggle('dark', isDarkRef.value)
}

export function useTheme() {
  function toggleDark() {
    isDarkRef.value = !isDarkRef.value
    document.documentElement.classList.toggle('dark', isDarkRef.value)
    localStorage.setItem('theme', isDarkRef.value ? 'dark' : 'light')
  }

  return { isDark: readonly(isDarkRef), toggleDark }
}
