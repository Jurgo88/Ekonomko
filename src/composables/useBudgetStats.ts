import { ref, computed } from 'vue'
import { parseISO, isWithinInterval, subMonths, startOfMonth, endOfMonth } from 'date-fns'
import { supabase } from '@/lib/supabase'
import { useHouseholdStore } from '@/stores/household'
import { useCategoriesStore } from '@/stores/categories'
import {
  toISODate,
  startOfCurrentMonth,
  endOfCurrentMonth,
  getLastMonths,
} from '@/lib/date'
import type { Transaction } from '@/types/models'

export interface Kpi {
  income: number
  expense: number
  balance: number
}

export interface CategoryStat {
  categoryId: string | null
  name: string
  amount: number
}

export interface MonthlyStat {
  label: string
  income: number
  expense: number
}

// Ťahá transakcie za posledných 6 mesiacov (vrátane aktuálneho) a nad nimi
// počíta kpi, výdavky po kategóriách a mesačné sumáre. Nezávisí od filtrov
// v Transakcie-store, aby dashboard nezmenil dáta, keď user prepína filtre.
export function useBudgetStats() {
  const household = useHouseholdStore()
  const categories = useCategoriesStore()

  const items = ref<Transaction[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetch() {
    if (!household.current) return
    loading.value = true
    error.value = null
    try {
      const rangeStart = startOfMonth(subMonths(new Date(), 5))
      const rangeEnd = endOfCurrentMonth()
      const { data, error: e } = await supabase
        .from('transactions')
        .select('*')
        .eq('household_id', household.current.id)
        .gte('date', toISODate(rangeStart))
        .lte('date', toISODate(rangeEnd))
        .in('type', ['income', 'expense'])
        .order('date', { ascending: true })
      if (e) throw e
      items.value = (data ?? []) as Transaction[]
    } catch (e) {
      error.value = (e as Error).message
    } finally {
      loading.value = false
    }
  }

  const kpi = computed<Kpi>(() => {
    const range = { start: startOfCurrentMonth(), end: endOfCurrentMonth() }
    let income = 0
    let expense = 0
    for (const t of items.value) {
      if (!isWithinInterval(parseISO(t.date), range)) continue
      if (t.type === 'income') income += Number(t.amount)
      else if (t.type === 'expense') expense += Number(t.amount)
    }
    return { income, expense, balance: income - expense }
  })

  const byCategory = computed<CategoryStat[]>(() => {
    const range = { start: startOfCurrentMonth(), end: endOfCurrentMonth() }
    const sums = new Map<string | null, number>()
    for (const t of items.value) {
      if (t.type !== 'expense') continue
      if (!isWithinInterval(parseISO(t.date), range)) continue
      const key = t.category_id
      sums.set(key, (sums.get(key) ?? 0) + Number(t.amount))
    }
    const out: CategoryStat[] = []
    for (const [id, amount] of sums) {
      const name = id ? categories.byId.get(id)?.name ?? 'Bez kategórie' : 'Bez kategórie'
      out.push({ categoryId: id, name, amount })
    }
    return out.sort((a, b) => b.amount - a.amount)
  })

  const monthly = computed<MonthlyStat[]>(() => {
    const months = getLastMonths(6)
    return months.map((m) => {
      let income = 0
      let expense = 0
      for (const t of items.value) {
        const d = parseISO(t.date)
        if (!isWithinInterval(d, { start: m.start, end: m.end })) continue
        if (t.type === 'income') income += Number(t.amount)
        else if (t.type === 'expense') expense += Number(t.amount)
      }
      return { label: m.label, income, expense }
    })
  })

  const kpiPrev = computed<Kpi>(() => {
    const prev = subMonths(new Date(), 1)
    const range = { start: startOfMonth(prev), end: endOfMonth(prev) }
    let income = 0
    let expense = 0
    for (const t of items.value) {
      if (!isWithinInterval(parseISO(t.date), range)) continue
      if (t.type === 'income') income += Number(t.amount)
      else if (t.type === 'expense') expense += Number(t.amount)
    }
    return { income, expense, balance: income - expense }
  })

  const savingsRate = computed<number | null>(() => {
    const { income, expense } = kpi.value
    if (income === 0) return null
    return ((income - expense) / income) * 100
  })

  const txCount = computed(() => {
    const range = { start: startOfCurrentMonth(), end: endOfCurrentMonth() }
    return items.value.filter((t) => isWithinInterval(parseISO(t.date), range)).length
  })

  return { items, loading, error, fetch, kpi, kpiPrev, savingsRate, txCount, byCategory, monthly }
}
