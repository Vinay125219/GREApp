-- ============================================================
-- CoachLMS: Notify admins when a student submits a new doubt
-- ============================================================

-- ─── Function: notify all admins on new doubt ────────────────
CREATE OR REPLACE FUNCTION public.notify_admins_on_new_doubt()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_student_name TEXT;
    v_admin        RECORD;
BEGIN
    -- Fetch the student's display name (fallback to 'A student')
    SELECT COALESCE(full_name, email, 'A student')
    INTO v_student_name
    FROM public.user_profiles
    WHERE id = NEW.student_id;

    -- Insert a notification for every admin / super_admin
    FOR v_admin IN
        SELECT id
        FROM public.user_profiles
        WHERE role IN ('admin', 'super_admin')
    LOOP
        INSERT INTO public.notifications (
            user_id,
            title,
            body,
            notification_type,
            is_read,
            metadata
        ) VALUES (
            v_admin.id,
            'New Doubt Submitted',
            COALESCE(v_student_name, 'A student') ||
                ' asked: "' || LEFT(NEW.title, 60) || '"',
            'doubt'::public.notification_type,
            false,
            jsonb_build_object('doubt_id', NEW.id::text)
        );
    END LOOP;

    RETURN NEW;
END;
$$;

-- ─── Trigger: fire after a new doubt row is inserted ─────────
DROP TRIGGER IF EXISTS trg_notify_admins_new_doubt ON public.doubts;
CREATE TRIGGER trg_notify_admins_new_doubt
    AFTER INSERT ON public.doubts
    FOR EACH ROW EXECUTE FUNCTION public.notify_admins_on_new_doubt();
