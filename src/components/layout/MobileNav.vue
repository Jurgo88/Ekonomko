<script setup lang="ts">
import { ref } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import {
  LayoutDashboard,
  ArrowLeftRight,
  Plus,
  BarChart3,
  Menu as MenuIcon,
  X,
  Tags,
  PiggyBank,
  Wallet,
  Settings,
  LogOut,
} from 'lucide-vue-next'
import { useAuth } from '@/composables/useAuth'

const { user, signOut } = useAuth()
const router = useRouter()

const menuOpen = ref(false)

// Rýchle pridanie transakcie — formulár spravíme v Kroku 7.
// Dovtedy to smeruje na /transactions s query, ktorý TransactionsView neskôr
// pochopí ako "otvor formulár".
function onAdd() {
  router.push({ path: '/transactions', query: { new: '1' } })
}

async function onLogout() {
  menuOpen.value = false
  await signOut()
  router.replace({ name: 'login' })
}

function closeMenu() {
  menuOpen.value = false
}

const drawerItems = [
  { to: '/categories', label: 'Kategórie', icon: Tags },
  { to: '/budgets', label: 'Rozpočty', icon: PiggyBank },
  { to: '/accounts', label: 'Účty', icon: Wallet },
  { to: '/settings', label: 'Nastavenia', icon: Settings },
]
</script>

<template>
  <!-- Bottom nav — mobile only -->
  <nav
    class="md:hidden fixed bottom-0 inset-x-0 z-30 border-t bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/75 pb-[env(safe-area-inset-bottom)]"
  >
    <div class="grid grid-cols-5 h-16">
      <RouterLink
        to="/dashboard"
        class="flex flex-col items-center justify-center gap-0.5 text-[11px] text-muted-foreground"
        active-class="text-foreground"
      >
        <LayoutDashboard class="h-5 w-5" />
        <span>Dashboard</span>
      </RouterLink>

      <RouterLink
        to="/transactions"
        class="flex flex-col items-center justify-center gap-0.5 text-[11px] text-muted-foreground"
        active-class="text-foreground"
      >
        <ArrowLeftRight class="h-5 w-5" />
        <span>Transakcie</span>
      </RouterLink>

      <button
        type="button"
        class="flex flex-col items-center justify-center"
        aria-label="Pridať transakciu"
        @click="onAdd"
      >
        <span
          class="flex h-11 w-11 items-center justify-center rounded-full bg-primary text-primary-foreground shadow-md -mt-5"
        >
          <Plus class="h-5 w-5" />
        </span>
      </button>

      <RouterLink
        to="/dashboard"
        class="flex flex-col items-center justify-center gap-0.5 text-[11px] text-muted-foreground"
      >
        <BarChart3 class="h-5 w-5" />
        <span>Grafy</span>
      </RouterLink>

      <button
        type="button"
        class="flex flex-col items-center justify-center gap-0.5 text-[11px] text-muted-foreground"
        :aria-expanded="menuOpen"
        @click="menuOpen = true"
      >
        <MenuIcon class="h-5 w-5" />
        <span>Menu</span>
      </button>
    </div>
  </nav>

  <!-- Drawer s ostatnými položkami -->
  <Teleport to="body">
    <div
      v-if="menuOpen"
      class="md:hidden fixed inset-0 z-40 bg-black/50"
      role="presentation"
      @click="closeMenu"
    />
    <aside
      v-if="menuOpen"
      class="md:hidden fixed inset-y-0 right-0 z-50 w-72 max-w-[85vw] bg-card text-card-foreground border-l shadow-xl flex flex-col"
    >
      <div class="flex items-center justify-between px-4 py-3 border-b">
        <h2 class="text-sm font-semibold">Menu</h2>
        <button
          type="button"
          class="p-2 -m-2 text-muted-foreground hover:text-foreground"
          aria-label="Zavrieť menu"
          @click="closeMenu"
        >
          <X class="h-5 w-5" />
        </button>
      </div>

      <nav class="flex-1 overflow-y-auto p-3 space-y-1">
        <RouterLink
          v-for="item in drawerItems"
          :key="item.to"
          :to="item.to"
          class="flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium text-muted-foreground hover:bg-accent hover:text-accent-foreground"
          active-class="bg-accent text-accent-foreground"
          @click="closeMenu"
        >
          <component :is="item.icon" class="h-4 w-4" />
          {{ item.label }}
        </RouterLink>
      </nav>

      <div class="border-t p-3 space-y-2">
        <p class="px-2 text-xs text-muted-foreground truncate" :title="user?.email ?? ''">
          {{ user?.email }}
        </p>
        <button
          type="button"
          class="flex w-full items-center gap-2 rounded-md px-3 py-2 text-sm text-muted-foreground hover:bg-accent hover:text-accent-foreground"
          @click="onLogout"
        >
          <LogOut class="h-4 w-4" />
          Odhlásiť sa
        </button>
      </div>
    </aside>
  </Teleport>
</template>
