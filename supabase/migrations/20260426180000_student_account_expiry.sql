-- ============================================================
-- Student Account Management: username + expiry support
-- Adds: username column, account_expires_at column to user_profiles
-- Adds: admin_create_student edge-function-ready RPC
-- ============================================================

-- 1. Add username column (unique, optional for existing rows)
ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS username TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS account_expires_at TIMESTAMPTZ;

-- 2. Index for fast expiry checks
CREATE INDEX IF NOT EXISTS idx_user_profiles_expires_at
  ON public.user_profiles (account_expires_at)
  WHERE account_expires_at IS NOT NULL;

-- 3. RPC: admin_create_student
--    Creates auth user + profile in one call (runs as SECURITY DEFINER)
CREATE OR REPLACE FUNCTION public.admin_create_student(
  p_email          TEXT,
  p_password       TEXT,
  p_full_name      TEXT,
  p_username       TEXT DEFAULT NULL,
  p_expires_at     TIMESTAMPTZ DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Create auth user via admin API (requires service role; here we insert directly)
  INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_user_meta_data,
    created_at,
    updated_at,
    aud,
    role
  )
  VALUES (
    gen_random_uuid(),
    p_email,
    crypt(p_password, gen_salt('bf')),
    now(),
    jsonb_build_object('full_name', p_full_name),
    now(),
    now(),
    'authenticated',
    'authenticated'
  )
  RETURNING id INTO v_user_id;

  -- Upsert profile
  INSERT INTO public.user_profiles (
    id, email, full_name, username, role, is_active, account_expires_at
  )
  VALUES (
    v_user_id,
    p_email,
    p_full_name,
    p_username,
    'student',
    true,
    p_expires_at
  )
  ON CONFLICT (id) DO UPDATE
    SET full_name          = EXCLUDED.full_name,
        username           = EXCLUDED.username,
        account_expires_at = EXCLUDED.account_expires_at,
        updated_at         = now();

  RETURN v_user_id;
END;
$$;

-- 4. RPC: admin_update_student_expiry
CREATE OR REPLACE FUNCTION public.admin_update_student_expiry(
  p_student_id UUID,
  p_expires_at TIMESTAMPTZ
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.user_profiles
  SET account_expires_at = p_expires_at,
      updated_at         = now()
  WHERE id = p_student_id;
END;
$$;

-- 5. Grant execute to authenticated (admin checks role in app layer)
GRANT EXECUTE ON FUNCTION public.admin_create_student TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_update_student_expiry TO authenticated;
