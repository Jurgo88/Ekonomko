<script setup lang="ts">
import { computed, ref } from 'vue'
import { useTheme } from '@/composables/useTheme'
import { graphic } from 'echarts/core'
import VChart from 'vue-echarts'
import '@/lib/echarts'
import { formatMoney } from '@/lib/money'

interface Bar {
  label: string
  income: number
  expense: number
}

const props = defineProps<{
  data: Bar[]
  selectedIndex?: number | null
}>()

const emit = defineEmits<{
  select: [index: number | null]
}>()

const { isDark } = useTheme()
const chartRef = ref<InstanceType<typeof VChart>>()
const hasAny = computed(() => props.data.some((d) => d.income > 0 || d.expense > 0))

function onZrClick(event: { offsetX: number; offsetY: number }) {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const instance = chartRef.value as any
  if (!instance) return
  const result = instance.convertFromPixel({ seriesIndex: 0 }, [event.offsetX, event.offsetY])
  if (!result) return
  const idx = Math.round(result[0])
  if (idx < 0 || idx >= props.data.length) return
  emit('select', props.selectedIndex === idx ? null : idx)
}

const incomeGradient = new graphic.LinearGradient(0, 0, 0, 1, [
  { offset: 0, color: '#4ade80' },
  { offset: 1, color: '#16a34a' },
])

const expenseGradient = new graphic.LinearGradient(0, 0, 0, 1, [
  { offset: 0, color: '#f87171' },
  { offset: 1, color: '#dc2626' },
])

const option = computed(() => {
  const sel = props.selectedIndex ?? null

  function barData(values: number[], gradient: unknown) {
    return values.map((value, i) => ({
      value,
      itemStyle: {
        color: gradient,
        borderRadius: [6, 6, 2, 2],
        opacity: sel === null || sel === i ? 1 : 0.2,
      },
    }))
  }

  const dark = isDark.value
  const textColor = dark ? '#94a3b8' : '#475569'
  const lineColor = dark ? '#1e293b' : '#e2e8f0'

  return {
    tooltip: {
      trigger: 'axis',
      axisPointer: { type: 'shadow', shadowStyle: { color: 'rgba(0,0,0,0.04)' } },
      backgroundColor: dark ? '#1e293b' : '#ffffff',
      borderColor: dark ? '#334155' : '#e2e8f0',
      borderWidth: 1,
      textStyle: { color: dark ? '#f1f5f9' : '#0f172a', fontSize: 12 },
      formatter(params: { marker: string; value: number }[]) {
        return params
          .map((p) => `${p.marker} ${formatMoney(p.value)}`)
          .join('<br/>')
      },
    },
    legend: {
      data: ['Príjmy', 'Výdavky'],
      bottom: 0,
      itemWidth: 12,
      itemHeight: 8,
      borderRadius: 4,
      textStyle: { color: textColor, fontSize: 12 },
    },
    grid: {
      top: 8,
      left: 0,
      right: 0,
      bottom: 56,
      containLabel: true,
    },
    xAxis: {
      type: 'category',
      data: props.data.map((d) => d.label),
      axisTick: { show: false },
      axisLine: { show: false },
      axisLabel: {
        color: textColor,
        fontSize: 11,
        interval: 0,
        rotate: -20,
        margin: 10,
      },
    },
    yAxis: {
      type: 'value',
      splitNumber: 4,
      splitLine: {
        lineStyle: { color: lineColor, type: 'dashed' },
      },
      axisLabel: {
        color: textColor,
        fontSize: 11,
        formatter: (v: number) =>
          v >= 1000 ? `${(v / 1000).toFixed(v % 1000 === 0 ? 0 : 1)}k €` : `${v} €`,
      },
    },
    series: [
      {
        name: 'Príjmy',
        type: 'bar',
        color: '#16a34a',
        barMaxWidth: 28,
        barGap: '15%',
        cursor: 'pointer',
        showBackground: true,
        backgroundStyle: { color: 'rgba(0,0,0,0.03)', borderRadius: [6, 6, 2, 2] },
        data: barData(
          props.data.map((d) => Number(d.income.toFixed(2))),
          incomeGradient,
        ),
      },
      {
        name: 'Výdavky',
        type: 'bar',
        color: '#dc2626',
        barMaxWidth: 28,
        barGap: '15%',
        cursor: 'pointer',
        showBackground: true,
        backgroundStyle: { color: 'rgba(0,0,0,0.03)', borderRadius: [6, 6, 2, 2] },
        data: barData(
          props.data.map((d) => Number(d.expense.toFixed(2))),
          expenseGradient,
        ),
      },
    ],
  }
})
</script>

<template>
  <div class="h-80">
    <v-chart ref="chartRef" v-if="hasAny" :option="option" autoresize @zr:click="onZrClick" />
    <div v-else class="flex h-full items-center justify-center text-sm text-muted-foreground">
      Zatiaľ nie sú žiadne dáta za posledných 6 mesiacov.
    </div>
  </div>
</template>
