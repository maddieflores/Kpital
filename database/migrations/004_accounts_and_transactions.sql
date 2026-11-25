BEGIN;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'accounts' AND column_name = 'id' AND data_type = 'uuid'
    ) THEN
        ALTER TABLE public.transactions DROP CONSTRAINT IF EXISTS transactions_account_id_fkey;
        ALTER TABLE public.transactions DROP CONSTRAINT IF EXISTS transactions_destination_account_id_fkey;
        ALTER TABLE public.accounts ALTER COLUMN id TYPE VARCHAR(64) USING id::text;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'transactions' AND column_name = 'id' AND data_type = 'uuid'
    ) THEN
        ALTER TABLE public.transactions ALTER COLUMN id TYPE VARCHAR(64) USING id::text;
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

CREATE INDEX IF NOT EXISTS accounts_user_id_idx ON public.accounts(user_id);
CREATE INDEX IF NOT EXISTS transactions_user_id_idx ON public.transactions(user_id);
CREATE INDEX IF NOT EXISTS transactions_account_id_idx ON public.transactions(account_id);

COMMIT;
