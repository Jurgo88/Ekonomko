<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useAccountsStore } from '@/stores/accounts'
import { useCategoriesStore } from '@/stores/categories'
import { useTransactionsStore } from '@/stores/transactions'
import { transactionFormSchema, type TransactionFormValues } from '@/lib/validators'
import { parseAmount } from '@/lib/money'
import { toISODate } from '@/lib/date'
import type { Transaction, TransactionType } from '@/types/models'

const props = defineProps<{
  initial?: Transaction | null
}>()
const emit = defineEmits<{ (e: 'saved'): void; (e: 'cancel'): void }>()

const accounts = useAccountsStore()
const categories = useCategoriesStore()
const transactions = useTransactionsStore()

// Form state — ako strings kvôli <input>-om, konverzia pred validáciou.
const type = ref<TransactionType>(props.initial?.type ?? 'expense')
const amountInput = ref<string>(
  props.initial ? String(props.initial.amount).replace('.', ',') : '',
)
const date = ref<string>(props.initial?.date ?? toISODate(new Date()))
const accountId = ref<string>(props.initial?.account_id ?? accounts.active[0]?.id ?? '')
const categoryId = ref<string | null>(props.initial?.category_id ?? null)
const transferToAccountId = ref<string | null>(props.initial?.transfer_to_account_id ?? null)
const description = ref<string>(props.initial?.description ?? '')
const note = ref<string>(props.initial?.note ?? '')

const submitting = ref(false)
const errors = ref<Partial<Record<keyof TransactionFormValues | 'form', string>>>({})

const categoryOptions = computed(() => {
  if (type.value === 'transfer') return []
  return categories.byType(type.value === 'income' ? 'income' : 'expense')
})

// Pri prepnutí typu vynuluj nekompatibilné polia
watch(type, (t) => {
  if (t === 'transfer') {
    categoryId.value = null
  } else {
    transferToAccountId.value = null
    // ak pôvodná kategória patrí inému typu, zahoď ju
    if (categoryId.value) {
      const c = categories.byId.get(categoryId.value)
      if (!c || c.type !== (t === 'income' ? 'income' : 'expense')) {
        categoryId.value = null
      }
    }
  }
})

async function onSubmit() {
  errors.value = {}
  submitting.value = true
  try {
    const amount = parseAmount(amountInput.value)
    const raw = {
      type: type.value,
      amount: amount ?? NaN,
      date: date.value,
      account_id: accountId.value,
      category_id: categoryId.value,
      transfer_to_account_id: transferToAccountId.value,
      description: description.value.trim() || null,
      note: note.value.trim() || null,
      currency: 'EUR',
    }
    const parsed = transactionFormSchema.safeParse(raw)
    if (!parsed.success) {
      for (const issue of parsed.error.issues) {
        const key = (issue.path[0] as keyof TransactionFormValues) ?? 'form'
        errors.value[key] = issue.message
      }
      return
    }

    if (props.initial) {
      await transactions.update(props.initial.id, parsed.data)
    } else {
      await transactions.create(parsed.data)
    }
    emit('saved')
  } catch (e) {
    errors.value.form = (e as Error).message
  } finally {
    submitting.value = false
  }
}

const inputCls =
  'h-10 w-full rounded-md border border-input bg-background px-3 text-sm focus:outline-none focus:ring-2 focus:ring-ring'
const labelCls = 'text-sm font-medium'
const errCls = 'text-xs text-destructive mt-1'
</script>

<template>
  <form class="space-y-4" @submit.prevent="onSubmit">
    <!-- Type toggle -->
    <div class="grid grid-cols-3 gap-1 rounded-md bg-muted p-1 text-sm">
      <button
        type="button"
        class="h-8 rounded"
        :class="type === 'expense' ? 'bg-background shadow-sm' : 'text-muted-foreground'"
        @click="type = 'expense'"
      >
        Výdavok
      </button>
      <button
        type="button"
        class="h-8 rounded"
        :class="type === 'income' ? 'bg-background shadow-sm' : 'text-muted-foreground'"
        @click="type = 'income'"
      >
        Príjem
      </button>
      <button
        type="button"
        class="h-8 rounded"
        :class="type === 'transfer' ? 'bg-background shadow-sm' : 'text-muted-foreground'"
        @click="type = 'transfer'"
      >
        Prevod
      </button>
    </div>

    <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
      <div>
        <label :class="labelCls" for="t-amount">Suma (EUR)</label>
        <input
          id="t-amount"
          v-model="amountInput"
          inputmode="decimal"
          placeholder="0,00"
          :class="inputCls"
        />
        <p v-if="errors.amount" :class="errCls">{{ errors.amount }}</p>
      </div>
      <div>
        <label :class="labelCls" for="t-date">Dátum</label>
        <input id="t-date" v-model="date" type="date" :class="inputCls" />
        <p v-if="errors.date" :class="errCls">{{ errors.date }}</p>
      </div>
    </div>

    <div>
      <label :class="labelCls" for="t-account">{{
        type === 'transfer' ? 'Z účtu' : 'Účet'
      }}</label>
      <select id="t-account" v-model="accountId" :class="inputCls">
        <option value="" disabled>— vyber —</option>
        <option v-for="a in accounts.active" :key="a.id" :value="a.id">{{ a.name }}</option>
      </select>
      <p v-if="errors.account_id" :class="errCls">{{ errors.account_id }}</p>
    </div>

    <div v-if="type === 'transfer'">
      <label :class="labelCls" for="t-to-account">Na účet</label>
      <select id="t-to-account" v-model="transferToAccountId" :class="inputCls">
        <option :value="null" disabled>— vyber —</option>
        <option
          v-for="a in accounts.active.filter((x) => x.id !== accountId)"
          :key="a.id"
          :value="a.id"
        >
          {{ a.name }}
        </option>
      </select>
      <p v-if="errors.transfer_to_account_id" :class="errCls">
        {{ errors.transfer_to_account_id }}
      </p>
    </div>

    <div v-else>
      <label :class="labelCls" for="t-category">Kategória</label>
      <select id="t-category" v-model="categoryId" :class="inputCls">
        <option :value="null" disabled>— vyber —</option>
        <option v-for="c in categoryOptions" :key="c.id" :value="c.id">{{ c.name }}</option>
      </select>
      <p v-if="errors.category_id" :class="errCls">{{ errors.category_id }}</p>
    </div>

    <div>
      <label :class="labelCls" for="t-description">Popis</label>
      <input
        id="t-description"
        v-model="description"
        :class="inputCls"
        placeholder="napr. Billa nákup"
      />
    </div>

    <div>
      <label :class="labelCls" for="t-note">Poznámka</label>
      <textarea
        id="t-note"
        v-model="note"
        rows="2"
        class="w-full rounded-md border border-input bg-background p-3 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
      />
    </div>

    <p v-if="errors.form" class="text-sm text-destructive">{{ errors.form }}</p>

    <div class="flex justify-end gap-2 pt-2">
      <button
        type="button"
        class="h-10 px-4 rounded-md text-sm text-muted-foreground hover:bg-accent"
        @click="emit('cancel')"
      >
        Zrušiť
      </button>
      <button
        type="submit"
        :disabled="submitting"
        class="h-10 px-4 rounded-md bg-primary text-primary-foreground text-sm font-medium hover:opacity-90 disabled:opacity-50"
      >
        {{ submitting ? '...' : props.initial ? 'Uložiť' : 'Pridať' }}
      </button>
    </div>
  </form>
</template>
