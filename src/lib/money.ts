// Formátovanie peňažných súm v slovenskom locale.

const defaultFormatter = new Intl.NumberFormat('sk-SK', {
  style: 'currency',
  currency: 'EUR',
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
})

// Cache formatterov pre iné meny — NumberFormat je drahý
const formatterCache = new Map<string, Intl.NumberFormat>()

function getFormatter(currency: string): Intl.NumberFormat {
  if (currency === 'EUR') return defaultFormatter
  let f = formatterCache.get(currency)
  if (!f) {
    f = new Intl.NumberFormat('sk-SK', {
      style: 'currency',
      currency,
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    })
    formatterCache.set(currency, f)
  }
  return f
}

export function formatMoney(amount: number | string | null | undefined, currency = 'EUR'): string {
  if (amount === null || amount === undefined || amount === '') return ''
  const n = typeof amount === 'string' ? Number(amount) : amount
  if (!Number.isFinite(n)) return ''
  return getFormatter(currency).format(n)
}

// Pre výpisy podľa typu transakcie — príjmy kladne, výdavky s mínusom
export function formatSigned(
  amount: number,
  type: 'income' | 'expense' | 'transfer',
  currency = 'EUR',
): string {
  const signed = type === 'expense' ? -Math.abs(amount) : Math.abs(amount)
  return formatMoney(signed, currency)
}

// Parse ručne zadanej sumy — akceptuje "," aj "." ako desatinnú čiarku
export function parseAmount(input: string): number | null {
  if (!input) return null
  const normalized = input.replace(/\s+/g, '').replace(',', '.')
  const n = Number(normalized)
  return Number.isFinite(n) ? n : null
}
