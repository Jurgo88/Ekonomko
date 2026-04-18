import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import type { Category, CategoryType } from '@/types/models'
import { useHouseholdStore } from './household'

export const useCategoriesStore = defineStore('categories', () => {
  const items = ref<Category[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  const active = computed(() => items.value.filter((c) => !c.is_archived))
  const byId = computed(() => {
    const m = new Map<string, Category>()
    for (const c of items.value) m.set(c.id, c)
    return m
  })

  function byType(type: CategoryType) {
    return active.value.filter((c) => c.type === type)
  }

  async function fetch() {
    const household = useHouseholdStore()
    if (!household.current) return
    loading.value = true
    error.value = null
    try {
      const { data, error: e } = await supabase
        .from('categories')
        .select('*')
        .eq('household_id', household.current.id)
        .order('type', { ascending: true })
        .order('display_order', { ascending: true })
      if (e) throw e
      items.value = (data ?? []) as Category[]
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

  return { items, active, byId, byType, loading, error, fetch, reset }
})
