import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import type { Account } from '@/types/models'
import { useHouseholdStore } from './household'

export const useAccountsStore = defineStore('accounts', () => {
  const items = ref<Account[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  const active = computed(() => items.value.filter((a) => !a.is_archived))
  const byId = computed(() => {
    const m = new Map<string, Account>()
    for (const a of items.value) m.set(a.id, a)
    return m
  })

  async function fetch() {
    const household = useHouseholdStore()
    if (!household.current) return
    loading.value = true
    error.value = null
    try {
      const { data, error: e } = await supabase
        .from('accounts')
        .select('*')
        .eq('household_id', household.current.id)
        .order('display_order', { ascending: true })
        .order('created_at', { ascending: true })
      if (e) throw e
      items.value = (data ?? []) as Account[]
    } catch (e) {
      error.value = (e as Error).message
      throw e
    } finally {
      loading.value = false
    }
  }

  function reset() {
    items.value = []
    error.value = null
  }

  return { items, active, byId, loading, error, fetch, reset }
})
