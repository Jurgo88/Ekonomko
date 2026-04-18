<script setup lang="ts">
import { computed } from 'vue'
import VChart from 'vue-echarts'
import '@/lib/echarts'
import { formatMoney } from '@/lib/money'

interface Slice {
  name: string
  amount: number
}

const props = defineProps<{ data: Slice[] }>()

// Paleta — vyladená tak, aby fungovala na svetlom aj tmavom pozadí
const palette = [
  '#2563eb',
  '#dc2626',
  '#16a34a',
  '#d97706',
  '#9333ea',
  '#0891b2',
  '#e11d48',
  '#059669',
  '#ca8a04',
  '#7c3aed',
  '#f43f5e',
  '#0284c7',
]

const option = computed(() => ({
  color: palette,
  tooltip: {
    trigger: 'item',
    formatter: (p: { name: string; value: number; percent: number }) =>
      `<strong>${p.name}</strong><br/>${formatMoney(p.value)} · ${p.percent.toFixed(1)}%`,
  },
  legend: {
    type: 'scroll',
    bottom: 0,
    textStyle: { color: 'var(--echarts-text, #475569)' },
  },
  series: [
    {
      name: 'Výdavky',
      type: 'pie',
      radius: ['45%', '72%'],
      avoidLabelOverlap: true,
      itemStyle: {
        borderRadius: 6,
        borderColor: 'transparent',
        borderWidth: 2,
      },
      label: { show: false },
      labelLine: { show: false },
      data: props.data.map((d) => ({ name: d.name, value: Number(d.amount.toFixed(2)) })),
    },
  ],
}))
</script>

<template>
  <div class="h-72">
    <v-chart v-if="data.length" :option="option" autoresize />
    <div
      v-else
      class="flex h-full items-center justify-center text-sm text-muted-foreground"
    >
      Tento mesiac zatiaľ žiadne výdavky.
    </div>
  </div>
</template>
