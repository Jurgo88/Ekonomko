// Doménové TS typy — zrkadlia Supabase tabuľky z migrácie 0001.
// Neskôr (voliteľne) ich môžeš nahradiť generovanými typmi v database.ts.

export type HouseholdRole = 'owner' | 'admin' | 'member'

export type AccountType =
  | 'checking'
  | 'savings'
  | 'cash'
  | 'credit_card'
  | 'investment'
  | 'other'

export type CategoryType = 'income' | 'expense'

export type TransactionType = 'income' | 'expense' | 'transfer'

export type RecurringFrequency = 'daily' | 'weekly' | 'monthly' | 'yearly'

export type BudgetPeriod = 'monthly' | 'yearly'

export interface Household {
  id: string
  name: string
  currency: string
  created_at: string
  created_by: string | null
}

export interface HouseholdMember {
  household_id: string
  user_id: string
  role: HouseholdRole
  joined_at: string
}

export interface Account {
  id: string
  household_id: string
  name: string
  type: AccountType
  currency: string
  initial_balance: number
  color: string | null
  icon: string | null
  is_archived: boolean
  display_order: number
  created_at: string
}

export interface Category {
  id: string
  household_id: string
  name: string
  type: CategoryType
  color: string | null
  icon: string | null
  parent_id: string | null
  is_archived: boolean
  display_order: number
  created_at: string
}

export interface Transaction {
  id: string
  household_id: string
  account_id: string
  category_id: string | null
  type: TransactionType
  amount: number
  currency: string
  date: string // ISO date: YYYY-MM-DD
  description: string | null
  note: string | null
  transfer_to_account_id: string | null
  recurring_template_id: string | null
  created_by: string | null
  created_at: string
  updated_at: string
}

export interface RecurringTemplate {
  id: string
  household_id: string
  account_id: string
  category_id: string | null
  type: TransactionType
  amount: number
  currency: string
  description: string | null
  frequency: RecurringFrequency
  interval_count: number
  start_date: string
  end_date: string | null
  next_occurrence: string | null
  is_active: boolean
  created_at: string
}

export interface Budget {
  id: string
  household_id: string
  category_id: string
  amount: number
  period: BudgetPeriod
  start_date: string
  end_date: string | null
  created_at: string
}
