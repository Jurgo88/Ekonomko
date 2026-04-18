<script setup lang="ts">
import { computed } from 'vue'
import { RouterView, useRoute } from 'vue-router'
import AppShell from '@/components/layout/AppShell.vue'
import PwaUpdatePrompt from '@/components/pwa/PwaUpdatePrompt.vue'

const route = useRoute()

// Login (a iné public routes) rendrujú sa bez shellu
const usesShell = computed(() => route.meta.public !== true)
</script>

<template>
  <AppShell v-if="usesShell">
    <RouterView />
  </AppShell>
  <RouterView v-else />
  <PwaUpdatePrompt />
</template>
