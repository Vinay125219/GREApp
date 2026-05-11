-- Migration: Notify all admin users when a student submits a test
-- Adds a trigger on test_attempts that fires on status → 'submitted'

-- ─── Function ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.notify_admins_on_test_submission()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_test_title  TEXT;
  v_student_name TEXT;
  v_admin       RECORD;
BEGIN
  -- Only fire when status transitions to 'submitted'
  IF NEW.status <> 'submitted' OR OLD.status = 'submitted' THEN
    RETURN NEW;
  END IF;

  -- Fetch test title
  SELECT title INTO v_test_title
  FROM public.tests
  WHERE id = NEW.test_id;

  -- Fetch student name
  SELECT full_name INTO v_student_name
  FROM public.user_profiles
  WHERE id = NEW.student_id;

  -- Insert a notification for every admin / super_admin
  FOR v_admin IN
    SELECT id FROM public.user_profiles
    WHERE role IN ('admin', 'super_admin')
  LOOP
    INSERT INTO public.notifications (
      user_id,
      title,
      body,
      notification_type,
      is_read,
      metadata
    )
    VALUES (
      v_admin.id,
      'Test Submitted: ' || LEFT(COALESCE(v_test_title, 'Test'), 60),
      COALESCE(v_student_name, 'A student') || ' has submitted the test "' ||
        LEFT(COALESCE(v_test_title, 'Test'), 50) || '".',
      'test'::public.notification_type,
      false,
      jsonb_build_object(
        'attempt_id', NEW.id,
        'test_id',    NEW.test_id,
        'student_id', NEW.student_id,
        'score',      NEW.score,
        'total_marks', NEW.total_marks
      )
    );
  END LOOP;

  RETURN NEW;
END;
$$;

-- ─── Trigger ─────────────────────────────────────────────────
DROP TRIGGER IF EXISTS trg_notify_admins_test_submission ON public.test_attempts;

CREATE TRIGGER trg_notify_admins_test_submission
  AFTER UPDATE OF status ON public.test_attempts
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_admins_on_test_submission();

-- ─── Add metadata column to notifications (if not present) ───
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'notifications'
      AND column_name  = 'metadata'
  ) THEN
    ALTER TABLE public.notifications ADD COLUMN metadata JSONB;
  END IF;
END;
$$;
