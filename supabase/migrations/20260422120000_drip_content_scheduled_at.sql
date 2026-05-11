-- ============================================================
-- Drip Content: Add scheduled_at to lessons table
-- tests.scheduled_at already exists in the schema
-- ============================================================

-- Add scheduled_at to lessons (idempotent)
ALTER TABLE public.lessons
ADD COLUMN IF NOT EXISTS scheduled_at TIMESTAMPTZ;

-- Index for efficient drip content queries
CREATE INDEX IF NOT EXISTS idx_lessons_scheduled_at ON public.lessons(scheduled_at);

-- Sample drip content data using existing courses/tests
DO $$
DECLARE
    existing_course_id UUID;
    existing_test_id UUID;
    now_ts TIMESTAMPTZ := now();
BEGIN
    -- Get an existing course if any
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'courses'
    ) THEN
        SELECT id INTO existing_course_id FROM public.courses LIMIT 1;
    END IF;

    -- Get an existing test if any
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'tests'
    ) THEN
        SELECT id INTO existing_test_id FROM public.tests LIMIT 1;
    END IF;

    -- Insert sample lessons with drip schedule if a course exists
    IF existing_course_id IS NOT NULL THEN
        INSERT INTO public.lessons (id, course_id, title, lesson_type, sort_order, is_published, scheduled_at)
        VALUES
            (gen_random_uuid(), existing_course_id, 'Introduction & Overview', 'text'::public.lesson_type, 1, true, now_ts - INTERVAL '7 days'),
            (gen_random_uuid(), existing_course_id, 'Core Concepts - Part 1', 'video'::public.lesson_type, 2, true, now_ts - INTERVAL '3 days'),
            (gen_random_uuid(), existing_course_id, 'Core Concepts - Part 2', 'video'::public.lesson_type, 3, true, now_ts + INTERVAL '1 day'),
            (gen_random_uuid(), existing_course_id, 'Practice Problems', 'quiz'::public.lesson_type, 4, true, now_ts + INTERVAL '4 days'),
            (gen_random_uuid(), existing_course_id, 'Advanced Topics', 'pdf'::public.lesson_type, 5, true, now_ts + INTERVAL '7 days'),
            (gen_random_uuid(), existing_course_id, 'Final Review', 'text'::public.lesson_type, 6, true, now_ts + INTERVAL '10 days')
        ON CONFLICT (id) DO NOTHING;
    END IF;

    -- Schedule the existing test if any
    IF existing_test_id IS NOT NULL THEN
        UPDATE public.tests
        SET scheduled_at = now_ts + INTERVAL '5 days',
            status = 'published'::public.test_status
        WHERE id = existing_test_id
          AND scheduled_at IS NULL;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Drip content sample data insertion skipped: %', SQLERRM;
END $$;
