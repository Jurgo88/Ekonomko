<script setup lang="ts">
import {
  needRefresh,
  offlineReady,
  applyUpdate,
  dismissNeedRefresh,
  dismissOfflineReady,
} from '@/pwa'
</script>

<template>
  <!-- Update pripravený -->
  <Teleport to="body">
    <div
      v-if="needRefresh"
      class="fixed inset-x-0 bottom-4 z-[60] mx-auto flex max-w-sm items-center gap-3 rounded-lg border bg-card/95 px-4 py-3 shadow-lg backdrop-blur supports-[backdrop-filter]:bg-card/80"
      style="bottom: calc(env(safe-area-inset-bottom, 0) + 1rem)"
      role="status"
      aria-live="polite"
    >
      <div class="flex-1 text-sm">
        <p class="font-medium">Dostupná nová verzia</p>
        <p class="text-muted-foreground">Obnov, aby si dostal(a) najnovšie zmeny.</p>
      </div>
      <button
        class="rounded-md bg-primary px-3 py-1.5 text-sm font-medium text-primary-foreground hover:bg-primary/90"
        @click="applyUpdate"
      >
        Obnoviť
      </button>
      <button
        class="text-sm text-muted-foreground hover:text-foreground"
        aria-label="Zavrieť"
        @click="dismissNeedRefresh"
      >
        ✕
      </button>
    </div>

    <!-- Offline ready -->
    <div
      v-if="offlineReady && !needRefresh"
      class="fixed inset-x-0 bottom-4 z-[60] mx-auto flex max-w-sm items-center gap-3 rounded-lg border bg-card/95 px-4 py-3 shadow-lg backdrop-blur supports-[backdrop-filter]:bg-card/80"
      style="bottom: calc(env(safe-area-inset-bottom, 0) + 1rem)"
      role="status"
      aria-live="polite"
    >
      <div class="flex-1 text-sm">
        <p class="font-medium">Pripravené na offline</p>
        <p class="text-muted-foreground">Appka bude fungovať aj bez pripojenia.</p>
      </div>
      <button
        class="text-sm text-muted-foreground hover:text-foreground"
        aria-label="Zavrieť"
        @click="dismissOfflineReady"
      >
        ✕
      </button>
    </div>
  </Teleport>
</template>
