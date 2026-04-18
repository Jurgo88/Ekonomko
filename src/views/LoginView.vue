<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuth } from '@/composables/useAuth'

type Mode = 'login' | 'signup'

const mode = ref<Mode>('login')
const email = ref('')
const password = ref('')
const submitting = ref(false)
const successMessage = ref<string | null>(null)

const { signIn, signUp, error, clearError } = useAuth()
const router = useRouter()
const route = useRoute()

const title = computed(() => (mode.value === 'login' ? 'Prihlásenie' : 'Registrácia'))
const submitLabel = computed(() => (mode.value === 'login' ? 'Prihlásiť sa' : 'Zaregistrovať'))
const switchLabel = computed(() =>
  mode.value === 'login' ? 'Nemáš účet? Zaregistruj sa' : 'Už máš účet? Prihlás sa',
)

function switchMode() {
  mode.value = mode.value === 'login' ? 'signup' : 'login'
  clearError()
  successMessage.value = null
}

async function onSubmit() {
  if (submitting.value) return
  submitting.value = true
  successMessage.value = null
  try {
    if (mode.value === 'login') {
      await signIn(email.value.trim(), password.value)
      const redirect = typeof route.query.redirect === 'string' ? route.query.redirect : '/dashboard'
      router.replace(redirect)
    } else {
      await signUp(email.value.trim(), password.value)
      // Ak je "Confirm email" zapnuté, session nepríde — user musí potvrdiť mail.
      // Ak je vypnuté (typické pre dev), onAuthStateChange nás prihlási automaticky.
      successMessage.value =
        'Účet vytvorený. Ak je v Supabase zapnuté potvrdenie e-mailu, skontroluj schránku.'
    }
  } catch {
    // chyba sa už zobrazuje cez error zo store
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <section class="min-h-screen flex items-center justify-center p-4 bg-background">
    <div class="w-full max-w-sm space-y-6 rounded-lg border bg-card p-6 shadow-sm">
      <header class="space-y-1 text-center">
        <h1 class="text-2xl font-semibold tracking-tight">{{ title }}</h1>
        <p class="text-sm text-muted-foreground">Rodinný rozpočet</p>
      </header>

      <form class="space-y-4" @submit.prevent="onSubmit">
        <div class="space-y-1.5">
          <label for="email" class="text-sm font-medium">E-mail</label>
          <input
            id="email"
            v-model="email"
            type="email"
            autocomplete="email"
            required
            class="h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
            placeholder="tvoj@email.sk"
          />
        </div>

        <div class="space-y-1.5">
          <label for="password" class="text-sm font-medium">Heslo</label>
          <input
            id="password"
            v-model="password"
            type="password"
            :autocomplete="mode === 'login' ? 'current-password' : 'new-password'"
            required
            minlength="6"
            class="h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
            placeholder="aspoň 6 znakov"
          />
        </div>

        <p v-if="error" class="text-sm text-destructive">{{ error }}</p>
        <p v-if="successMessage" class="text-sm text-green-600 dark:text-green-400">
          {{ successMessage }}
        </p>

        <button
          type="submit"
          :disabled="submitting"
          class="h-10 w-full rounded-md bg-primary text-primary-foreground text-sm font-medium hover:opacity-90 disabled:opacity-50"
        >
          {{ submitting ? '...' : submitLabel }}
        </button>
      </form>

      <button
        type="button"
        class="w-full text-sm text-muted-foreground hover:text-foreground"
        @click="switchMode"
      >
        {{ switchLabel }}
      </button>
    </div>
  </section>
</template>
