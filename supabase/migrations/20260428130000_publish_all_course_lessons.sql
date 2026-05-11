-- Publish all lessons that belong to published courses.
-- This fixes the case where lessons were uploaded but left as is_published=false
-- while the course itself is published, making them invisible to students.

UPDATE public.lessons
SET is_published = true,
    updated_at   = NOW()
WHERE is_published = false
  AND EXISTS (
      SELECT 1
      FROM public.courses c
      WHERE c.id = lessons.course_id
        AND c.is_published = true
  );
