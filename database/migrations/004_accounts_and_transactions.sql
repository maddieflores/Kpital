BEGIN;

SET LOCAL lock_timeout = '5s';

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'accounts'
          AND column_name = 'id' AND data_type = 'uuid'
    ) THEN
        ALTER TABLE public.transactions DROP CONSTRAINT IF EXISTS transactions_account_id_fkey;
        ALTER TABLE public.transactions DROP CONSTRAINT IF EXISTS transactions_destination_account_id_fkey;
        ALTER TABLE public.business_sales DROP CONSTRAINT business_sales_account_id_fkey;
        ALTER TABLE public.debt_payments DROP CONSTRAINT debt_payments_account_id_fkey;
        ALTER TABLE public.savings_goals DROP CONSTRAINT savings_goals_account_id_fkey;

        ALTER TABLE public.accounts ALTER COLUMN id DROP DEFAULT;
        ALTER TABLE public.accounts ALTER COLUMN id TYPE VARCHAR(64) USING id::text;
        ALTER TABLE public.accounts ALTER COLUMN id SET DEFAULT uuid_generate_v4()::text;
        ALTER TABLE public.business_sales ALTER COLUMN account_id TYPE VARCHAR(64) USING account_id::text;
        ALTER TABLE public.debt_payments ALTER COLUMN account_id TYPE VARCHAR(64) USING account_id::text;
        ALTER TABLE public.savings_goals ALTER COLUMN account_id TYPE VARCHAR(64) USING account_id::text;

        ALTER TABLE public.business_sales ADD CONSTRAINT business_sales_account_id_fkey
            FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE SET NULL;
        ALTER TABLE public.debt_payments ADD CONSTRAINT debt_payments_account_id_fkey
            FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE SET NULL;
        ALTER TABLE public.savings_goals ADD CONSTRAINT savings_goals_account_id_fkey
            FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'transactions'
          AND column_name = 'id' AND data_type = 'uuid'
    ) THEN
        ALTER TABLE public.transactions ALTER COLUMN id DROP DEFAULT;
        ALTER TABLE public.transactions ALTER COLUMN id TYPE VARCHAR(64) USING id::text;
        ALTER TABLE public.transactions ALTER COLUMN id SET DEFAULT uuid_generate_v4()::text;
        ALTER TABLE public.transactions ALTER COLUMN account_id TYPE VARCHAR(64) USING account_id::text;
        ALTER TABLE public.transactions ALTER COLUMN destination_account_id TYPE VARCHAR(64) USING destination_account_id::text;
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.accounts (
    id VARCHAR(64) PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(30) NOT NULL,
    currency VARCHAR(5) DEFAULT 'BOB',
    balance NUMERIC(14, 2) DEFAULT 0.00,
    is_savings_vault BOOLEAN DEFAULT FALSE,
    target_amount NUMERIC(14, 2),
    color_hex VARCHAR(10) DEFAULT '#3366D6',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.accounts ADD COLUMN IF NOT EXISTS target_amount NUMERIC(14, 2);
ALTER TABLE public.accounts ADD COLUMN IF NOT EXISTS color_hex VARCHAR(10) DEFAULT '#3366D6';
ALTER TABLE public.accounts ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

CREATE TABLE IF NOT EXISTS public.finance_records (
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    collection TEXT NOT NULL CHECK (collection IN ('debts', 'products', 'sales')),
    id VARCHAR(64) NOT NULL,
    data JSONB,
    PRIMARY KEY (user_id, collection, id)
);

CREATE TABLE IF NOT EXISTS public.transactions (
    id VARCHAR(64) PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    account_id VARCHAR(64) NOT NULL,
    account_name VARCHAR(100),
    destination_account_id VARCHAR(64),
    destination_account_name VARCHAR(100),
    type VARCHAR(20) NOT NULL,
    amount NUMERIC(14, 2) NOT NULL,
    currency VARCHAR(5) DEFAULT 'BOB',
    contact_name VARCHAR(150),
    description TEXT,
    category VARCHAR(100),
    receipt_image_url TEXT,
    transaction_date TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS account_name VARCHAR(100);
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS destination_account_name VARCHAR(100);
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS category VARCHAR(100);
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS is_essential BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS accounts_user_id_idx ON public.accounts(user_id);
CREATE INDEX IF NOT EXISTS transactions_user_id_idx ON public.transactions(user_id);
CREATE INDEX IF NOT EXISTS transactions_account_id_idx ON public.transactions(account_id);

COMMIT;
