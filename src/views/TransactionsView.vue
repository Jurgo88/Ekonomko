<script setup lang="ts">
import { ref, computed, onMounted, watch, h } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  FlexRender,
  getCoreRowModel,
  useVueTable,
  type ColumnDef,
} from '@tanstack/vue-table'
import { Pencil, Trash2, Plus, X } from 'lucide-vue-next'
import { useTransactionsStore } from '@/stores/transactions'
import { useAccountsStore } from '@/stores/accounts'
import { useCategoriesStore } from '@/stores/categories'
import type { Transaction, TransactionType } from '@/types/models'
import { formatDate } from '@/lib/date'
import { formatSigned } from '@/lib/money'
import TransactionForm from '@/components/transactions/TransactionForm.vue'

const transactions = useTransactionsStore()
const accounts = useAccountsStore()
const categories = useCategoriesStore()
const route = useRoute()
const router = useRouter()

const modalOpen = ref(false)
const editing = ref<Transaction | null>(null)

function openCreate() {
  editing.value = null
  modalOpen.value = true
}

function openEdit(tx: Transaction) {
  editing.value = tx
  modalOpen.value = true
}

function closeModal() {
  modalOpen.value = false
  editing.value = null
  // vyčisti ?new=1 z URL
  if (route.query.new) {
    router.replace({ query: { ...route.query, new: undefined } })
  }
}

async function onSaved() {
  closeModal()
}

async function onDelete(tx: Transaction) {
  if (!confirm('Naozaj zmazať túto transakciu?')) return
  await transactions.remove(tx.id)
}

// Reaguj na ?new=1 z MobileNav
watch(
  () => route.query.new,
  (v) => {
    if (v === '1') openCreate()
  },
  { immediate: true },
)

// Filtre — lokálne v-modely, pri zmene fetchni
const dateFrom = ref<string>('')
const dateTo = ref<string>('')
const typeFilter = ref<TransactionType | ''>('')
const categoryFilter = ref<string>('')

async function applyFilters() {
  transactions.setFilter('dateFrom', dateFrom.value || null)
  transactions.setFilter('dateTo', dateTo.value || null)
  transactions.setFilter('type', (typeFilter.value || null) as TransactionType | null)
  transactions.setFilter('categoryId', categoryFilter.value || null)
  await transactions.fetch()
}

async function resetFilters() {
  dateFrom.value = ''
  dateTo.value = ''
  typeFilter.value = ''
  categoryFilter.value = ''
  transactions.resetFilters()
  await transactions.fetch()
}

// Inicializácia dát
onMounted(async () => {
  // fetch je už prípadne odštartovaný AppShellom; ale istota je istota
  await transactions.fetch()
})

// ------------------------------------------------------------
// TanStack Vue Table
// ------------------------------------------------------------
const columns = computed<ColumnDef<Transaction>[]>(() => [
  {
    accessorKey: 'date',
    header: 'Dátum',
    cell: (ctx) => formatDate(ctx.getValue<string>()),
  },
  {
    accessorKey: 'type',
    header: 'Typ',
    cell: (ctx) => {
      const v = ctx.getValue<TransactionType>()
      return v === 'income' ? 'Príjem' : v === 'expense' ? 'Výdavok' : 'Prevod'
    },
  },
  {
    accessorKey: 'category_id',
    header: 'Kategória',
    cell: (ctx) => {
      const id = ctx.getValue<string | null>()
      return id ? categories.byId.get(id)?.name ?? '—' : '—'
    },
  },
  {
    accessorKey: 'account_id',
    header: 'Účet',
    cell: (ctx) => {
      const tx = ctx.row.original
      const from = accounts.byId.get(tx.account_id)?.name ?? '—'
      if (tx.type === 'transfer' && tx.transfer_to_account_id) {
        const to = accounts.byId.get(tx.transfer_to_account_id)?.name ?? '—'
        return `${from} → ${to}`
      }
      return from
    },
  },
  {
    accessorKey: 'description',
    header: 'Popis',
    cell: (ctx) => ctx.getValue<string | null>() ?? '',
  },
  {
    accessorKey: 'amount',
    header: () => h('div', { class: 'text-right' }, 'Suma'),
    cell: (ctx) => {
      const tx = ctx.row.original
      const cls =
        tx.type === 'income'
          ? 'text-green-600 dark:text-green-400'
          : tx.type === 'expense'
          ? 'text-destructive'
          : 'text-foreground'
      return h('div', { class: `text-right font-medium ${cls}` }, formatSigned(tx.amount, tx.type))
    },
  },
  {
    id: 'actions',
    header: '',
    cell: (ctx) =>
      h('div', { class: 'flex justify-end gap-1' }, [
        h(
          'button',
          {
            type: 'button',
            class:
              'p-2 -m-2 text-muted-foreground hover:text-foreground rounded-md hover:bg-accent',
            'aria-label': 'Upraviť',
            onClick: () => openEdit(ctx.row.original),
          },
          h(Pencil, { class: 'h-4 w-4' }),
        ),
        h(
          'button',
          {
            type: 'button',
            class:
              'p-2 -m-2 text-muted-foreground hover:text-destructive rounded-md hover:bg-accent',
            'aria-label': 'Zmazať',
            onClick: () => onDelete(ctx.row.original),
          },
          h(Trash2, { class: 'h-4 w-4' }),
        ),
      ]),
  },
])

