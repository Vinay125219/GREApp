-- ============================================================
-- CoachLMS Full Schema Migration
-- Tables: user_profiles, batches, courses, lessons, tests,
--         batch_enrollments, test_attempts, course_enrollments
-- ============================================================

-- ─── 1. ENUM TYPES ───────────────────────────────────────────
DROP TYPE IF EXISTS public.user_role CASCADE;
CREATE TYPE public.user_role AS ENUM ('student', 'admin', 'super_admin');

DROP TYPE IF EXISTS public.lesson_type CASCADE;
CREATE TYPE public.lesson_type AS ENUM ('video', 'text', 'quiz', 'pdf');

DROP TYPE IF EXISTS public.test_status CASCADE;
CREATE TYPE public.test_status AS ENUM ('draft', 'published', 'archived');

DROP TYPE IF EXISTS public.attempt_status CASCADE;
CREATE TYPE public.attempt_status AS ENUM ('in_progress', 'submitted', 'graded');

-- ─── 2. CORE TABLES ──────────────────────────────────────────

-- user_profiles (mirrors auth.users, auto-populated by trigger)
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email         TEXT NOT NULL UNIQUE,
    full_name     TEXT NOT NULL DEFAULT '',
    avatar_url    TEXT,
    role          public.user_role NOT NULL DEFAULT 'student'::public.user_role,
    is_active     BOOLEAN NOT NULL DEFAULT true,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- batches (cohorts / classes)
