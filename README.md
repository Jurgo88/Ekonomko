# Ekonomko

Web + PWA aplikácia na sledovanie rodinného rozpočtu — príjmy, výdavky, účty, kategórie, opakované platby, mesačné rozpočty a štatistiky s grafmi. Slovenské UI, podpora viacerých domácností s RLS izoláciou.

Stack: **Vue 3 + TypeScript + Vite** (Composition API, `<script setup>`), **Pinia**, **Vue Router**, **Supabase** (Postgres + Auth + RLS), **Tailwind CSS** + shadcn-vue tokeny, **ECharts** (vue-echarts), **TanStack Vue Table**, **Zod**, **date-fns**, **vite-plugin-pwa**. Hosting na Netlify.

## Rýchly prehľad štruktúry

```
src/
  assets/            globálne CSS (Tailwind + CSS premenné tém)
  components/
    charts/          CategoryPieChart, MonthlyBarChart
    layout/          AppShell, Sidebar, MobileNav
    pwa/             PwaUpdatePrompt (toast pri novej verzii)
    transactions/    TransactionForm (+ validácia cez Zod)
  composables/       useBudgetStats atď.
  lib/               supabase, echarts, money, date, utils, validators
  router/            routes + auth guard
  stores/            Pinia: auth, household, accounts, categories, transactions
  types/             database (generovateľný), models (doménové typy)
  views/             Login, Dashboard, Transactions, (atď.)
  pwa.ts             registrácia SW + update toast state
supabase/
  migrations/        0001 schéma, 0002 seed_categories RPC, 0003 RLS + households trigger
  seed/              bootstrap.sql, sample_transactions.sql
public/
  favicon.svg        brand favicon
  icons/             PWA ikony (any 192/512, maskable 512, apple-touch)
  offline.html       offline fallback stránka
```

## Lokálny vývoj

Predpoklad: **Node 20+** a **npm**.

```bash
# 1) klonuj a nainštaluj
npm install

# 2) skopíruj .env a doplň vlastné Supabase credentials
cp .env.example .env.development
# uprav VITE_SUPABASE_URL a VITE_SUPABASE_ANON_KEY

# 3) dev server
npm run dev       # http://localhost:5173

# 4) produkčný build + local preview (otestuj PWA)
npm run build
npm run preview   # http://localhost:4173

# 5) iba TypeScript check
npm run type-check
```

Service worker je v dev-e **vypnutý** (cleaner vývoj). PWA správanie testuj cez `npm run build && npm run preview`.

## Supabase — one-time setup

1. Vytvor projekt na [supabase.com](https://supabase.com). Skopíruj `Project URL` a `anon public key`.
2. V SQL editore postupne spusti migrácie v tomto poradí:
   - `supabase/migrations/0001_initial_schema.sql` — tabuľky, indexy, trigger `set_updated_at`
   - `supabase/migrations/0002_seed_categories.sql` — RPC `seed_default_categories`
   - `supabase/migrations/0003_rls_policies.sql` — RLS politiky, helper `user_household_ids` a trigger `households_set_created_by`
3. V **Authentication → Providers** zapni `Email` (heslo). Vypni `Confirm email`, ak chceš zjednodušiť dev registráciu.
4. V aplikácii sa zaregistruj cez `/login` — onboarding (vytvorenie domácnosti, členstva, default účtu a kategórií) beží automaticky po prvom prihlásení.
5. (Voliteľne) Seed ukážkové dáta:
   - Najprv `supabase/seed/bootstrap.sql` (idempotentný, zaistí household/account/kategórie pre prvého auth usera).
   - Potom `supabase/seed/sample_transactions.sql` (~82 transakcií za 6 mesiacov).

### Regenerácia TypeScript typov (voliteľné)

`src/types/database.ts` je ručne napísaný a zrkadlí migrácie. Ak zmeníš schému, môžeš ho znovu-vygenerovať cez Supabase CLI:

```bash
npx supabase gen types typescript --project-id <your-ref> > src/types/database.ts
```

## Deploy na Netlify

### GitHub integration (odporúčané)

1. Pushni repo na GitHub.
2. V Netlify → **Add new site → Import an existing project → GitHub**, vyber repo.
3. Build settings sú v `netlify.toml`, nemusíš nič meniť:
   - Build command: `npm run build`
   - Publish directory: `dist`
   - Node version: `20`
4. V **Site configuration → Environment variables** pridaj:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
5. Deploy. Každý push na `main` spustí nový build.

### Netlify CLI (alternatíva)

```bash
npm i -g netlify-cli
netlify login
netlify init       # prepojí lokálny projekt so Netlify site-om
netlify env:set VITE_SUPABASE_URL "https://your-ref.supabase.co"
netlify env:set VITE_SUPABASE_ANON_KEY "your-anon-key"
netlify deploy --prod
```

### Čo `netlify.toml` rieši

- **SPA fallback**: `/* → /index.html` (inak by deep-linky vracali 404).
- **Service worker**: `/sw.js` s `Cache-Control: no-cache` — inak by sa zasekla stará verzia v cache CDN-u.
- **Hashed assety**: `/assets/*` s `max-age=31536000, immutable`.
- **Security headers**: `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, `Permissions-Policy` (bez FLoC cohort).

## Po deploy-i — smoke checklist

- `/login` sa otvorí a registrácia funguje
- po prihlásení sa zobrazí dashboard (prípadne prázdny)
- pridanie transakcie cez `/transactions?new=1` uloží záznam a objaví sa v tabuľke
- dashboard KPI karty a oba grafy reagujú na nové dáta
- Chrome DevTools → *Application → Manifest*: ikony 192/512 + maskable viditeľné, shortcut-y prítomné
- *Application → Service Workers*: SW aktívny, `navigateFallback: /offline.html`
- inštalačná ikonka v omniboxe → nainštaluj ako PWA → okno má vlastnú app-chrome
- v *Network* simuluj *Offline* a preloaduj → zobrazí sa `offline.html`

## PWA caveaty

- iOS: "Pridať na plochu" v Safari, no push/background sync chýbajú (limit iOS).
- Deploy novej verzie → users dostanú toast "Dostupná nová verzia" pri ďalšej návšteve (nie automatický reload — `skipWaiting: false`).
- Dáta Supabase sa cacheujú NetworkFirst s 10-min TTL; keď si offline, dashboard ti ukáže posledné stiahnuté dáta.

## Časté problémy

**`new row violates row-level security policy for table 'households'`** — `0003` sa neaplikoval kompletne (chýba trigger `households_set_created_by` alebo insert policy `to authenticated`). Spusti `0003_rls_policies.sql` znovu — je idempotentný.

**`Chýba domácnosť alebo účet`** pri sample skripte — spusti najprv `supabase/seed/bootstrap.sql`.

**TypeScript errory typu `Property 'id' does not exist on type 'never'`** — `src/types/database.ts` je v placeholder tvare. Použi aktuálnu verziu zo zdroj. kontroly (obsahuje celý `Database` typ), alebo ho regeneruj cez Supabase CLI.

**Dev SW sa zasekol** — DevTools → *Application → Service Workers → Unregister*, potom hard refresh (Cmd+Shift+R / Ctrl+Shift+R).

## Licencia

Súkromný projekt. Ak by si chcel fork-nuť, daj vedieť.
