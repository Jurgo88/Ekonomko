import { createClient, type SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '@/types/database'

const url = import.meta.env.VITE_SUPABASE_URL
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!url || !anonKey) {
  // Vyhodíme zrozumiteľnú chybu — ľahšie sa to odhalí než "undefined" pri requeste
  throw new Error(
    'Chýbajú Supabase env premenné. Skontroluj VITE_SUPABASE_URL a VITE_SUPABASE_ANON_KEY v .env.development',
  )
}

export const supabase: SupabaseClient<Database> = createClient<Database>(url, anonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
})
