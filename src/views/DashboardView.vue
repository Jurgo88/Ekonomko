<script setup lang="ts">
import { onMounted } from 'vue'
import { formatMoney } from '@/lib/money'
import { formatMonth } from '@/lib/date'
import { useBudgetStats } from '@/composables/useBudgetStats'
import CategoryPieChart from '@/components/charts/CategoryPieChart.vue'
import MonthlyBarChart from '@/components/charts/MonthlyBarChart.vue'

const { fetch, kpi, byCategory, monthly, loading, error } = useBudgetStats()

onMounted(() => fetch())
</script>

<template>
  <section class="p-4 md:p-6 space-y-6">
    <header>
      <h1 class="text-2xl font-semibold">Dashboard</h1>
      <p class="text-sm text-muted-foreground capitalize">{{ formatMonth(new Date()) }}</p>
    </header>

    <p v-if="loading" class="text-sm text-muted-foreground">Načítavam...</p>
    <p v-if="error" class="text-sm text-destructive">{{ error }}</p>

    <!-- KPI karty -->
    <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
      <div class="rounded-lg border bg-card p-4">
        <p class="text-xs text-muted-foreground uppercase tracking-wide">Príjmy</p>
        <p class="mt-1 text-2xl font-semibold text-green-600 dark:text-green-400">
          {{ formatMoney(kpi.income) }}
        </p>
      </div>
      <div class="rounded-lg border bg-card p-4">
        <p class="text-xs text-muted-foreground uppercase tracking-wide">Výdavky</p>
        <p class="mt-1 text-2xl font-semibold text-destructive">
          {{ formatMoney(kpi.expense) }}
        </p>
      </div>
      <div class="rounded-lg border bg-card p-4">
        <p class="text-xs text-muted-foreground uppercase tracking-wide">Zostatok</p>
        <p
          class="mt-1 text-2xl font-semibold"
          :class="kpi.balance >= 0 ? 'text-foreground' : 'text-destructive'"
        >
          {{ formatMoney(kpi.balance) }}
        </p>
      </div>
    </div>

    <!-- Grafy -->
    <div class="grid grid-cols-1 xl:grid-cols-2 gap-3">
      <div class="rounded-lg border bg-card p-4">
        <h2 class="text-sm font-semibold mb-2">Výdavky podľa kategórií</h2>
        <p class="text-xs text-muted-foreground mb-2">Tento mesiac</p>
        <CategoryPieChart :data="byCategory" />
      </div>
      <div class="rounded-lg border bg-card p-4">
        <h2 class="text-sm font-semibold mb-2">Príjmy vs. výdavky</h2>
        <p class="text-xs text-muted-foreground mb-2">Posledných 6 mesiacov</p>
        <MonthlyBarChart :data="monthly" />
      </div>
    </div>
  </section>
</template>
