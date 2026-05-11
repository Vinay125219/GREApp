-- ============================================================
-- CoachLMS: Add doubt_id to doubt reply notification metadata
-- ============================================================

-- Update the function to include doubt_id in metadata
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
        INSERT INTO public.notifications (user_id, title, body, notification_type, is_read, metadata)
        VALUES (
            v_student_id,
            'Doubt Answered',
            'Your doubt "' || LEFT(v_doubt_title, 60) || '" has received a reply from the instructor.',
            'doubt'::public.notification_type,
            false,
            jsonb_build_object('doubt_id', NEW.doubt_id::text)
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