CREATE TABLE IF NOT EXISTS public.batches (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name          TEXT NOT NULL,
    description   TEXT,
    start_date    DATE,
    end_date      DATE,
    is_active     BOOLEAN NOT NULL DEFAULT true,
    created_by    UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- courses
CREATE TABLE IF NOT EXISTS public.courses (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title         TEXT NOT NULL,
    description   TEXT,
    thumbnail_url TEXT,
    batch_id      UUID REFERENCES public.batches(id) ON DELETE SET NULL,
    created_by    UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    is_published  BOOLEAN NOT NULL DEFAULT false,
    total_lessons INT NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- lessons
CREATE TABLE IF NOT EXISTS public.lessons (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id     UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    title         TEXT NOT NULL,
    content_url   TEXT,
    lesson_type   public.lesson_type NOT NULL DEFAULT 'text'::public.lesson_type,
    sort_order    INT NOT NULL DEFAULT 0,
    duration_mins INT,
    is_published  BOOLEAN NOT NULL DEFAULT false,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- tests
CREATE TABLE IF NOT EXISTS public.tests (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title           TEXT NOT NULL,
    description     TEXT,
    course_id       UUID REFERENCES public.courses(id) ON DELETE SET NULL,
    batch_id        UUID REFERENCES public.batches(id) ON DELETE SET NULL,
    created_by      UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    scheduled_at    TIMESTAMPTZ,
    duration_mins   INT NOT NULL DEFAULT 60,
    total_marks     INT NOT NULL DEFAULT 100,
    passing_marks   INT NOT NULL DEFAULT 40,
    status          public.test_status NOT NULL DEFAULT 'draft'::public.test_status,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- batch_enrollments (student ↔ batch)
CREATE TABLE IF NOT EXISTS public.batch_enrollments (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id    UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    batch_id      UUID NOT NULL REFERENCES public.batches(id) ON DELETE CASCADE,
    enrolled_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    is_active     BOOLEAN NOT NULL DEFAULT true
);

-- course_enrollments (student ↔ course progress)
CREATE TABLE IF NOT EXISTS public.course_enrollments (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id          UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    course_id           UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    lessons_completed   INT NOT NULL DEFAULT 0,
    last_accessed_at    TIMESTAMPTZ,
    enrolled_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- test_attempts (student ↔ test results)
CREATE TABLE IF NOT EXISTS public.test_attempts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id      UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    test_id         UUID NOT NULL REFERENCES public.tests(id) ON DELETE CASCADE,
    score           NUMERIC(6,2),
    total_marks     INT,
    status          public.attempt_status NOT NULL DEFAULT 'in_progress'::public.attempt_status,
    started_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    submitted_at    TIMESTAMPTZ
);

-- ─── 3. INDEXES ──────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_user_profiles_role        ON public.user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_courses_batch_id          ON public.courses(batch_id);
CREATE INDEX IF NOT EXISTS idx_lessons_course_id         ON public.lessons(course_id);
CREATE INDEX IF NOT EXISTS idx_tests_batch_id            ON public.tests(batch_id);
CREATE INDEX IF NOT EXISTS idx_tests_scheduled_at        ON public.tests(scheduled_at);
CREATE INDEX IF NOT EXISTS idx_batch_enrollments_student ON public.batch_enrollments(student_id);
CREATE INDEX IF NOT EXISTS idx_batch_enrollments_batch   ON public.batch_enrollments(batch_id);
CREATE INDEX IF NOT EXISTS idx_course_enrollments_student ON public.course_enrollments(student_id);
CREATE INDEX IF NOT EXISTS idx_test_attempts_student     ON public.test_attempts(student_id);
CREATE INDEX IF NOT EXISTS idx_test_attempts_test        ON public.test_attempts(test_id);

-- Unique constraints via partial indexes
CREATE UNIQUE INDEX IF NOT EXISTS uq_batch_enrollment
    ON public.batch_enrollments(student_id, batch_id);

CREATE UNIQUE INDEX IF NOT EXISTS uq_course_enrollment
    ON public.course_enrollments(student_id, course_id);

-- ─── 4. HELPER FUNCTIONS (before RLS policies) ───────────────

-- Check if current user is admin/super_admin via auth metadata (no recursion)
CREATE OR REPLACE FUNCTION public.is_admin_user()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM auth.users au
    WHERE au.id = auth.uid()
    AND (
        au.raw_user_meta_data->>'role' IN ('admin', 'super_admin')
        OR au.raw_app_meta_data->>'role' IN ('admin', 'super_admin')
    )
)
$$;

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- Handle new auth user → create user_profiles row
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, full_name, avatar_url, role)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', NULL),
        COALESCE(NEW.raw_user_meta_data->>'role', 'student')::public.user_role
    )
    ON CONFLICT (id) DO UPDATE
        SET email     = EXCLUDED.email,
            full_name = EXCLUDED.full_name,
            role      = EXCLUDED.role;
    RETURN NEW;
END;
$$;

-- ─── 5. ENABLE RLS ───────────────────────────────────────────
ALTER TABLE public.user_profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.batches            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courses            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lessons            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tests              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.batch_enrollments  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_attempts      ENABLE ROW LEVEL SECURITY;

-- ─── 6. RLS POLICIES ─────────────────────────────────────────

-- user_profiles: own row access + admin full access
DROP POLICY IF EXISTS "users_own_profile" ON public.user_profiles;
CREATE POLICY "users_own_profile"
ON public.user_profiles FOR ALL TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS "admin_all_profiles" ON public.user_profiles;
CREATE POLICY "admin_all_profiles"
ON public.user_profiles FOR ALL TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

-- batches: students read active batches they're enrolled in; admins manage all
DROP POLICY IF EXISTS "students_view_enrolled_batches" ON public.batches;
CREATE POLICY "students_view_enrolled_batches"
ON public.batches FOR SELECT TO authenticated
USING (
    is_active = true
    AND EXISTS (
        SELECT 1 FROM public.batch_enrollments be
        WHERE be.batch_id = id AND be.student_id = auth.uid() AND be.is_active = true
    )
);

DROP POLICY IF EXISTS "admin_manage_batches" ON public.batches;
CREATE POLICY "admin_manage_batches"
ON public.batches FOR ALL TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

-- courses: students read published courses in their batches; admins manage all
DROP POLICY IF EXISTS "students_view_batch_courses" ON public.courses;
CREATE POLICY "students_view_batch_courses"
ON public.courses FOR SELECT TO authenticated
USING (
    is_published = true
    AND (
        batch_id IS NULL
        OR EXISTS (
            SELECT 1 FROM public.batch_enrollments be
            WHERE be.batch_id = courses.batch_id
              AND be.student_id = auth.uid()
              AND be.is_active = true
        )
    )
);

DROP POLICY IF EXISTS "admin_manage_courses" ON public.courses;
CREATE POLICY "admin_manage_courses"
ON public.courses FOR ALL TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

-- lessons: students read published lessons of accessible courses; admins manage all
DROP POLICY IF EXISTS "students_view_lessons" ON public.lessons;
CREATE POLICY "students_view_lessons"
ON public.lessons FOR SELECT TO authenticated
USING (
    is_published = true
    AND EXISTS (
        SELECT 1 FROM public.courses c
        WHERE c.id = lessons.course_id
          AND c.is_published = true
          AND (
              c.batch_id IS NULL
              OR EXISTS (
                  SELECT 1 FROM public.batch_enrollments be
                  WHERE be.batch_id = c.batch_id
                    AND be.student_id = auth.uid()
                    AND be.is_active = true
              )
          )
    )
);

DROP POLICY IF EXISTS "admin_manage_lessons" ON public.lessons;
CREATE POLICY "admin_manage_lessons"
ON public.lessons FOR ALL TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

-- tests: students see published tests for their batches; admins manage all
DROP POLICY IF EXISTS "students_view_tests" ON public.tests;
CREATE POLICY "students_view_tests"
ON public.tests FOR SELECT TO authenticated
USING (
    status = 'published'::public.test_status
    AND (
        batch_id IS NULL
        OR EXISTS (
            SELECT 1 FROM public.batch_enrollments be
            WHERE be.batch_id = tests.batch_id
              AND be.student_id = auth.uid()
              AND be.is_active = true
        )
    )
);

DROP POLICY IF EXISTS "admin_manage_tests" ON public.tests;
CREATE POLICY "admin_manage_tests"
ON public.tests FOR ALL TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

-- batch_enrollments: students see own; admins manage all
DROP POLICY IF EXISTS "students_own_enrollments" ON public.batch_enrollments;
CREATE POLICY "students_own_enrollments"
ON public.batch_enrollments FOR SELECT TO authenticated
USING (student_id = auth.uid());

DROP POLICY IF EXISTS "admin_manage_batch_enrollments" ON public.batch_enrollments;
CREATE POLICY "admin_manage_batch_enrollments"
ON public.batch_enrollments FOR ALL TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

-- course_enrollments: students manage own; admins manage all
DROP POLICY IF EXISTS "students_own_course_enrollments" ON public.course_enrollments;
CREATE POLICY "students_own_course_enrollments"
ON public.course_enrollments FOR ALL TO authenticated
USING (student_id = auth.uid())
WITH CHECK (student_id = auth.uid());

DROP POLICY IF EXISTS "admin_manage_course_enrollments" ON public.course_enrollments;
CREATE POLICY "admin_manage_course_enrollments"
ON public.course_enrollments FOR ALL TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

-- test_attempts: students manage own; admins manage all
DROP POLICY IF EXISTS "students_own_test_attempts" ON public.test_attempts;
CREATE POLICY "students_own_test_attempts"
ON public.test_attempts FOR ALL TO authenticated
USING (student_id = auth.uid())
WITH CHECK (student_id = auth.uid());

DROP POLICY IF EXISTS "admin_manage_test_attempts" ON public.test_attempts;
CREATE POLICY "admin_manage_test_attempts"
ON public.test_attempts FOR ALL TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

-- ─── 7. TRIGGERS ─────────────────────────────────────────────

-- Auto-create user_profiles on auth signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- updated_at triggers
DROP TRIGGER IF EXISTS set_updated_at_user_profiles ON public.user_profiles;
CREATE TRIGGER set_updated_at_user_profiles
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS set_updated_at_batches ON public.batches;
CREATE TRIGGER set_updated_at_batches
    BEFORE UPDATE ON public.batches
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS set_updated_at_courses ON public.courses;
CREATE TRIGGER set_updated_at_courses
    BEFORE UPDATE ON public.courses
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS set_updated_at_lessons ON public.lessons;
CREATE TRIGGER set_updated_at_lessons
    BEFORE UPDATE ON public.lessons
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS set_updated_at_tests ON public.tests;
CREATE TRIGGER set_updated_at_tests
    BEFORE UPDATE ON public.tests
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ─── 8. SEED DATA ─────────────────────────────────────────────
-- Ensure the existing admin user (admin@coachlms.in) has a profile
-- and seed sample batch, courses, lessons, and tests for demo.

DO $$
DECLARE
    admin_uid        UUID;
    student_uid      UUID;
    batch_uuid       UUID := gen_random_uuid();
    course1_uuid     UUID := gen_random_uuid();
    course2_uuid     UUID := gen_random_uuid();
    test1_uuid       UUID := gen_random_uuid();
    test2_uuid       UUID := gen_random_uuid();
BEGIN
    -- Get existing admin user id
    SELECT id INTO admin_uid FROM auth.users WHERE email = 'admin@coachlms.in' LIMIT 1;

    -- Ensure admin profile exists with correct role
    IF admin_uid IS NOT NULL THEN
        INSERT INTO public.user_profiles (id, email, full_name, role)
        VALUES (admin_uid, 'admin@coachlms.in', 'Coach Admin', 'admin'::public.user_role)
        ON CONFLICT (id) DO UPDATE
            SET role = 'admin'::public.user_role,
                full_name = COALESCE(NULLIF(public.user_profiles.full_name, ''), 'Coach Admin');
    END IF;

    -- Create a demo student user in auth
    student_uid := gen_random_uuid();
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES (
        student_uid, '00000000-0000-0000-0000-000000000000',
        'authenticated', 'authenticated',
        'student@coachlms.in',
        crypt('Student#2026', gen_salt('bf', 10)),
        now(), now(), now(),
        jsonb_build_object('full_name', 'Arjun Sharma', 'role', 'student'),
        jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
        false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
    ) ON CONFLICT (id) DO NOTHING;

    -- Re-fetch student id in case it already existed
    SELECT id INTO student_uid FROM auth.users WHERE email = 'student@coachlms.in' LIMIT 1;

    -- Batch
    INSERT INTO public.batches (id, name, description, start_date, end_date, is_active, created_by)
    VALUES (batch_uuid, 'GRE Batch 2026', 'Intensive GRE preparation batch', '2026-01-01', '2026-12-31', true, admin_uid)
    ON CONFLICT (id) DO NOTHING;

    -- Courses
    INSERT INTO public.courses (id, title, description, batch_id, created_by, is_published, total_lessons)
    VALUES
        (course1_uuid, 'Verbal Reasoning', 'Master GRE verbal section with vocabulary and reading comprehension', batch_uuid, admin_uid, true, 12),
        (course2_uuid, 'Quantitative Reasoning', 'Algebra, geometry, and data analysis for GRE quant', batch_uuid, admin_uid, true, 15)
    ON CONFLICT (id) DO NOTHING;

    -- Lessons for course 1
    INSERT INTO public.lessons (id, course_id, title, lesson_type, sort_order, duration_mins, is_published)
    VALUES
        (gen_random_uuid(), course1_uuid, 'Introduction to Text Completion', 'video'::public.lesson_type, 1, 20, true),
        (gen_random_uuid(), course1_uuid, 'Sentence Equivalence Strategies', 'video'::public.lesson_type, 2, 25, true),
        (gen_random_uuid(), course1_uuid, 'Reading Comprehension Techniques', 'text'::public.lesson_type, 3, 30, true),
        (gen_random_uuid(), course1_uuid, 'Vocabulary Building - Set 1', 'pdf'::public.lesson_type, 4, 15, true)
    ON CONFLICT (id) DO NOTHING;

    -- Lessons for course 2
    INSERT INTO public.lessons (id, course_id, title, lesson_type, sort_order, duration_mins, is_published)
    VALUES
        (gen_random_uuid(), course2_uuid, 'Arithmetic Fundamentals', 'video'::public.lesson_type, 1, 20, true),
        (gen_random_uuid(), course2_uuid, 'Algebra Essentials', 'video'::public.lesson_type, 2, 30, true),
        (gen_random_uuid(), course2_uuid, 'Geometry Concepts', 'text'::public.lesson_type, 3, 25, true)
    ON CONFLICT (id) DO NOTHING;

    -- Tests
    INSERT INTO public.tests (id, title, description, batch_id, created_by, scheduled_at, duration_mins, total_marks, passing_marks, status)
    VALUES
        (test1_uuid, 'GRE Mock Test 1', 'Full-length GRE practice test', batch_uuid, admin_uid,
         now() + interval '3 days', 240, 340, 300, 'published'::public.test_status),
        (test2_uuid, 'Verbal Mini Test', 'Quick verbal reasoning assessment', batch_uuid, admin_uid,
         now() + interval '7 days', 60, 100, 60, 'published'::public.test_status)
    ON CONFLICT (id) DO NOTHING;

    -- Enroll student in batch
    IF student_uid IS NOT NULL THEN
        INSERT INTO public.batch_enrollments (student_id, batch_id)
        VALUES (student_uid, batch_uuid)
        ON CONFLICT DO NOTHING;

        -- Course enrollments with progress
        INSERT INTO public.course_enrollments (student_id, course_id, lessons_completed, last_accessed_at)
        VALUES
            (student_uid, course1_uuid, 3, now() - interval '1 day'),
            (student_uid, course2_uuid, 1, now() - interval '2 days')
        ON CONFLICT DO NOTHING;

        -- A past test attempt
        INSERT INTO public.test_attempts (student_id, test_id, score, total_marks, status, started_at, submitted_at)
        VALUES (student_uid, test1_uuid, 285, 340, 'graded'::public.attempt_status, now() - interval '5 days', now() - interval '5 days' + interval '4 hours')
        ON CONFLICT (id) DO NOTHING;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Seed data error: %', SQLERRM;
END $$;
