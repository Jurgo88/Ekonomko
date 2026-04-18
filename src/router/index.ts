import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const routes: RouteRecordRaw[] = [
  {
    path: '/',
    redirect: '/dashboard',
  },
  {
    path: '/login',
    name: 'login',
    component: () => import('@/views/LoginView.vue'),
    meta: { public: true },
  },
  {
    path: '/dashboard',
    name: 'dashboard',
    component: () => import('@/views/DashboardView.vue'),
  },
  {
    path: '/transactions',
    name: 'transactions',
    component: () => import('@/views/TransactionsView.vue'),
  },
  {
    path: '/categories',
    name: 'categories',
    component: () => import('@/views/CategoriesView.vue'),
  },
  {
    path: '/budgets',
    name: 'budgets',
    component: () => import('@/views/BudgetsView.vue'),
  },
  {
    path: '/accounts',
    name: 'accounts',
    component: () => import('@/views/AccountsView.vue'),
  },
  {
    path: '/settings',
    name: 'settings',
    component: () => import('@/views/SettingsView.vue'),
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: '/dashboard',
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

// Auth guard: ak je route neverejný a user nie je prihlásený → /login.
// Ak je prihlásený a ide na /login, presmeruj na dashboard.
router.beforeEach(async (to) => {
  const auth = useAuthStore()

  // Pri prvom navigate môže ešte bežať init() — počkáme, kým doznie
  if (auth.loading) {
    await auth.init()
  }

  const isPublic = to.meta.public === true

  if (!isPublic && !auth.isAuthenticated) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }

  if (isPublic && auth.isAuthenticated && to.name === 'login') {
    return { name: 'dashboard' }
  }

  return true
})

export default router
