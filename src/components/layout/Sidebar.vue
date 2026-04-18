<script setup lang="ts">
import { RouterLink } from 'vue-router'
import {
  LayoutDashboard,
  ArrowLeftRight,
  Tags,
  PiggyBank,
  Wallet,
  Settings,
  LogOut,
  Sun,
  Moon,
} from 'lucide-vue-next'
import { useTheme } from '@/composables/useTheme'
import { useAuth } from '@/composables/useAuth'
import { useRouter } from 'vue-router'

const { isDark, toggleDark } = useTheme()

const { user, signOut } = useAuth()
const router = useRouter()

const navItems = [
  { to: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { to: '/transactions', label: 'Transakcie', icon: ArrowLeftRight },
  { to: '/categories', label: 'Kategórie', icon: Tags },
  { to: '/budgets', label: 'Rozpočty', icon: PiggyBank },
  { to: '/accounts', label: 'Účty', icon: Wallet },
  { to: '/settings', label: 'Nastavenia', icon: Settings },
]

async function onLogout() {
  await signOut()
  router.replace({ name: 'login' })
}
</script>

<template>
  <aside
    class="hidden md:flex md:w-60 lg:w-64 shrink-0 flex-col border-r bg-card text-card-foreground"
  >
    <div class="px-5 py-5 border-b">
      <h1 class="text-lg font-semibold tracking-tight">Ekonomko</h1>
      <p class="text-xs text-muted-foreground mt-0.5">Rodinné financie</p>
    </div>

    <nav class="flex-1 overflow-y-auto p-3 space-y-1">
      <RouterLink
        v-for="item in navItems"
        :key="item.to"
        :to="item.to"
        class="flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium text-muted-foreground hover:bg-accent hover:text-accent-foreground"
        active-class="bg-accent text-accent-foreground"
      >
        <component :is="item.icon" class="h-4 w-4" />
        {{ item.label }}
      </RouterLink>
    </nav>

    <div class="border-t p-3 space-y-1">
      <p class="px-2 text-xs text-muted-foreground truncate" :title="user?.email ?? ''">
        {{ user?.email }}
      </p>
      <button
        type="button"
        class="flex w-full items-center gap-2 rounded-md px-3 py-2 text-sm text-muted-foreground hover:bg-accent hover:text-accent-foreground"
        @click="toggleDark"
      >
        <Sun v-if="isDark" class="h-4 w-4" />
        <Moon v-else class="h-4 w-4" />
        {{ isDark ? 'Svetlý režim' : 'Tmavý režim' }}
      </button>
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
</template>
