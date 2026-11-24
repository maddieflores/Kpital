BEGIN;

CREATE TABLE IF NOT EXISTS public.auth_sessions (
    token_hash CHAR(64) PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    expires_at TIMESTAMPTZ NOT NULL
);
CREATE INDEX IF NOT EXISTS auth_sessions_user_id_idx ON public.auth_sessions (user_id);

COMMIT;
