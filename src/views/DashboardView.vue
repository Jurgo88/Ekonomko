<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { parseISO, isWithinInterval } from 'date-fns'
import {
  TrendingUp,
  TrendingDown,
  Wallet,
  Plus,
  X,
  ReceiptText,
  ChevronRight,
  CreditCard,
  PiggyBank,
  Banknote,
  ArrowLeftRight,
  BarChart3,
} from 'lucide-vue-next'
import { formatMoney, formatSigned } from '@/lib/money'
import { formatMonth, formatDate, getLastMonths } from '@/lib/date'
import { useBudgetStats } from '@/composables/useBudgetStats'
import { useAccountsStore } from '@/stores/accounts'
import { useTransactionsStore } from '@/stores/transactions'
import { useCategoriesStore } from '@/stores/categories'
import CategoryPieChart from '@/components/charts/CategoryPieChart.vue'
import MonthlyBarChart from '@/components/charts/MonthlyBarChart.vue'
import TransactionForm from '@/components/transactions/TransactionForm.vue'
import type { Account } from '@/types/models'

const { fetch, items, kpi, kpiPrev, savingsRate, txCount, byCategory, monthly, loading, error } =
  useBudgetStats()
const accountsStore = useAccountsStore()
const txStore = useTransactionsStore()
const categoriesStore = useCategoriesStore()

// Modal
const modalOpen = ref(false)
function openCreate() {
  modalOpen.value = true
}
function closeModal() {
  modalOpen.value = false
}
async function onSaved() {
  closeModal()
  await fetch()
}

onMounted(() => fetch())

// Account balance from all transactions in store
function accountBalance(account: Account): number {
  let bal = Number(account.initial_balance)
  for (const t of txStore.items) {
    if (t.type === 'income' && t.account_id === account.id) bal += Number(t.amount)
    else if (t.type === 'expense' && t.account_id === account.id) bal -= Number(t.amount)
    else if (t.type === 'transfer') {
      if (t.account_id === account.id) bal -= Number(t.amount)
      if (t.transfer_to_account_id === account.id) bal += Number(t.amount)
    }
  }
  return bal
}

function accountTypeLabel(type: string): string {
  const map: Record<string, string> = {
    checking: 'Bežný účet',
    savings: 'Sporiaci účet',
    cash: 'Hotovosť',
    credit_card: 'Kreditná karta',
    investment: 'Investície',
    other: 'Iné',
  }
  return map[type] ?? type
}

function accountIcon(type: string) {
  switch (type) {
    case 'savings':
      return PiggyBank
    case 'cash':
      return Banknote
    case 'credit_card':
      return CreditCard
    case 'transfer':
      return ArrowLeftRight
    default:
      return CreditCard
  }
}

function categoryName(categoryId: string | null): string {
  if (!categoryId) return 'Bez kategórie'
  return categoriesStore.byId.get(categoryId)?.name ?? 'Bez kategórie'
}

// Výber mesiaca v grafe
const selectedMonthIdx = ref<number | null>(null)
const monthRanges = getLastMonths(6)

const selectedMonthStat = computed(() => {
  if (selectedMonthIdx.value === null) return null
  const range = monthRanges[selectedMonthIdx.value]
  let income = 0
  let expense = 0
  for (const t of items.value) {
    if (!isWithinInterval(parseISO(t.date), { start: range.start, end: range.end })) continue
    if (t.type === 'income') income += Number(t.amount)
    else if (t.type === 'expense') expense += Number(t.amount)
  }
  return { label: range.label, income, expense, balance: income - expense }
})

const selectedMonthCategories = computed(() => {
  if (selectedMonthIdx.value === null) return []
  const range = monthRanges[selectedMonthIdx.value]
  const sums = new Map<string | null, number>()
  for (const t of items.value) {
    if (t.type !== 'expense') continue
    if (!isWithinInterval(parseISO(t.date), { start: range.start, end: range.end })) continue
    sums.set(t.category_id, (sums.get(t.category_id) ?? 0) + Number(t.amount))
  }
  return [...sums.entries()]
    .map(([id, amount]) => ({
      name: id ? categoriesStore.byId.get(id)?.name ?? 'Bez kategórie' : 'Bez kategórie',
      amount,
    }))
    .sort((a, b) => b.amount - a.amount)
    .slice(0, 5)
})

