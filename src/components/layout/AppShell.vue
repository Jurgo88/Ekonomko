<script setup lang="ts">
import { onMounted, ref } from 'vue'
import Sidebar from './Sidebar.vue'
import MobileNav from './MobileNav.vue'
import { useHouseholdStore } from '@/stores/household'
import { useAccountsStore } from '@/stores/accounts'
import { useCategoriesStore } from '@/stores/categories'
import { useTransactionsStore } from '@/stores/transactions'

const household = useHouseholdStore()
const accounts = useAccountsStore()
const categories = useCategoriesStore()
const transactions = useTransactionsStore()

const booting = ref(true)
const bootError = ref<string | null>(null)

onMounted(async () => {
  try {
    await household.ensureForCurrentUser()
    // Paralelne — sú nezávislé
    await Promise.all([accounts.fetch(), categories.fetch(), transactions.fetch()])
  } catch (e) {
    bootError.value = (e as Error).message
  } finally {
    booting.value = false
  }
})
</script>

<template>
  <div class="min-h-screen flex bg-background text-foreground">
    <Sidebar />

    <div class="flex-1 flex flex-col min-w-0">
      <main class="flex-1 overflow-x-hidden pb-20 md:pb-0">
        <div v-if="booting" class="p-6 text-sm text-muted-foreground">Pripravujem dáta...</div>
        <div v-else-if="bootError" class="p-6 text-sm text-destructive">
          Chyba pri načítaní: {{ bootError }}
        </div>
        <slot v-else />
      </main>
    </div>

    <MobileNav />
  </div>
</template>
