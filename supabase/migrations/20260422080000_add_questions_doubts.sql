-- ============================================================
-- CoachLMS Additive Migration: questions + doubts tables
-- Adds: questions, doubts, notifications, lesson_completions tables
-- Also adds: answers_json column to test_attempts
-- ============================================================

-- ─── 1. NEW ENUM TYPES ───────────────────────────────────────
DROP TYPE IF EXISTS public.doubt_status CASCADE;
CREATE TYPE public.doubt_status AS ENUM ('open', 'answered', 'closed');

DROP TYPE IF EXISTS public.notification_type CASCADE;
CREATE TYPE public.notification_type AS ENUM ('test', 'doubt', 'course', 'announcement', 'system');

-- ─── 2. NEW TABLES ───────────────────────────────────────────

-- questions (linked to tests)
CREATE TABLE IF NOT EXISTS public.questions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    test_id         UUID NOT NULL REFERENCES public.tests(id) ON DELETE CASCADE,
    section_name    TEXT NOT NULL DEFAULT 'Section 1',
    question_text   TEXT NOT NULL,
    option_a        TEXT NOT NULL,
    option_b        TEXT NOT NULL,
    option_c        TEXT NOT NULL,
    option_d        TEXT NOT NULL,
    correct_option  SMALLINT NOT NULL CHECK (correct_option BETWEEN 0 AND 3),
    explanation     TEXT,
    marks           NUMERIC(5,2) NOT NULL DEFAULT 1,
    negative_marks  NUMERIC(5,2) NOT NULL DEFAULT 0,
    sort_order      INT NOT NULL DEFAULT 0,
    difficulty      TEXT NOT NULL DEFAULT 'medium',
    subject         TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- doubts (student Q&A)
CREATE TABLE IF NOT EXISTS public.doubts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id      UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    course_id       UUID REFERENCES public.courses(id) ON DELETE SET NULL,
    lesson_id       UUID REFERENCES public.lessons(id) ON DELETE SET NULL,
    title           TEXT NOT NULL,
    body            TEXT NOT NULL,
    status          public.doubt_status NOT NULL DEFAULT 'open'::public.doubt_status,
    answered_by     UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    answer_text     TEXT,
    answered_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- notifications
