-- ============================================================
-- bootstrap.sql
-- Ručné zaistenie domácnosti, členstva, default účtu a kategórií
-- pre prvého auth usera v DB. Idempotentné — spúšťaj bezpečne
-- viackrát. Spusti pred sample_transactions.sql ak onboarding
-- v appke z nejakého dôvodu neprebehol.
-- ============================================================

DO $$
DECLARE
  v_user      uuid;
  v_hh        uuid;
  v_acc       uuid;
  v_cat_count int;

  v_income_names text[] := ARRAY[
    'Mzda','Podnikanie','Odmeny','Rodičovský príspevok','Prídavky',
    'Prenájom','Investície','Dary','Iné'
  ];
  v_expense_names text[] := ARRAY[
    'Bývanie','Energie','Internet a TV','Potraviny','Reštaurácie',
    'Doprava-PHM','Doprava-MHD','Servis auta','Zdravie','Lieky',
    'Deti-škola','Deti-krúžky','Oblečenie','Drogéria','Predplatné',
    'Mobil','Dovolenky','Kultúra','Šport','Darčeky',
    'Poistenie','Sporenie','Splátky úverov','Bankové poplatky','Dane',
    'Domáce zvieratá','Iné'
  ];
  v_name text;
  v_i    int;
BEGIN
  -- 1) Auth user ----------------------------------------------
  SELECT id INTO v_user FROM auth.users ORDER BY created_at LIMIT 1;
  IF v_user IS NULL THEN
    RAISE EXCEPTION 'V auth.users nie je žiadny user. Najprv sa zaregistruj v appke.';
  END IF;
  RAISE NOTICE '[1/5] User: %', v_user;

  -- 2) Household ----------------------------------------------
  SELECT id INTO v_hh
  FROM public.households
  WHERE created_by = v_user
  ORDER BY created_at LIMIT 1;

  IF v_hh IS NULL THEN
    -- záloha cez members (pre prípad, že sa created_by nesetol)
    SELECT h.id INTO v_hh
    FROM public.households h
    JOIN public.household_members m ON m.household_id = h.id
    WHERE m.user_id = v_user
    ORDER BY h.created_at LIMIT 1;
  END IF;

  IF v_hh IS NULL THEN
    INSERT INTO public.households (name, currency, created_by)
    VALUES ('Moja domácnosť', 'EUR', v_user)
    RETURNING id INTO v_hh;
    RAISE NOTICE '[2/5] Vytvorená domácnosť: %', v_hh;
  ELSE
    RAISE NOTICE '[2/5] Domácnosť existuje: %', v_hh;
  END IF;

  -- 3) Membership ---------------------------------------------
  INSERT INTO public.household_members (household_id, user_id, role)
  VALUES (v_hh, v_user, 'owner')
  ON CONFLICT (household_id, user_id) DO NOTHING;
  RAISE NOTICE '[3/5] Členstvo zabezpečené (owner)';

  -- 4) Default account ----------------------------------------
  SELECT id INTO v_acc
  FROM public.accounts
  WHERE household_id = v_hh
  ORDER BY display_order LIMIT 1;

  IF v_acc IS NULL THEN
    INSERT INTO public.accounts (household_id, name, type, currency, initial_balance, display_order)
    VALUES (v_hh, 'Hlavný účet', 'checking', 'EUR', 0, 0)
    RETURNING id INTO v_acc;
    RAISE NOTICE '[4/5] Vytvorený účet: %', v_acc;
  ELSE
    RAISE NOTICE '[4/5] Účet existuje: %', v_acc;
  END IF;

  -- 5) Categories ---------------------------------------------
  SELECT count(*) INTO v_cat_count FROM public.categories WHERE household_id = v_hh;

  IF v_cat_count = 0 THEN
    v_i := 0;
    FOREACH v_name IN ARRAY v_income_names LOOP
      INSERT INTO public.categories (household_id, name, type, display_order)
      VALUES (v_hh, v_name, 'income', v_i);
      v_i := v_i + 1;
    END LOOP;

    v_i := 0;
    FOREACH v_name IN ARRAY v_expense_names LOOP
      INSERT INTO public.categories (household_id, name, type, display_order)
      VALUES (v_hh, v_name, 'expense', v_i);
      v_i := v_i + 1;
    END LOOP;

    RAISE NOTICE '[5/5] Kategórie naseedované (% príjmov + % výdavkov)',
                 array_length(v_income_names, 1),
                 array_length(v_expense_names, 1);
  ELSE
    RAISE NOTICE '[5/5] Kategórie existujú (%)', v_cat_count;
  END IF;

  RAISE NOTICE '--------------------------------------------------';
  RAISE NOTICE 'Hotovo.  Household: %', v_hh;
  RAISE NOTICE '         Account:   %', v_acc;
  RAISE NOTICE 'Teraz môžeš spustiť sample_transactions.sql.';
END $$;
