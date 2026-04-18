import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

// Klasický shadcn-vue helper: spojí triedy cez clsx + odstráni duplicity
// a konflikty cez tailwind-merge (napr. "px-2 px-4" → "px-4").
export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs))
}
