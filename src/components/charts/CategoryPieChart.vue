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

const SMALL_SLICE_THRESHOLD = 0.02

const total = computed(() => props.data.reduce((s, d) => s + d.amount, 0))

const processedData = computed(() => {
  if (!total.value) return { main: [] as Slice[], others: [] as Slice[] }
  const main: Slice[] = []
  const others: Slice[] = []
  for (const d of props.data) {
    if (d.amount / total.value < SMALL_SLICE_THRESHOLD) {
      others.push(d)
    } else {
      main.push(d)
    }
  }
  if (others.length > 0)
    main.push({ name: 'Ostatné', amount: others.reduce((s, d) => s + d.amount, 0) })
  return { main, others }
})

const chartData = computed(() => processedData.value.main)
const othersItems = computed(() => processedData.value.others)

const legendItems = computed(() =>
  chartData.value.map((d, i) => ({
    name: d.name,
    amount: d.amount,
    pct: total.value ? (d.amount / total.value) * 100 : 0,
    color: palette[i % palette.length],
  })),
)

const option = computed(() => ({
  color: palette,
  tooltip: {
    trigger: 'item',
    formatter: (p: { name: string; value: number; percent: number }) => {
      if (p.name === 'Ostatné' && othersItems.value.length > 0) {
        const rows = othersItems.value
          .map((d) => `&nbsp;&nbsp;${d.name}: ${formatMoney(d.amount)}`)
          .join('<br/>')
        return `<strong>Ostatné</strong><br/>${formatMoney(p.value)} · ${p.percent.toFixed(1)}%<br/><br/>${rows}`
      }
      return `<strong>${p.name}</strong><br/>${formatMoney(p.value)} · ${p.percent.toFixed(1)}%`
    },
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
      data: chartData.value.map((d) => ({ name: d.name, value: Number(d.amount.toFixed(2)) })),
    },
  ],
}))
</script>

<template>
  <div v-if="data.length" class="space-y-4">
    <!-- Donut chart with center label overlay -->
    <div class="relative h-96">
      <v-chart :option="option" autoresize />
      <div
        class="absolute inset-0 flex flex-col items-center justify-center pointer-events-none"
      >
        <span class="text-lg font-bold tabular-nums leading-tight">{{
          formatMoney(total)
        }}</span>
        <span class="text-xs text-muted-foreground">celkovo</span>
      </div>
    </div>

    <!-- Custom legend: color · name · % · amount -->
    <div class="space-y-2">
      <div
        v-for="item in legendItems"
        :key="item.name"
        class="relative flex items-center gap-2.5 text-xs group"
      >
        <span
          class="w-2.5 h-2.5 rounded-full shrink-0"
          :style="{ background: item.color }"
        />
        <span class="flex-1 truncate">{{ item.name }}</span>
        <span class="tabular-nums text-muted-foreground w-10 text-right"
          >{{ item.pct.toFixed(1) }}%</span
        >
        <span class="tabular-nums font-medium w-24 text-right">{{
          formatMoney(item.amount)
        }}</span>

        <!-- Tooltip pre "Ostatné" — zobrazí zoznam zlúčených kategórií -->
        <div
          v-if="item.name === 'Ostatné' && othersItems.length > 0"
          class="absolute bottom-full left-0 mb-2 z-20 hidden group-hover:block bg-card text-card-foreground border rounded-lg shadow-lg p-2.5 min-w-44 space-y-1 pointer-events-none"
        >
          <div
            v-for="other in othersItems"
            :key="other.name"
            class="flex items-center justify-between gap-4"
          >
            <span class="text-muted-foreground truncate">{{ other.name }}</span>
            <span class="tabular-nums font-medium shrink-0">{{ formatMoney(other.amount) }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>

  <div
    v-else
    class="flex min-h-48 items-center justify-center text-sm text-muted-foreground"
  >
    Tento mesiac zatiaľ žiadne výdavky.
  </div>
</template>
