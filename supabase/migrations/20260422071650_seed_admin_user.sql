-- ============================================================
-- CoachLMS: Seed Admin User
-- Creates admin@coachlms.in with role "admin" in auth.users
-- and ensures user_profiles row is correct.
-- ============================================================

DO $$
DECLARE
    admin_uuid UUID;
BEGIN
    -- Check if admin user already exists
    SELECT id INTO admin_uuid FROM auth.users WHERE email = 'admin@coachlms.in' LIMIT 1;

    IF admin_uuid IS NULL THEN
        -- Create the admin user in auth.users with all required fields
        admin_uuid := gen_random_uuid();

        INSERT INTO auth.users (
            id,
            instance_id,
            aud,
            role,
            email,
            encrypted_password,
            email_confirmed_at,
            created_at,
            updated_at,
            raw_user_meta_data,
            raw_app_meta_data,
            is_sso_user,
            is_anonymous,
            confirmation_token,
            confirmation_sent_at,
            recovery_token,
            recovery_sent_at,
            email_change_token_new,
            email_change,
            email_change_sent_at,
            email_change_token_current,
            email_change_confirm_status,
            reauthentication_token,
            reauthentication_sent_at,
            phone,
            phone_change,
            phone_change_token,
            phone_change_sent_at
        ) VALUES (
            admin_uuid,
            '00000000-0000-0000-0000-000000000000',
            'authenticated',
            'authenticated',
            'admin@coachlms.in',
            crypt('CoachAdmin#2026', gen_salt('bf', 10)),
            now(),
            now(),
            now(),
            jsonb_build_object('full_name', 'Coach Admin', 'role', 'admin'),
            jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
            false,
            false,
            '',
            null,
            '',
            null,
            '',
            '',
            null,
            '',
            0,
            '',
            null,
            null,
            '',
            '',
            null
        );

        RAISE NOTICE 'Admin user created with id: %', admin_uuid;
    ELSE
        -- User exists — update password and ensure role metadata is set
        UPDATE auth.users
        SET
            encrypted_password  = crypt('CoachAdmin#2026', gen_salt('bf', 10)),
            raw_user_meta_data  = raw_user_meta_data || jsonb_build_object('role', 'admin'),
            email_confirmed_at  = COALESCE(email_confirmed_at, now()),
            updated_at          = now()
        WHERE id = admin_uuid;

        RAISE NOTICE 'Admin user already exists (id: %), password and role metadata updated.', admin_uuid;
    END IF;

    -- Upsert user_profiles row for admin (trigger may have already created it)
    INSERT INTO public.user_profiles (id, email, full_name, role, is_active)
    VALUES (admin_uuid, 'admin@coachlms.in', 'Coach Admin', 'admin'::public.user_role, true)
    ON CONFLICT (id) DO UPDATE
        SET role      = 'admin'::public.user_role,
            full_name = COALESCE(NULLIF(public.user_profiles.full_name, ''), 'Coach Admin'),
            is_active = true,
            updated_at = now();

    RAISE NOTICE 'user_profiles row ensured for admin@coachlms.in';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Admin seed error: %', SQLERRM;
END $$;