CREATE TABLE IF NOT EXISTS public.notifications (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title           TEXT NOT NULL,
    body            TEXT NOT NULL,
    notification_type public.notification_type NOT NULL DEFAULT 'system'::public.notification_type,
    is_read         BOOLEAN NOT NULL DEFAULT false,
    action_url      TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- lesson_completions (tracks which lessons a student has completed)
CREATE TABLE IF NOT EXISTS public.lesson_completions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id      UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    course_id       UUID NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
    lesson_id       UUID NOT NULL REFERENCES public.lessons(id) ON DELETE CASCADE,
    completed_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── 3. ALTER EXISTING TABLES ────────────────────────────────

-- Add answers_json to test_attempts for storing per-question answers
ALTER TABLE public.test_attempts
ADD COLUMN IF NOT EXISTS answers_json JSONB;

-- Add anti_cheat_violations to test_attempts
ALTER TABLE public.test_attempts
ADD COLUMN IF NOT EXISTS anti_cheat_violations INT NOT NULL DEFAULT 0;

-- ─── 4. INDEXES ──────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_questions_test_id       ON public.questions(test_id);
CREATE INDEX IF NOT EXISTS idx_questions_sort_order    ON public.questions(test_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_doubts_student_id       ON public.doubts(student_id);
CREATE INDEX IF NOT EXISTS idx_doubts_status           ON public.doubts(status);
CREATE INDEX IF NOT EXISTS idx_doubts_course_id        ON public.doubts(course_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id   ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read   ON public.notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_lesson_completions_student ON public.lesson_completions(student_id);
CREATE INDEX IF NOT EXISTS idx_lesson_completions_course  ON public.lesson_completions(course_id);

CREATE UNIQUE INDEX IF NOT EXISTS uq_lesson_completion
    ON public.lesson_completions(student_id, lesson_id);

-- ─── 5. ENABLE RLS ───────────────────────────────────────────
ALTER TABLE public.questions          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doubts             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lesson_completions ENABLE ROW LEVEL SECURITY;

-- ─── 6. RLS POLICIES ─────────────────────────────────────────

-- questions: students read questions for their batch tests; admins manage all
DROP POLICY IF EXISTS "students_view_test_questions" ON public.questions;
CREATE POLICY "students_view_test_questions"
ON public.questions FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.tests t
        JOIN public.batch_enrollments be ON be.batch_id = t.batch_id
        WHERE t.id = questions.test_id
          AND be.student_id = auth.uid()
          AND be.is_active = true
          AND t.status = 'published'
    )
);

DROP POLICY IF EXISTS "admin_manage_questions" ON public.questions;
CREATE POLICY "admin_manage_questions"
ON public.questions FOR ALL TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

-- doubts: students manage own doubts; admins manage all
DROP POLICY IF EXISTS "students_manage_own_doubts" ON public.doubts;
CREATE POLICY "students_manage_own_doubts"
ON public.doubts FOR ALL TO authenticated
USING (student_id = auth.uid())
WITH CHECK (student_id = auth.uid());

DROP POLICY IF EXISTS "admin_manage_doubts" ON public.doubts;
CREATE POLICY "admin_manage_doubts"
ON public.doubts FOR ALL TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

-- notifications: users see own notifications; admins manage all
DROP POLICY IF EXISTS "users_own_notifications" ON public.notifications;
CREATE POLICY "users_own_notifications"
ON public.notifications FOR ALL TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "admin_manage_notifications" ON public.notifications;
CREATE POLICY "admin_manage_notifications"
ON public.notifications FOR ALL TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

-- lesson_completions: students manage own completions; admins manage all
DROP POLICY IF EXISTS "students_manage_own_completions" ON public.lesson_completions;
CREATE POLICY "students_manage_own_completions"
ON public.lesson_completions FOR ALL TO authenticated
USING (student_id = auth.uid())
WITH CHECK (student_id = auth.uid());

DROP POLICY IF EXISTS "admin_manage_completions" ON public.lesson_completions;
CREATE POLICY "admin_manage_completions"
ON public.lesson_completions FOR ALL TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

-- ─── 7. TRIGGERS ─────────────────────────────────────────────
DROP TRIGGER IF EXISTS set_updated_at_questions ON public.questions;
CREATE TRIGGER set_updated_at_questions
    BEFORE UPDATE ON public.questions
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS set_updated_at_doubts ON public.doubts;
CREATE TRIGGER set_updated_at_doubts
    BEFORE UPDATE ON public.doubts
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ─── 8. SAMPLE DATA ──────────────────────────────────────────
DO $$
DECLARE
    sample_test_id UUID;
    admin_id UUID;
    student_id UUID;
BEGIN
    -- Get existing test
    SELECT id INTO sample_test_id FROM public.tests LIMIT 1;
    SELECT id INTO admin_id FROM public.user_profiles WHERE role = 'admin' LIMIT 1;
    SELECT id INTO student_id FROM public.user_profiles WHERE role = 'student' LIMIT 1;

    IF sample_test_id IS NOT NULL THEN
        -- Insert sample questions
        INSERT INTO public.questions (test_id, section_name, question_text, option_a, option_b, option_c, option_d, correct_option, explanation, marks, sort_order, difficulty, subject)
        VALUES
            (sample_test_id, 'Physics', 'A body is thrown vertically upward with velocity u. The ratio of the time of ascent to the time of descent is:', '1:1', '1:2', '2:1', 'Depends on u', 0, 'For vertical projectile motion, time of ascent equals time of descent (ignoring air resistance).', 4, 1, 'medium', 'Physics'),
            (sample_test_id, 'Physics', 'The dimensional formula of angular momentum is:', 'ML²T⁻¹', 'MLT⁻¹', 'ML²T⁻²', 'M²L²T⁻¹', 0, 'Angular momentum = mvr = kg·m²·s⁻¹ = ML²T⁻¹', 4, 2, 'easy', 'Physics'),
            (sample_test_id, 'Chemistry', 'Which of the following has the highest ionization energy?', 'Na', 'Mg', 'Al', 'Si', 1, 'Mg has higher IE than Na due to increased nuclear charge. Al has lower IE than Mg due to 3p electron being easier to remove.', 4, 3, 'medium', 'Chemistry'),
            (sample_test_id, 'Chemistry', 'The IUPAC name of CH₃-CH(OH)-CH₂-CH₃ is:', '2-butanol', '3-butanol', '1-methylpropanol', '2-methylpropan-1-ol', 0, 'The OH group is on carbon 2 of a 4-carbon chain, so it is butan-2-ol (2-butanol).', 4, 4, 'easy', 'Chemistry'),
            (sample_test_id, 'Mathematics', 'If f(x) = x² + 2x + 1, then f''(x) is:', '2x + 2', '2x + 1', 'x + 2', '2x', 0, 'Differentiating x² + 2x + 1 gives 2x + 2.', 4, 5, 'easy', 'Mathematics')
        ON CONFLICT (id) DO NOTHING;
    END IF;

    -- Insert sample notifications for admin
    IF admin_id IS NOT NULL THEN
        INSERT INTO public.notifications (user_id, title, body, notification_type, is_read)
        VALUES
            (admin_id, 'New Student Enrolled', 'A new student has enrolled in Batch A.', 'system'::public.notification_type, false),
            (admin_id, 'Test Submitted', '15 students have submitted the Physics Mock Test.', 'test'::public.notification_type, false),
            (admin_id, 'Pending Doubts', '3 student doubts are awaiting your response.', 'doubt'::public.notification_type, true)
        ON CONFLICT (id) DO NOTHING;
    END IF;

    -- Insert sample doubt for student
    IF student_id IS NOT NULL THEN
        INSERT INTO public.doubts (student_id, title, body, status)
        VALUES
            (student_id, 'Doubt about Newton''s Third Law', 'Can you explain how Newton''s Third Law applies to rocket propulsion? I am confused about the action-reaction pair.', 'open'::public.doubt_status)
        ON CONFLICT (id) DO NOTHING;

        INSERT INTO public.notifications (user_id, title, body, notification_type, is_read)
        VALUES
            (student_id, 'New Test Available', 'Physics Mock Test 1 is now available. Duration: 60 mins.', 'test'::public.notification_type, false),
            (student_id, 'Course Updated', 'New lesson added to Mechanics course.', 'course'::public.notification_type, false),
            (student_id, 'Doubt Answered', 'Your doubt about Newton''s Third Law has been answered.', 'doubt'::public.notification_type, true)
        ON CONFLICT (id) DO NOTHING;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Sample data insertion skipped: %', SQLERRM;
END $$;
