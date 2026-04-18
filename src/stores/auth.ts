import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { Session, User, AuthError } from '@supabase/supabase-js'
import { supabase } from '@/lib/supabase'

export const useAuthStore = defineStore('auth', () => {
  const session = ref<Session | null>(null)
  const user = ref<User | null>(null)
  const loading = ref(true) // true pri inicializácii, kým nezistíme session
  const error = ref<string | null>(null)

  const isAuthenticated = computed(() => !!user.value)

  // Zavolá sa raz pri štarte appky — načíta existujúcu session
  // a registruje listener na zmeny (login/logout v iných taboch atď.)
  async function init() {
    const { data } = await supabase.auth.getSession()
    session.value = data.session
    user.value = data.session?.user ?? null
    loading.value = false

    supabase.auth.onAuthStateChange((_event, newSession) => {
      session.value = newSession
      user.value = newSession?.user ?? null
    })
  }

  async function signInWithPassword(email: string, password: string) {
    error.value = null
    const { error: err } = await supabase.auth.signInWithPassword({ email, password })
    if (err) {
      error.value = humanizeAuthError(err)
      throw err
    }
  }

  async function signUp(email: string, password: string) {
    error.value = null
    const { error: err } = await supabase.auth.signUp({ email, password })
    if (err) {
      error.value = humanizeAuthError(err)
      throw err
    }
  }

  async function signOut() {
    await supabase.auth.signOut()
    // stav sa aktualizuje cez onAuthStateChange listener
  }

  function clearError() {
    error.value = null
  }

  return {
    session,
    user,
    loading,
    error,
    isAuthenticated,
    init,
    signInWithPassword,
    signUp,
    signOut,
    clearError,
  }
})

function humanizeAuthError(err: AuthError): string {
  const msg = err.message.toLowerCase()
  if (msg.includes('invalid login credentials')) return 'Nesprávny e-mail alebo heslo.'
  if (msg.includes('email not confirmed')) return 'E-mail ešte nie je potvrdený.'
  if (msg.includes('user already registered')) return 'Účet s týmto e-mailom už existuje.'
  if (msg.includes('password should be at least')) return 'Heslo musí mať aspoň 6 znakov.'
  return err.message
}