// Trend vs previous month
function calcTrend(
  current: number,
  prev: number,
): { pct: number; dir: 'up' | 'down' | 'same' } | null {
  if (prev === 0) return null
  const diff = ((current - prev) / prev) * 100
  return {
    pct: Math.abs(diff),
    dir: diff > 0.5 ? 'up' : diff < -0.5 ? 'down' : 'same',
  }
}

const incomeTrend = computed(() => calcTrend(kpi.value.income, kpiPrev.value.income))
const expenseTrend = computed(() => calcTrend(kpi.value.expense, kpiPrev.value.expense))

const recentTx = computed(() => txStore.items.slice(0, 5))

const totalNetWorth = computed(() =>
  accountsStore.active.reduce((sum, a) => sum + accountBalance(a), 0),
)
</script>

<template>
  <section class="p-4 md:p-6 space-y-6 max-w-7xl mx-auto">
    <!-- Header -->
    <header class="flex items-center justify-between gap-3">
      <div>
        <h1 class="text-2xl font-bold tracking-tight">Dashboard</h1>
        <p class="text-sm text-muted-foreground mt-0.5 capitalize">
          {{ formatMonth(new Date()) }}
        </p>
      </div>
      <button
        type="button"
        class="inline-flex items-center gap-2 h-10 px-4 rounded-lg bg-primary text-primary-foreground text-sm font-medium hover:opacity-90 transition-opacity shrink-0"
        @click="openCreate"
      >
        <Plus class="h-4 w-4" />
        <span class="hidden sm:inline">Pridať transakciu</span>
        <span class="sm:hidden">Pridať</span>
      </button>
    </header>

    <!-- Skeleton loader -->
    <template v-if="loading">
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-3 animate-pulse">
        <div v-for="i in 3" :key="i" class="h-28 rounded-xl bg-muted" />
      </div>
      <div class="grid grid-cols-1 xl:grid-cols-2 gap-3 animate-pulse">
        <div class="h-80 rounded-xl bg-muted" />
        <div class="h-80 rounded-xl bg-muted" />
      </div>
    </template>

    <!-- Error -->
    <div
      v-else-if="error"
      class="rounded-xl border border-destructive/30 bg-destructive/10 p-4 text-sm text-destructive"
    >
      {{ error }}
    </div>

    <template v-else>
      <!-- KPI Cards -->
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
        <!-- Príjmy -->
        <div class="rounded-xl border bg-card p-5">
          <div class="flex items-start justify-between gap-3">
            <div class="min-w-0">
              <p class="text-xs text-muted-foreground uppercase tracking-widest font-medium">
                Príjmy
              </p>
              <p class="mt-2 text-2xl font-bold text-green-600 dark:text-green-400 tabular-nums">
                {{ formatMoney(kpi.income) }}
              </p>
            </div>
            <div class="p-2 rounded-lg bg-green-50 dark:bg-green-950/60 shrink-0">
              <TrendingUp class="h-5 w-5 text-green-600 dark:text-green-400" />
            </div>
          </div>
          <div class="mt-3 flex items-center gap-1 text-xs" v-if="incomeTrend">
            <span
              :class="
                incomeTrend.dir === 'up'
                  ? 'text-green-600 dark:text-green-400'
                  : incomeTrend.dir === 'down'
                    ? 'text-destructive'
                    : 'text-muted-foreground'
              "
              class="font-medium"
            >
              {{ incomeTrend.dir === 'up' ? '+' : incomeTrend.dir === 'down' ? '−' : ''
              }}{{ incomeTrend.pct.toFixed(1) }}%
            </span>
            <span class="text-muted-foreground">vs. minulý mesiac</span>
          </div>
          <p v-else class="mt-3 text-xs text-muted-foreground">Žiadne porovnanie</p>
        </div>

        <!-- Výdavky -->
        <div class="rounded-xl border bg-card p-5">
          <div class="flex items-start justify-between gap-3">
            <div class="min-w-0">
              <p class="text-xs text-muted-foreground uppercase tracking-widest font-medium">
                Výdavky
              </p>
              <p class="mt-2 text-2xl font-bold text-destructive tabular-nums">
                {{ formatMoney(kpi.expense) }}
              </p>
            </div>
            <div class="p-2 rounded-lg bg-red-50 dark:bg-red-950/60 shrink-0">
              <TrendingDown class="h-5 w-5 text-destructive" />
            </div>
          </div>
          <div class="mt-3 flex items-center gap-1 text-xs" v-if="expenseTrend">
            <span
              :class="
                expenseTrend.dir === 'down'
                  ? 'text-green-600 dark:text-green-400'
                  : expenseTrend.dir === 'up'
                    ? 'text-destructive'
                    : 'text-muted-foreground'
              "
              class="font-medium"
            >
              {{ expenseTrend.dir === 'up' ? '+' : expenseTrend.dir === 'down' ? '−' : ''
              }}{{ expenseTrend.pct.toFixed(1) }}%
            </span>
            <span class="text-muted-foreground">vs. minulý mesiac</span>
          </div>
          <p v-else class="mt-3 text-xs text-muted-foreground">Žiadne porovnanie</p>
        </div>

        <!-- Zostatok / Miera úspor -->
        <div class="rounded-xl border bg-card p-5">
          <div class="flex items-start justify-between gap-3">
            <div class="min-w-0">
              <p class="text-xs text-muted-foreground uppercase tracking-widest font-medium">
                Čistý zostatok
              </p>
              <p
                class="mt-2 text-2xl font-bold tabular-nums"
                :class="kpi.balance >= 0 ? 'text-foreground' : 'text-destructive'"
              >
                {{ formatMoney(kpi.balance) }}
              </p>
            </div>
            <div class="p-2 rounded-lg bg-blue-50 dark:bg-blue-950/60 shrink-0">
              <Wallet class="h-5 w-5 text-blue-600 dark:text-blue-400" />
            </div>
          </div>
          <div v-if="savingsRate !== null" class="mt-3 space-y-1">
            <div class="flex items-center justify-between text-xs">
              <span class="text-muted-foreground">Miera úspor</span>
              <span
                :class="
                  savingsRate >= 0 ? 'text-green-600 dark:text-green-400' : 'text-destructive'
                "
                class="font-medium"
                >{{ savingsRate.toFixed(1) }}%</span
              >
            </div>
            <div class="h-1.5 rounded-full bg-muted overflow-hidden">
              <div
                class="h-full rounded-full transition-all duration-500"
                :class="savingsRate >= 0 ? 'bg-green-500' : 'bg-destructive'"
                :style="{ width: `${Math.min(Math.abs(savingsRate), 100)}%` }"
              />
            </div>
          </div>
          <p v-else class="mt-3 text-xs text-muted-foreground">Žiadne príjmy tento mesiac</p>
        </div>
      </div>

      <!-- Rýchle štatistiky -->
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
        <div class="rounded-xl border bg-card p-4 flex items-center gap-3">
          <div class="p-2 rounded-lg bg-muted shrink-0">
            <ReceiptText class="h-4 w-4 text-muted-foreground" />
          </div>
          <div>
            <p class="text-xs text-muted-foreground">Transakcie tento mesiac</p>
            <p class="text-lg font-semibold tabular-nums">{{ txCount }}</p>
          </div>
        </div>

        <div class="rounded-xl border bg-card p-4 flex items-center gap-3" v-if="byCategory[0]">
          <div
            class="w-2.5 h-10 rounded-full shrink-0"
            style="background: #2563eb"
          />
          <div class="min-w-0">
            <p class="text-xs text-muted-foreground">Najväčšia výdavková kategória</p>
            <p class="text-sm font-semibold truncate">{{ byCategory[0].name }}</p>
            <p class="text-xs text-muted-foreground tabular-nums">
              {{ formatMoney(byCategory[0].amount) }}
            </p>
          </div>
        </div>
        <div v-else class="rounded-xl border bg-card p-4 flex items-center gap-3">
          <div class="p-2 rounded-lg bg-muted shrink-0">
            <BarChart3 class="h-4 w-4 text-muted-foreground" />
          </div>
          <div>
            <p class="text-xs text-muted-foreground">Najväčšia výdavková kategória</p>
            <p class="text-sm font-semibold text-muted-foreground">—</p>
          </div>
        </div>

        <div class="rounded-xl border bg-card p-4 flex items-center gap-3">
          <div class="p-2 rounded-lg bg-muted shrink-0">
            <Wallet class="h-4 w-4 text-muted-foreground" />
          </div>
          <div>
            <p class="text-xs text-muted-foreground">Celkové čisté imanie</p>
            <p
              class="text-lg font-semibold tabular-nums"
              :class="totalNetWorth >= 0 ? 'text-foreground' : 'text-destructive'"
            >
              {{ formatMoney(totalNetWorth) }}
            </p>
          </div>
        </div>
      </div>

      <!-- Grafy -->
      <div class="grid grid-cols-1 xl:grid-cols-2 gap-3">
        <div class="rounded-xl border bg-card p-5">
          <div class="mb-4 flex items-start justify-between gap-2">
            <div>
              <h2 class="text-sm font-semibold">Príjmy vs. výdavky</h2>
              <p class="text-xs text-muted-foreground mt-0.5">
                {{ selectedMonthIdx !== null ? `Vybraný: ${monthly[selectedMonthIdx].label}` : 'Posledných 6 mesiacov — klikni na mesiac' }}
              </p>
            </div>
            <button
              v-if="selectedMonthIdx !== null"
              type="button"
              class="shrink-0 text-xs text-muted-foreground hover:text-foreground flex items-center gap-1"
              @click="selectedMonthIdx = null"
            >
              <X class="h-3 w-3" /> Zrušiť výber
            </button>
          </div>
          <MonthlyBarChart
            :data="monthly"
            :selected-index="selectedMonthIdx"
            @select="selectedMonthIdx = $event"
          />

          <!-- Detail vybraného mesiaca -->
          <Transition
            enter-active-class="transition-all duration-300 ease-out"
            enter-from-class="opacity-0 -translate-y-2"
            enter-to-class="opacity-100 translate-y-0"
            leave-active-class="transition-all duration-200 ease-in"
            leave-from-class="opacity-100 translate-y-0"
            leave-to-class="opacity-0 -translate-y-2"
          >
            <div v-if="selectedMonthStat" class="mt-4 space-y-3">
              <div class="h-px bg-border" />

              <!-- KPI riadok -->
              <div class="grid grid-cols-3 gap-2">
                <div class="rounded-lg bg-muted p-3 text-center">
                  <p class="text-xs text-muted-foreground mb-0.5">Príjmy</p>
                  <p class="text-sm font-bold text-green-600 dark:text-green-400 tabular-nums">
                    {{ formatMoney(selectedMonthStat.income) }}
                  </p>
                </div>
                <div class="rounded-lg bg-muted p-3 text-center">
                  <p class="text-xs text-muted-foreground mb-0.5">Výdavky</p>
                  <p class="text-sm font-bold text-destructive tabular-nums">
                    {{ formatMoney(selectedMonthStat.expense) }}
                  </p>
                </div>
                <div class="rounded-lg bg-muted p-3 text-center">
                  <p class="text-xs text-muted-foreground mb-0.5">Zostatok</p>
                  <p
                    class="text-sm font-bold tabular-nums"
                    :class="selectedMonthStat.balance >= 0 ? 'text-foreground' : 'text-destructive'"
                  >
                    {{ formatMoney(selectedMonthStat.balance) }}
                  </p>
                </div>
              </div>

              <!-- Top kategórie -->
              <div v-if="selectedMonthCategories.length">
                <p class="text-xs text-muted-foreground mb-2">Výdavky podľa kategórií</p>
                <div class="space-y-1.5">
                  <div
                    v-for="cat in selectedMonthCategories"
                    :key="cat.name"
                    class="flex items-center gap-2"
                  >
                    <div class="flex-1 min-w-0">
                      <div class="flex items-center justify-between text-xs mb-0.5">
                        <span class="truncate font-medium">{{ cat.name }}</span>
                        <span class="tabular-nums text-muted-foreground ml-2 shrink-0">
                          {{ formatMoney(cat.amount) }}
                        </span>
                      </div>
                      <div class="h-1.5 rounded-full bg-muted overflow-hidden">
                        <div
                          class="h-full rounded-full bg-red-500 transition-all duration-500"
                          :style="{
                            width: `${(cat.amount / selectedMonthStat.expense) * 100}%`,
                          }"
                        />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <p v-else class="text-xs text-muted-foreground text-center py-2">
                Žiadne výdavky v tomto mesiaci.
              </p>
            </div>
          </Transition>
        </div>
        <div class="rounded-xl border bg-card p-5">
          <div class="mb-4">
            <h2 class="text-sm font-semibold">Výdavky podľa kategórií</h2>
            <p class="text-xs text-muted-foreground mt-0.5">Tento mesiac</p>
          </div>
          <CategoryPieChart :data="byCategory" />
        </div>
      </div>

      <!-- Účty -->
      <div v-if="accountsStore.active.length">
        <div class="flex items-center justify-between mb-3">
          <h2 class="text-sm font-semibold">Účty</h2>
          <RouterLink
            to="/accounts"
            class="text-xs text-primary hover:underline flex items-center gap-0.5"
          >
            Spravovať <ChevronRight class="h-3 w-3" />
          </RouterLink>
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-3">
          <div
            v-for="account in accountsStore.active"
            :key="account.id"
            class="rounded-xl border bg-card p-4"
          >
            <div class="flex items-center gap-2 mb-2">
              <div class="p-1.5 rounded-md bg-muted shrink-0">
                <component :is="accountIcon(account.type)" class="h-3.5 w-3.5 text-muted-foreground" />
              </div>
              <p class="text-xs text-muted-foreground truncate">{{ account.name }}</p>
            </div>
            <p
              class="text-xl font-bold tabular-nums"
              :class="accountBalance(account) >= 0 ? 'text-foreground' : 'text-destructive'"
            >
              {{ formatMoney(accountBalance(account), account.currency) }}
            </p>
            <p class="text-xs text-muted-foreground mt-0.5">
              {{ accountTypeLabel(account.type) }}
            </p>
          </div>
        </div>
      </div>

      <!-- Posledné transakcie -->
      <div>
        <div class="flex items-center justify-between mb-3">
          <h2 class="text-sm font-semibold">Posledné transakcie</h2>
          <RouterLink
            to="/transactions"
            class="text-xs text-primary hover:underline flex items-center gap-0.5"
          >
            Zobraziť všetky <ChevronRight class="h-3 w-3" />
          </RouterLink>
        </div>
        <div class="rounded-xl border bg-card overflow-hidden">
          <div
            v-if="!recentTx.length"
            class="py-12 flex flex-col items-center gap-2 text-center"
          >
            <div class="p-3 rounded-full bg-muted">
              <ReceiptText class="h-6 w-6 text-muted-foreground" />
            </div>
            <p class="text-sm text-muted-foreground">Zatiaľ žiadne transakcie.</p>
            <button
              class="text-sm text-primary hover:underline font-medium"
              @click="openCreate"
            >
              Pridaj prvú transakciu
            </button>
          </div>
          <div v-else>
            <div
              v-for="(tx, i) in recentTx"
              :key="tx.id"
              class="flex items-center gap-3 px-4 py-3 hover:bg-muted/40 transition-colors"
              :class="{ 'border-b': i < recentTx.length - 1 }"
            >
              <!-- Typ ikona -->
              <div
                class="w-9 h-9 rounded-full shrink-0 flex items-center justify-center font-bold text-sm text-white"
                :class="
                  tx.type === 'income'
                    ? 'bg-green-500'
                    : tx.type === 'expense'
                      ? 'bg-red-500'
                      : 'bg-blue-500'
                "
              >
                {{ tx.type === 'income' ? '↑' : tx.type === 'expense' ? '↓' : '⇄' }}
              </div>
              <div class="flex-1 min-w-0">
                <p class="text-sm font-medium truncate">
                  {{ tx.description || categoryName(tx.category_id) }}
                </p>
                <p class="text-xs text-muted-foreground truncate">
                  {{ categoryName(tx.category_id) }} · {{ formatDate(tx.date) }}
                </p>
              </div>
              <p
                class="text-sm font-semibold shrink-0 tabular-nums"
                :class="
                  tx.type === 'income'
                    ? 'text-green-600 dark:text-green-400'
                    : tx.type === 'expense'
                      ? 'text-destructive'
                      : 'text-foreground'
                "
              >
                {{ formatSigned(tx.amount, tx.type, tx.currency) }}
              </p>
            </div>
          </div>
        </div>
      </div>
    </template>

    <!-- Modal: Nová transakcia -->
    <Teleport to="body">
      <div
        v-if="modalOpen"
        class="fixed inset-0 z-40 bg-black/50 backdrop-blur-sm"
        role="presentation"
        @click="closeModal"
      />
      <div
        v-if="modalOpen"
        class="fixed inset-0 z-50 flex items-end md:items-center justify-center p-0 md:p-4 pointer-events-none"
      >
        <div
          class="pointer-events-auto w-full md:max-w-lg bg-card text-card-foreground rounded-t-xl md:rounded-xl border shadow-xl max-h-[92vh] overflow-y-auto"
        >
          <div class="flex items-center justify-between px-4 py-3 border-b">
            <h2 class="text-base font-semibold">Nová transakcia</h2>
            <button
              type="button"
              class="p-2 -m-2 text-muted-foreground hover:text-foreground rounded-md hover:bg-accent"
              aria-label="Zavrieť"
              @click="closeModal"
            >
              <X class="h-5 w-5" />
            </button>
          </div>
          <div class="p-4">
            <TransactionForm :initial="null" @saved="onSaved" @cancel="closeModal" />
          </div>
        </div>
      </div>
    </Teleport>
  </section>
</template>
