-- ============================================================
-- CoachLMS: Doubt Replies + Notification Triggers
-- Adds: doubt_replies table, auto-notification on reply
-- ============================================================

-- ─── 1. doubt_replies table ──────────────────────────────────
CREATE TABLE IF NOT EXISTS public.doubt_replies (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    doubt_id    UUID NOT NULL REFERENCES public.doubts(id) ON DELETE CASCADE,
    author_id   UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    body        TEXT NOT NULL,
    is_admin    BOOLEAN NOT NULL DEFAULT false,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_doubt_replies_doubt_id ON public.doubt_replies(doubt_id);
CREATE INDEX IF NOT EXISTS idx_doubt_replies_author_id ON public.doubt_replies(author_id);

ALTER TABLE public.doubt_replies ENABLE ROW LEVEL SECURITY;

-- Students can read replies on their own doubts; admins manage all
DROP POLICY IF EXISTS "students_view_own_doubt_replies" ON public.doubt_replies;
CREATE POLICY "students_view_own_doubt_replies"
ON public.doubt_replies FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.doubts d
        WHERE d.id = doubt_replies.doubt_id
          AND d.student_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "students_insert_own_doubt_replies" ON public.doubt_replies;
CREATE POLICY "students_insert_own_doubt_replies"
ON public.doubt_replies FOR INSERT TO authenticated
WITH CHECK (
    author_id = auth.uid()
    AND is_admin = false
    AND EXISTS (
        SELECT 1 FROM public.doubts d
        WHERE d.id = doubt_replies.doubt_id
          AND d.student_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "admin_manage_doubt_replies" ON public.doubt_replies;
CREATE POLICY "admin_manage_doubt_replies"
ON public.doubt_replies FOR ALL TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

DROP TRIGGER IF EXISTS set_updated_at_doubt_replies ON public.doubt_replies;
CREATE TRIGGER set_updated_at_doubt_replies
    BEFORE UPDATE ON public.doubt_replies
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ─── 2. Function: notify student when admin replies ──────────
CREATE OR REPLACE FUNCTION public.notify_student_on_doubt_reply()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_student_id UUID;
    v_doubt_title TEXT;
BEGIN
    -- Only fire for admin replies
    IF NEW.is_admin = false THEN
        RETURN NEW;
    END IF;

    SELECT d.student_id, d.title
    INTO v_student_id, v_doubt_title
    FROM public.doubts d
    WHERE d.id = NEW.doubt_id;

    IF v_student_id IS NOT NULL THEN
        INSERT INTO public.notifications (user_id, title, body, notification_type, is_read)
        VALUES (
            v_student_id,
            'Doubt Answered',
            'Your doubt "' || LEFT(v_doubt_title, 60) || '" has received a reply from the instructor.',
            'doubt'::public.notification_type,
            false
        );

        -- Mark doubt as answered
        UPDATE public.doubts
        SET status = 'answered'::public.doubt_status,
            answer_text = NEW.body,
            answered_by = NEW.author_id,
            answered_at = now()
        WHERE id = NEW.doubt_id;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_student_doubt_reply ON public.doubt_replies;
CREATE TRIGGER trg_notify_student_doubt_reply
    AFTER INSERT ON public.doubt_replies
    FOR EACH ROW EXECUTE FUNCTION public.notify_student_on_doubt_reply();

-- ─── 3. Function: notify students when test is scheduled ─────
CREATE OR REPLACE FUNCTION public.notify_batch_on_test_schedule()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_student RECORD;
BEGIN
    -- Only fire when scheduled_at is set and status becomes published
    IF NEW.scheduled_at IS NULL OR NEW.status != 'published' THEN
        RETURN NEW;
    END IF;
    -- Only fire on update when scheduled_at changes
    IF TG_OP = 'UPDATE' AND OLD.scheduled_at = NEW.scheduled_at AND OLD.status = NEW.status THEN
        RETURN NEW;
    END IF;

    FOR v_student IN
        SELECT be.student_id
        FROM public.batch_enrollments be
        WHERE be.batch_id = NEW.batch_id
          AND be.is_active = true
    LOOP
        INSERT INTO public.notifications (user_id, title, body, notification_type, is_read)
        VALUES (
            v_student.student_id,
            'Test Scheduled: ' || LEFT(NEW.title, 50),
            'A test has been scheduled for ' ||
            TO_CHAR(NEW.scheduled_at AT TIME ZONE 'UTC', 'DD Mon YYYY HH24:MI') || ' UTC. Duration: ' ||
            NEW.duration_mins || ' mins.',
            'test'::public.notification_type,
            false
        )
        ON CONFLICT DO NOTHING;
    END LOOP;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_batch_test_schedule ON public.tests;
CREATE TRIGGER trg_notify_batch_test_schedule
    AFTER INSERT OR UPDATE OF scheduled_at, status ON public.tests
    FOR EACH ROW EXECUTE FUNCTION public.notify_batch_on_test_schedule();

-- ─── 4. Function: notify students when drip content unlocks ──
CREATE OR REPLACE FUNCTION public.notify_batch_on_drip_unlock()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_student RECORD;
    v_course_title TEXT;
BEGIN
    -- Only fire when is_published changes to true
    IF NEW.is_published = false OR (TG_OP = 'UPDATE' AND OLD.is_published = NEW.is_published) THEN
        RETURN NEW;
    END IF;

    SELECT c.title INTO v_course_title
    FROM public.courses c WHERE c.id = NEW.course_id;

    FOR v_student IN
        SELECT DISTINCT be.student_id
        FROM public.batch_enrollments be
        JOIN public.course_enrollments ce ON ce.student_id = be.student_id
        WHERE ce.course_id = NEW.course_id
          AND be.is_active = true
    LOOP
        INSERT INTO public.notifications (user_id, title, body, notification_type, is_read)
        VALUES (
            v_student.student_id,
            'New Content Unlocked',
            '"' || LEFT(NEW.title, 50) || '" is now available in ' || COALESCE(v_course_title, 'your course') || '.',
            'course'::public.notification_type,
            false
        )
        ON CONFLICT DO NOTHING;
    END LOOP;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_drip_unlock ON public.lessons;
CREATE TRIGGER trg_notify_drip_unlock
    AFTER INSERT OR UPDATE OF is_published ON public.lessons
    FOR EACH ROW EXECUTE FUNCTION public.notify_batch_on_drip_unlock();
