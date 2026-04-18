import { z } from 'zod'

// Zod schéma pre formulár transakcie. Pravidlá:
//  - transfer vyžaduje transfer_to_account_id iný než account_id
//  - income/expense vyžaduje category_id
//  - amount > 0
export const transactionFormSchema = z
  .object({
    type: z.enum(['income', 'expense', 'transfer']),
    amount: z
      .number({ invalid_type_error: 'Zadaj sumu' })
      .positive('Suma musí byť väčšia ako 0'),
    date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Neplatný dátum'),
    account_id: z.string().uuid('Vyber účet'),
    category_id: z.string().uuid().nullable(),
    transfer_to_account_id: z.string().uuid().nullable(),
    description: z.string().max(200).nullable().optional().default(null),
    note: z.string().max(1000).nullable().optional().default(null),
    currency: z.string().length(3).default('EUR'),
  })
  .superRefine((val, ctx) => {
    if (val.type === 'transfer') {
      if (!val.transfer_to_account_id) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: 'Pri prevode vyber cieľový účet',
          path: ['transfer_to_account_id'],
        })
      } else if (val.transfer_to_account_id === val.account_id) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: 'Cieľový účet musí byť iný než zdrojový',
          path: ['transfer_to_account_id'],
        })
      }
    } else if (!val.category_id) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'Vyber kategóriu',
        path: ['category_id'],
      })
    }
  })

export type TransactionFormValues = z.infer<typeof transactionFormSchema>
