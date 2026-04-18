-- ============================================================
-- sample_transactions.sql
--
-- Jednorazový seed vzorových transakcií pre rýchle naplnenie
-- dashboardu. Spusti v Supabase SQL Editore (beží ako postgres
-- role, takže ignoruje RLS).
--
-- Skript automaticky nájde najstaršiu domácnosť v DB a jej prvý
-- účet (podľa display_order). Ak už nejaké transakcie máš, tieto
-- sa len pridajú — nemaže nič existujúce.
--
-- Rozsah: 6 mesiacov (november 2025 – apríl 2026), ~80 záznamov.
-- Slovenská rodina, mesačný plat ~1600 EUR, bežné životné náklady.
-- ============================================================

DO $$
DECLARE
  v_hh  uuid;
  v_acc uuid;
BEGIN
  SELECT id INTO v_hh  FROM public.households ORDER BY created_at LIMIT 1;
  SELECT id INTO v_acc FROM public.accounts WHERE household_id = v_hh ORDER BY display_order LIMIT 1;

  IF v_hh IS NULL OR v_acc IS NULL THEN
    RAISE EXCEPTION 'Chýba domácnosť alebo účet. Najprv sa prihlás v appke, nech beží onboarding.';
  END IF;

  -- Helper lookup: id(name, type)
  -- Používame inline subquery — malý zoznam, prehľadné.

  INSERT INTO public.transactions
    (household_id, account_id, category_id, type, amount, currency, date, description)
  VALUES
    -- ============ NOVEMBER 2025 ============
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Mzda'            AND type = 'income' ), 'income',  1580.00, 'EUR', '2025-11-03', 'Výplata november'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Bývanie'         AND type = 'expense'), 'expense',  450.00, 'EUR', '2025-11-05', 'Nájom'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Energie'         AND type = 'expense'), 'expense',  125.30, 'EUR', '2025-11-10', 'Elektrina + plyn'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Internet a TV'   AND type = 'expense'), 'expense',   24.99, 'EUR', '2025-11-07', 'Telekom'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Mobil'           AND type = 'expense'), 'expense',   20.00, 'EUR', '2025-11-09', '4ka paušál'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Predplatné'      AND type = 'expense'), 'expense',   14.99, 'EUR', '2025-11-12', 'Netflix'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Potraviny'       AND type = 'expense'), 'expense',  112.50, 'EUR', '2025-11-08', 'Lidl'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Potraviny'       AND type = 'expense'), 'expense',   85.20, 'EUR', '2025-11-15', 'Billa'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Potraviny'       AND type = 'expense'), 'expense',   94.30, 'EUR', '2025-11-22', 'Tesco'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Reštaurácie'     AND type = 'expense'), 'expense',   42.00, 'EUR', '2025-11-14', 'Pizzeria'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Doprava-PHM'     AND type = 'expense'), 'expense',   75.00, 'EUR', '2025-11-11', 'Tankovanie'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Doprava-PHM'     AND type = 'expense'), 'expense',   68.50, 'EUR', '2025-11-25', 'Tankovanie'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Drogéria'        AND type = 'expense'), 'expense',   38.20, 'EUR', '2025-11-18', 'DM'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Kultúra'         AND type = 'expense'), 'expense',   24.00, 'EUR', '2025-11-20', 'Kino'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Sporenie'        AND type = 'expense'), 'expense',  100.00, 'EUR', '2025-11-28', 'Mesačné sporenie'),

    -- ============ DECEMBER 2025 ============
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Mzda'            AND type = 'income' ), 'income',  1620.00, 'EUR', '2025-12-02', 'Výplata december'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Odmeny'          AND type = 'income' ), 'income',   300.00, 'EUR', '2025-12-20', 'Vianočný bonus'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Bývanie'         AND type = 'expense'), 'expense',  450.00, 'EUR', '2025-12-04', 'Nájom'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Energie'         AND type = 'expense'), 'expense',  142.50, 'EUR', '2025-12-10', 'Elektrina + plyn'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Internet a TV'   AND type = 'expense'), 'expense',   24.99, 'EUR', '2025-12-07', 'Telekom'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Mobil'           AND type = 'expense'), 'expense',   20.00, 'EUR', '2025-12-09', '4ka paušál'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Predplatné'      AND type = 'expense'), 'expense',   14.99, 'EUR', '2025-12-12', 'Netflix'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Potraviny'       AND type = 'expense'), 'expense',  156.40, 'EUR', '2025-12-06', 'Lidl'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Potraviny'       AND type = 'expense'), 'expense',   92.80, 'EUR', '2025-12-13', 'Billa'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Potraviny'       AND type = 'expense'), 'expense',  178.30, 'EUR', '2025-12-20', 'Veľký nákup pred Vianocami'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Reštaurácie'     AND type = 'expense'), 'expense',   58.00, 'EUR', '2025-12-19', 'Vianočná večera v reštike'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Doprava-PHM'     AND type = 'expense'), 'expense',   72.00, 'EUR', '2025-12-12', 'Tankovanie'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Darčeky'         AND type = 'expense'), 'expense',  220.00, 'EUR', '2025-12-18', 'Vianočné darčeky'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Darčeky'         AND type = 'expense'), 'expense',   85.50, 'EUR', '2025-12-22', 'Darčeky pre rodičov'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Oblečenie'       AND type = 'expense'), 'expense',   95.00, 'EUR', '2025-12-08', 'Zimná bunda'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Kultúra'         AND type = 'expense'), 'expense',   35.00, 'EUR', '2025-12-29', 'Silvestrovský koncert'),

    -- ============ JANUARY 2026 ============
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Mzda'            AND type = 'income' ), 'income',  1650.00, 'EUR', '2026-01-05', 'Výplata január'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Bývanie'         AND type = 'expense'), 'expense',  450.00, 'EUR', '2026-01-05', 'Nájom'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Energie'         AND type = 'expense'), 'expense',  160.00, 'EUR', '2026-01-10', 'Elektrina + plyn (zima)'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Internet a TV'   AND type = 'expense'), 'expense',   24.99, 'EUR', '2026-01-07', 'Telekom'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Mobil'           AND type = 'expense'), 'expense',   20.00, 'EUR', '2026-01-09', '4ka paušál'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Predplatné'      AND type = 'expense'), 'expense',   14.99, 'EUR', '2026-01-12', 'Netflix'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Potraviny'       AND type = 'expense'), 'expense',  105.60, 'EUR', '2026-01-08', 'Lidl'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Potraviny'       AND type = 'expense'), 'expense',  122.40, 'EUR', '2026-01-15', 'Kaufland'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Potraviny'       AND type = 'expense'), 'expense',   98.90, 'EUR', '2026-01-22', 'Tesco'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Reštaurácie'     AND type = 'expense'), 'expense',   36.50, 'EUR', '2026-01-17', 'Obed s kolegami'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Doprava-PHM'     AND type = 'expense'), 'expense',   71.00, 'EUR', '2026-01-14', 'Tankovanie'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Zdravie'         AND type = 'expense'), 'expense',   45.00, 'EUR', '2026-01-20', 'Zubár'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Lieky'           AND type = 'expense'), 'expense',   22.50, 'EUR', '2026-01-20', 'Lekáreň'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Šport'           AND type = 'expense'), 'expense',   40.00, 'EUR', '2026-01-11', 'Lyžiarsky vlek'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Sporenie'        AND type = 'expense'), 'expense',  150.00, 'EUR', '2026-01-28', 'Mesačné sporenie'),

    -- ============ FEBRUARY 2026 ============
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Mzda'            AND type = 'income' ), 'income',  1650.00, 'EUR', '2026-02-03', 'Výplata február'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Bývanie'         AND type = 'expense'), 'expense',  450.00, 'EUR', '2026-02-05', 'Nájom'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Energie'         AND type = 'expense'), 'expense',  155.80, 'EUR', '2026-02-10', 'Elektrina + plyn'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Internet a TV'   AND type = 'expense'), 'expense',   24.99, 'EUR', '2026-02-07', 'Telekom'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Mobil'           AND type = 'expense'), 'expense',   20.00, 'EUR', '2026-02-09', '4ka paušál'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Predplatné'      AND type = 'expense'), 'expense',   14.99, 'EUR', '2026-02-12', 'Netflix'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Potraviny'       AND type = 'expense'), 'expense',  115.30, 'EUR', '2026-02-06', 'Lidl'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Potraviny'       AND type = 'expense'), 'expense',   89.20, 'EUR', '2026-02-14', 'Billa'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Potraviny'       AND type = 'expense'), 'expense',  102.50, 'EUR', '2026-02-21', 'Tesco'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Reštaurácie'     AND type = 'expense'), 'expense',   68.00, 'EUR', '2026-02-14', 'Valentínska večera'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Doprava-PHM'     AND type = 'expense'), 'expense',   78.00, 'EUR', '2026-02-13', 'Tankovanie'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Doprava-PHM'     AND type = 'expense'), 'expense',   70.50, 'EUR', '2026-02-25', 'Tankovanie'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Oblečenie'       AND type = 'expense'), 'expense',  120.00, 'EUR', '2026-02-18', 'Topánky'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Drogéria'        AND type = 'expense'), 'expense',   41.60, 'EUR', '2026-02-11', 'DM'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Sporenie'        AND type = 'expense'), 'expense',  150.00, 'EUR', '2026-02-26', 'Mesačné sporenie'),

    -- ============ MARCH 2026 ============
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Mzda'            AND type = 'income' ), 'income',  1650.00, 'EUR', '2026-03-03', 'Výplata marec'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Bývanie'         AND type = 'expense'), 'expense',  450.00, 'EUR', '2026-03-05', 'Nájom'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Energie'         AND type = 'expense'), 'expense',  132.40, 'EUR', '2026-03-10', 'Elektrina + plyn'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Internet a TV'   AND type = 'expense'), 'expense',   24.99, 'EUR', '2026-03-07', 'Telekom'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Mobil'           AND type = 'expense'), 'expense',   20.00, 'EUR', '2026-03-09', '4ka paušál'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Predplatné'      AND type = 'expense'), 'expense',   14.99, 'EUR', '2026-03-12', 'Netflix'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Poistenie'       AND type = 'expense'), 'expense',  180.00, 'EUR', '2026-03-15', 'Poistka auta'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Potraviny'       AND type = 'expense'), 'expense',  108.70, 'EUR', '2026-03-04', 'Lidl'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Potraviny'       AND type = 'expense'), 'expense',  125.50, 'EUR', '2026-03-11', 'Kaufland'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Potraviny'       AND type = 'expense'), 'expense',   97.80, 'EUR', '2026-03-18', 'Tesco'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Reštaurácie'     AND type = 'expense'), 'expense',   52.00, 'EUR', '2026-03-22', 'Nedeľný obed'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Doprava-PHM'     AND type = 'expense'), 'expense',   74.00, 'EUR', '2026-03-12', 'Tankovanie'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Servis auta'     AND type = 'expense'), 'expense',   95.00, 'EUR', '2026-03-24', 'Výmena oleja'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Kultúra'         AND type = 'expense'), 'expense',   30.00, 'EUR', '2026-03-20', 'Divadlo'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Sporenie'        AND type = 'expense'), 'expense',  150.00, 'EUR', '2026-03-28', 'Mesačné sporenie'),

    -- ============ APRIL 2026 (do 18.4.) ============
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Mzda'            AND type = 'income' ), 'income',  1670.00, 'EUR', '2026-04-02', 'Výplata apríl'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Bývanie'         AND type = 'expense'), 'expense',  450.00, 'EUR', '2026-04-05', 'Nájom'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Energie'         AND type = 'expense'), 'expense',  118.50, 'EUR', '2026-04-10', 'Elektrina + plyn'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Internet a TV'   AND type = 'expense'), 'expense',   24.99, 'EUR', '2026-04-07', 'Telekom'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Mobil'           AND type = 'expense'), 'expense',   20.00, 'EUR', '2026-04-09', '4ka paušál'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Predplatné'      AND type = 'expense'), 'expense',   14.99, 'EUR', '2026-04-12', 'Netflix'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Potraviny'       AND type = 'expense'), 'expense',  112.80, 'EUR', '2026-04-06', 'Lidl'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Potraviny'       AND type = 'expense'), 'expense',   98.50, 'EUR', '2026-04-13', 'Billa'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Reštaurácie'     AND type = 'expense'), 'expense',   48.00, 'EUR', '2026-04-11', 'Pizzeria'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Doprava-PHM'     AND type = 'expense'), 'expense',   72.00, 'EUR', '2026-04-08', 'Tankovanie'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Drogéria'        AND type = 'expense'), 'expense',   36.80, 'EUR', '2026-04-14', 'DM'),
    (v_hh, v_acc, (SELECT id FROM public.categories WHERE household_id = v_hh AND name = 'Kultúra'         AND type = 'expense'), 'expense',   28.00, 'EUR', '2026-04-17', 'Kino');

  RAISE NOTICE 'Seed done. Household %, account %.', v_hh, v_acc;
END $$;
