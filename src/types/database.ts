// ============================================================
// Ručne písaný Database typ zodpovedajúci migráciám 0001-0004.
// Tvar je kompatibilný s `supabase gen types typescript`, takže
// ho neskôr môžeš nahradiť vygenerovaným súborom bez zmeny kódu.
// ============================================================

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

// --- pomocné literal typy ---------------------------------------------------
type HouseholdRole = 'owner' | 'admin' | 'member'
type AccountType =
  | 'checking'
  | 'savings'
  | 'cash'
  | 'credit_card'
  | 'investment'
  | 'other'
type CategoryType = 'income' | 'expense'
type TransactionType = 'income' | 'expense' | 'transfer'
type RecurringFrequency = 'daily' | 'weekly' | 'monthly' | 'yearly'
type BudgetPeriod = 'monthly' | 'yearly'

// ---------------------------------------------------------------------------
export interface Database {
  public: {
    Tables: {
      households: {
        Row: {
          id: string
          name: string
          currency: string
          created_at: string
          created_by: string | null
        }
        Insert: {
          id?: string
          name: string
          currency?: string
          created_at?: string
          created_by?: string | null
        }
        Update: {
          id?: string
          name?: string
          currency?: string
          created_at?: string
          created_by?: string | null
        }
        Relationships: []
      }
      household_members: {
        Row: {
          household_id: string
          user_id: string
          role: HouseholdRole
          joined_at: string
        }
        Insert: {
          household_id: string
          user_id: string
          role: HouseholdRole
          joined_at?: string
        }
        Update: {
          household_id?: string
          user_id?: string
          role?: HouseholdRole
          joined_at?: string
        }
        Relationships: [
          {
            foreignKeyName: 'household_members_household_id_fkey'
            columns: ['household_id']
            referencedRelation: 'households'
            referencedColumns: ['id']
          },
        ]
      }
      accounts: {
        Row: {
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
        Insert: {
          id?: string
          household_id: string
          name: string
          type: AccountType
          currency?: string
          initial_balance?: number
          color?: string | null
          icon?: string | null
          is_archived?: boolean
          display_order?: number
          created_at?: string
        }
        Update: {
          id?: string
          household_id?: string
          name?: string
          type?: AccountType
          currency?: string
          initial_balance?: number
          color?: string | null
          icon?: string | null
          is_archived?: boolean
          display_order?: number
          created_at?: string
        }
        Relationships: [
          {
            foreignKeyName: 'accounts_household_id_fkey'
            columns: ['household_id']
            referencedRelation: 'households'
            referencedColumns: ['id']
          },
        ]
      }
      categories: {
        Row: {
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
        Insert: {
          id?: string
          household_id: string
          name: string
          type: CategoryType
          color?: string | null
          icon?: string | null
          parent_id?: string | null
          is_archived?: boolean
          display_order?: number
          created_at?: string
        }
        Update: {
          id?: string
          household_id?: string
          name?: string
          type?: CategoryType
          color?: string | null
          icon?: string | null
          parent_id?: string | null
          is_archived?: boolean
          display_order?: number
          created_at?: string
        }
        Relationships: [
          {
            foreignKeyName: 'categories_household_id_fkey'
            columns: ['household_id']
            referencedRelation: 'households'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'categories_parent_id_fkey'
            columns: ['parent_id']
            referencedRelation: 'categories'
            referencedColumns: ['id']
          },
        ]
      }
      transactions: {
        Row: {
          id: string
          household_id: string
          account_id: string
          category_id: string | null
          type: TransactionType
          amount: number
          currency: string
          date: string
          description: string | null
          note: string | null
          transfer_to_account_id: string | null
          recurring_template_id: string | null
          created_by: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          household_id: string
          account_id: string
          category_id?: string | null
          type: TransactionType
          amount: number
          currency?: string
          date: string
          description?: string | null
          note?: string | null
          transfer_to_account_id?: string | null
          recurring_template_id?: string | null
          created_by?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          household_id?: string
          account_id?: string
          category_id?: string | null
          type?: TransactionType
          amount?: number
          currency?: string
          date?: string
          description?: string | null
          note?: string | null
          transfer_to_account_id?: string | null
          recurring_template_id?: string | null
          created_by?: string | null
          created_at?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: 'transactions_household_id_fkey'
            columns: ['household_id']
            referencedRelation: 'households'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'transactions_account_id_fkey'
            columns: ['account_id']
            referencedRelation: 'accounts'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'transactions_category_id_fkey'
            columns: ['category_id']
            referencedRelation: 'categories'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'transactions_transfer_to_account_id_fkey'
            columns: ['transfer_to_account_id']
            referencedRelation: 'accounts'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'fk_transactions_recurring_template'
            columns: ['recurring_template_id']
            referencedRelation: 'recurring_templates'
            referencedColumns: ['id']
          },
        ]
      }
      recurring_templates: {
        Row: {
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
        Insert: {
          id?: string
          household_id: string
          account_id: string
          category_id?: string | null
          type: TransactionType
          amount: number
          currency?: string
          description?: string | null
          frequency: RecurringFrequency
          interval_count?: number
          start_date: string
          end_date?: string | null
          next_occurrence?: string | null
          is_active?: boolean
          created_at?: string
        }
        Update: {
          id?: string
          household_id?: string
          account_id?: string
          category_id?: string | null
          type?: TransactionType
          amount?: number
          currency?: string
          description?: string | null
          frequency?: RecurringFrequency
          interval_count?: number
          start_date?: string
          end_date?: string | null
          next_occurrence?: string | null
          is_active?: boolean
          created_at?: string
        }
        Relationships: [
          {
            foreignKeyName: 'recurring_templates_household_id_fkey'
            columns: ['household_id']
            referencedRelation: 'households'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'recurring_templates_account_id_fkey'
            columns: ['account_id']
            referencedRelation: 'accounts'
            referencedColumns: ['id']
          },
        ]
      }
      budgets: {
        Row: {
          id: string
          household_id: string
          category_id: string
          amount: number
          period: BudgetPeriod
          start_date: string
          end_date: string | null
          created_at: string
        }
        Insert: {
          id?: string
          household_id: string
          category_id: string
          amount: number
          period: BudgetPeriod
          start_date: string
          end_date?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          household_id?: string
          category_id?: string
          amount?: number
          period?: BudgetPeriod
          start_date?: string
          end_date?: string | null
          created_at?: string
        }
        Relationships: [
          {
            foreignKeyName: 'budgets_household_id_fkey'
            columns: ['household_id']
            referencedRelation: 'households'
            referencedColumns: ['id']
          },
          {
            foreignKeyName: 'budgets_category_id_fkey'
            columns: ['category_id']
            referencedRelation: 'categories'
            referencedColumns: ['id']
          },
        ]
      }
    }
    Views: Record<string, never>
    Functions: {
      seed_default_categories: {
        Args: { p_household_id: string }
        Returns: undefined
      }
      user_household_ids: {
        Args: Record<string, never>
        Returns: string[]
      }
    }
    Enums: Record<string, never>
    CompositeTypes: Record<string, never>
  }
}
