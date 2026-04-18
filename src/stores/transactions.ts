import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import type { Transaction, TransactionType } from '@/types/models'
import { useHouseholdStore } from './household'
import type { TransactionFormValues } from '@/lib/validators'

export interface TransactionFilters {
  dateFrom: string | null
  dateTo: string | null
  categoryId: string | null
  type: TransactionType | null
}

export const defaultFilters: TransactionFilters = {
  dateFrom: null,
  dateTo: null,
  categoryId: null,
  type: null,
}

export const useTransactionsStore = defineStore('transactions', () => {
  const items = ref<Transaction[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)
  const filters = ref<TransactionFilters>({ ...defaultFilters })

  async function fetch() {
    const household = useHouseholdStore()
    if (!household.current) return
    loading.value = true
    error.value = null
    try {
      let q = supabase
        .from('transactions')
        .select('*')
        .eq('household_id', household.current.id)
        .order('date', { ascending: false })
        .order('created_at', { ascending: false })

      const f = filters.value
      if (f.dateFrom) q = q.gte('date', f.dateFrom)
      if (f.dateTo) q = q.lte('date', f.dateTo)
      if (f.categoryId) q = q.eq('category_id', f.categoryId)
      if (f.type) q = q.eq('type', f.type)

      const { data, error: e } = await q
      if (e) throw e
      items.value = (data ?? []) as Transaction[]
    } catch (e) {
      error.value = (e as Error).message
      throw e
    } finally {
      loading.value = false
    }
  }

  function setFilter<K extends keyof TransactionFilters>(key: K, value: TransactionFilters[K]) {
    filters.value[key] = value
  }

  function resetFilters() {
    filters.value = { ...defaultFilters }
  }

  async function create(values: TransactionFormValues) {
    const household = useHouseholdStore()
    if (!household.current) throw new Error('Žiadna domácnosť')
    const { data: userRes } = await supabase.auth.getUser()

    const payload = {
      household_id: household.current.id,
      account_id: values.account_id,
      category_id: values.type === 'transfer' ? null : values.category_id,
      type: values.type,
      amount: values.amount,
      currency: values.currency,
      date: values.date,
      description: values.description,
      note: values.note,
      transfer_to_account_id:
        values.type === 'transfer' ? values.transfer_to_account_id : null,
      created_by: userRes.user?.id ?? null,
    }

    const { data, error: e } = await supabase
      .from('transactions')
      .insert(payload)
      .select()
      .single()
    if (e) throw e
    const tx = data as Transaction
    items.value.unshift(tx)
    return tx
  }

  async function update(id: string, values: TransactionFormValues) {
    const patch = {
      account_id: values.account_id,
      category_id: values.type === 'transfer' ? null : values.category_id,
      type: values.type,
      amount: values.amount,
      currency: values.currency,
      date: values.date,
      description: values.description,
      note: values.note,
      transfer_to_account_id:
        values.type === 'transfer' ? values.transfer_to_account_id : null,
    }
    const { data, error: e } = await supabase
      .from('transactions')
      .update(patch)
      .eq('id', id)
      .select()
      .single()
    if (e) throw e
    const tx = data as Transaction
    const idx = items.value.findIndex((t) => t.id === id)
    if (idx >= 0) items.value[idx] = tx
    return tx
  }

  async function remove(id: string) {
    const { error: e } = await supabase.from('transactions').delete().eq('id', id)
    if (e) throw e
    items.value = items.value.filter((t) => t.id !== id)
  }

  function reset() {
    items.value = []
    error.value = null
    filters.value = { ...defaultFilters }
  }

  return {
    items,
    loading,
    error,
    filters,
    fetch,
    setFilter,
    resetFilters,
    create,
    update,
    remove,
    reset,
  }
})
