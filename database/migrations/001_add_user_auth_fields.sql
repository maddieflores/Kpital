BEGIN;

SET LOCAL lock_timeout = '5s';

ALTER TABLE public.users
    ADD COLUMN IF NOT EXISTS username VARCHAR(50),
    ADD COLUMN IF NOT EXISTS phone_number VARCHAR(30),
    ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255),
    ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE,
    ALTER COLUMN plan TYPE VARCHAR(50);

ALTER TABLE public.users ALTER COLUMN username SET NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS users_username_key ON public.users (username);

COMMIT;
