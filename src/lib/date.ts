import {
  format,
  parseISO,
  startOfMonth,
  endOfMonth,
  startOfYear,
  endOfYear,
  subMonths,
} from 'date-fns'
import { sk } from 'date-fns/locale'

// "15. 04. 2026" štýl — default pre zobrazenie transakcií
export function formatDate(date: Date | string, pattern = 'd. M. yyyy'): string {
  const d = typeof date === 'string' ? parseISO(date) : date
  return format(d, pattern, { locale: sk })
}

// "apríl 2026" — pre mesačné nadpisy
export function formatMonth(date: Date | string): string {
  const d = typeof date === 'string' ? parseISO(date) : date
  return format(d, 'LLLL yyyy', { locale: sk })
}

// DB-friendly ISO date (YYYY-MM-DD) — Postgres column `date`
export function toISODate(date: Date): string {
  return format(date, 'yyyy-MM-dd')
}

export function startOfCurrentMonth(): Date {
  return startOfMonth(new Date())
}

export function endOfCurrentMonth(): Date {
  return endOfMonth(new Date())
}

export interface DateRange {
  start: Date
  end: Date
}

// Rozsah pre ľubovoľný mesiac (default aktuálny)
export function getMonthRange(date: Date = new Date()): DateRange {
  return { start: startOfMonth(date), end: endOfMonth(date) }
}

// Rozsah pre ľubovoľný rok (default aktuálny) — užitočné pre ročné rozpočty
export function getYearRange(date: Date = new Date()): DateRange {
  return { start: startOfYear(date), end: endOfYear(date) }
}

// Posledných N mesiacov ako pole {start, end, label} — pre stĺpcový graf
export function getLastMonths(count: number): { start: Date; end: Date; label: string }[] {
  const now = new Date()
  const out: { start: Date; end: Date; label: string }[] = []
  for (let i = count - 1; i >= 0; i--) {
    const m = subMonths(now, i)
    out.push({
      start: startOfMonth(m),
      end: endOfMonth(m),
      label: format(m, 'LLL yyyy', { locale: sk }),
    })
  }
  return out
}
