import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import type { Household } from '@/types/models'

export const useHouseholdStore = defineStore('household', () => {
  const current = ref<Household | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  // Vráti prvú domácnosť, ktorej je user členom (RLS filtruje zvyšok).
  async function fetchCurrent() {
    loading.value = true
    error.value = null
    try {
      const { data, error: e } = await supabase
        .from('households')
        .select('*')
        .order('created_at', { ascending: true })
        .limit(1)
        .maybeSingle()
      if (e) throw e
      current.value = (data ?? null) as Household | null
    } catch (e) {
      error.value = (e as Error).message
      throw e
    } finally {
      loading.value = false
    }
  }

  // Onboarding: pri prvom prihlásení user nemá nič. Vytvor domácnosť,
  // zaradiť seba ako ownera, spusti seed kategórií, vytvor default účet.
  async function ensureForCurrentUser() {
    if (current.value) return current.value

    await fetchCurrent()
    if (current.value) return current.value

    const { data: userRes } = await supabase.auth.getUser()
    const uid = userRes.user?.id
    if (!uid) throw new Error('Nie si prihlásený')

    const { data: household, error: e1 } = await supabase
      .from('households')
      .insert({ name: 'Moja domácnosť', currency: 'EUR', created_by: uid })
      .select()
      .single()
    if (e1) throw e1

    const { error: e2 } = await supabase
      .from('household_members')
      .insert({ household_id: household.id, user_id: uid, role: 'owner' })
    if (e2) throw e2

    const { error: e3 } = await supabase.rpc('seed_default_categories', {
      p_household_id: household.id,
    })
    if (e3) throw e3

    const { error: e4 } = await supabase.from('accounts').insert({
      household_id: household.id,
      name: 'Hlavný účet',
      type: 'checking',
      currency: 'EUR',
      initial_balance: 0,
      display_order: 0,
    })
    if (e4) throw e4

    current.value = household as Household
    return current.value
  }

  function reset() {
    current.value = null
    error.value = null
  }

  return { current, loading, error, fetchCurrent, ensureForCurrentUser, reset }
})