const table = useVueTable({
  get data() {
    return transactions.items
  },
  get columns() {
    return columns.value
  },
  getCoreRowModel: getCoreRowModel(),
})

const inputCls =
  'h-9 w-full rounded-md border border-input bg-background px-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring'
</script>

<template>
  <section class="p-4 md:p-6 space-y-4">
    <header class="flex items-center justify-between gap-2">
      <div>
        <h1 class="text-2xl font-semibold">Transakcie</h1>
        <p class="text-sm text-muted-foreground">Prehľad príjmov, výdavkov a prevodov</p>
      </div>
      <button
        type="button"
        class="inline-flex items-center gap-2 h-10 px-3 rounded-md bg-primary text-primary-foreground text-sm font-medium hover:opacity-90"
        @click="openCreate"
      >
        <Plus class="h-4 w-4" />
        <span class="hidden sm:inline">Pridať</span>
      </button>
    </header>

    <!-- Filtre -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-2 rounded-md border p-3 bg-card">
      <div>
        <label class="text-xs text-muted-foreground">Od</label>
        <input v-model="dateFrom" type="date" :class="inputCls" />
      </div>
      <div>
        <label class="text-xs text-muted-foreground">Do</label>
        <input v-model="dateTo" type="date" :class="inputCls" />
      </div>
      <div>
        <label class="text-xs text-muted-foreground">Typ</label>
        <select v-model="typeFilter" :class="inputCls">
          <option value="">Všetky</option>
          <option value="income">Príjem</option>
          <option value="expense">Výdavok</option>
          <option value="transfer">Prevod</option>
        </select>
      </div>
      <div>
        <label class="text-xs text-muted-foreground">Kategória</label>
        <select v-model="categoryFilter" :class="inputCls">
          <option value="">Všetky</option>
          <option v-for="c in categories.active" :key="c.id" :value="c.id">{{ c.name }}</option>
        </select>
      </div>
      <div class="col-span-2 md:col-span-4 flex justify-end gap-2">
        <button
          type="button"
          class="h-9 px-3 text-sm rounded-md text-muted-foreground hover:bg-accent"
          @click="resetFilters"
        >
          Zrušiť filtre
        </button>
        <button
          type="button"
          class="h-9 px-3 text-sm rounded-md bg-secondary text-secondary-foreground hover:opacity-90"
          @click="applyFilters"
        >
          Použiť
        </button>
      </div>
    </div>

    <!-- Tabuľka -->
    <div class="rounded-md border bg-card overflow-x-auto">
      <table class="w-full text-sm">
        <thead class="bg-muted/50 text-muted-foreground">
          <tr
            v-for="headerGroup in table.getHeaderGroups()"
            :key="headerGroup.id"
            class="border-b"
          >
            <th
              v-for="header in headerGroup.headers"
              :key="header.id"
              class="px-3 py-2 text-left font-medium whitespace-nowrap"
            >
              <FlexRender
                v-if="!header.isPlaceholder"
                :render="header.column.columnDef.header"
                :props="header.getContext()"
              />
            </th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="transactions.loading">
            <td :colspan="columns.length" class="px-3 py-6 text-center text-muted-foreground">
              Načítavam...
            </td>
          </tr>
          <tr v-else-if="!transactions.items.length">
            <td :colspan="columns.length" class="px-3 py-10 text-center text-muted-foreground">
              Žiadne transakcie. Pridaj prvú cez tlačidlo vyššie.
            </td>
          </tr>
          <tr
            v-else
            v-for="row in table.getRowModel().rows"
            :key="row.id"
            class="border-b last:border-0 hover:bg-muted/30"
          >
            <td
              v-for="cell in row.getVisibleCells()"
              :key="cell.id"
              class="px-3 py-2 whitespace-nowrap"
            >
              <FlexRender :render="cell.column.columnDef.cell" :props="cell.getContext()" />
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Modal -->
    <Teleport to="body">
      <div
        v-if="modalOpen"
        class="fixed inset-0 z-40 bg-black/50"
        role="presentation"
        @click="closeModal"
      />
      <div
        v-if="modalOpen"
        class="fixed inset-0 z-50 flex items-end md:items-center justify-center p-0 md:p-4 pointer-events-none"
      >
        <div
          class="pointer-events-auto w-full md:max-w-lg bg-card text-card-foreground rounded-t-lg md:rounded-lg border shadow-xl max-h-[92vh] overflow-y-auto"
        >
          <div class="flex items-center justify-between px-4 py-3 border-b">
            <h2 class="text-base font-semibold">
              {{ editing ? 'Upraviť transakciu' : 'Nová transakcia' }}
            </h2>
            <button
              type="button"
              class="p-2 -m-2 text-muted-foreground hover:text-foreground"
              aria-label="Zavrieť"
              @click="closeModal"
            >
              <X class="h-5 w-5" />
            </button>
          </div>
          <div class="p-4">
            <TransactionForm :initial="editing" @saved="onSaved" @cancel="closeModal" />
          </div>
        </div>
      </div>
    </Teleport>
  </section>
</template>
