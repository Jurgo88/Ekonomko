<script setup lang="ts">
import { computed } from 'vue'
import VChart from 'vue-echarts'
import '@/lib/echarts'
import { formatMoney } from '@/lib/money'

interface Bar {
  label: string
  income: number
  expense: number
}

const props = defineProps<{ data: Bar[] }>()

const hasAny = computed(() => props.data.some((d) => d.income > 0 || d.expense > 0))

const option = computed(() => ({
  tooltip: {
    trigger: 'axis',
    axisPointer: { type: 'shadow' },
    valueFormatter: (v: number) => formatMoney(v),
  },
  legend: {
    data: ['Príjmy', 'Výdavky'],
    bottom: 0,
  },
  grid: { top: 12, left: 56, right: 16, bottom: 48, containLabel: true },
  xAxis: {
    type: 'category',
    data: props.data.map((d) => d.label),
    axisTick: { alignWithLabel: true },
  },
  yAxis: {
    type: 'value',
    axisLabel: {
      formatter: (v: number) => `${Math.round(v)} €`,
    },
  },
  series: [
    {
      name: 'Príjmy',
      type: 'bar',
      itemStyle: { color: '#16a34a', borderRadius: [4, 4, 0, 0] },
      data: props.data.map((d) => Number(d.income.toFixed(2))),
    },
    {
      name: 'Výdavky',
      type: 'bar',
      itemStyle: { color: '#dc2626', borderRadius: [4, 4, 0, 0] },
      data: props.data.map((d) => Number(d.expense.toFixed(2))),
    },
  ],
}))
</script>

<template>
  <div class="h-72">
    <v-chart v-if="hasAny" :option="option" autoresize />
    <div
      v-else
      class="flex h-full items-center justify-center text-sm text-muted-foreground"
    >
      Zatiaľ nie sú žiadne dáta za posledných 6 mesiacov.
    </div>
  </div>
</template>
