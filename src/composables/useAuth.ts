import { storeToRefs } from 'pinia'
import { useAuthStore } from '@/stores/auth'

// Pohodlný composable — refs sú reaktívne, akcie nie.
export function useAuth() {
  const store = useAuthStore()
  const { user, session, loading, error, isAuthenticated } = storeToRefs(store)
  return {
    user,
    session,
    loading,
    error,
    isAuthenticated,
    signIn: store.signInWithPassword,
    signUp: store.signUp,
    signOut: store.signOut,
    clearError: store.clearError,
  }
}
