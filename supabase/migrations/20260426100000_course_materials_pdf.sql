-- ============================================================
-- Course Materials PDF Storage Bucket
-- Creates a storage bucket for course PDF materials
-- ============================================================

-- Create the course-materials storage bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'course-materials',
  'course-materials',
  true,
  52428800, -- 50MB limit
  ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- RLS policies for course-materials bucket
DROP POLICY IF EXISTS "course_materials_public_read" ON storage.objects;
CREATE POLICY "course_materials_public_read"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'course-materials');

DROP POLICY IF EXISTS "course_materials_admin_insert" ON storage.objects;
CREATE POLICY "course_materials_admin_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'course-materials'
  AND public.is_admin_user()
);

DROP POLICY IF EXISTS "course_materials_admin_update" ON storage.objects;
CREATE POLICY "course_materials_admin_update"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'course-materials'
  AND public.is_admin_user()
);

DROP POLICY IF EXISTS "course_materials_admin_delete" ON storage.objects;
CREATE POLICY "course_materials_admin_delete"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'course-materials'
  AND public.is_admin_user()
);

-- Add batch_course_assignments table for batch → course/test assignments
CREATE TABLE IF NOT EXISTS public.batch_course_assignments (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id    UUID NOT NULL REFERENCES public.batches(id) ON DELETE CASCADE,
  course_id   UUID REFERENCES public.courses(id) ON DELETE CASCADE,
  test_id     UUID REFERENCES public.tests(id) ON DELETE CASCADE,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  assigned_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  CONSTRAINT check_course_or_test CHECK (
    (course_id IS NOT NULL AND test_id IS NULL) OR
    (course_id IS NULL AND test_id IS NOT NULL)
  )
);

CREATE INDEX IF NOT EXISTS idx_batch_course_assignments_batch ON public.batch_course_assignments(batch_id);
CREATE INDEX IF NOT EXISTS idx_batch_course_assignments_course ON public.batch_course_assignments(course_id);
CREATE INDEX IF NOT EXISTS idx_batch_course_assignments_test ON public.batch_course_assignments(test_id);

CREATE UNIQUE INDEX IF NOT EXISTS uq_batch_course
  ON public.batch_course_assignments(batch_id, course_id)
  WHERE course_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_batch_test
  ON public.batch_course_assignments(batch_id, test_id)
  WHERE test_id IS NOT NULL;

ALTER TABLE public.batch_course_assignments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_manage_batch_course_assignments" ON public.batch_course_assignments;
CREATE POLICY "admin_manage_batch_course_assignments"
ON public.batch_course_assignments FOR ALL TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

DROP POLICY IF EXISTS "students_view_batch_course_assignments" ON public.batch_course_assignments;
CREATE POLICY "students_view_batch_course_assignments"
ON public.batch_course_assignments FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.batch_enrollments be
    WHERE be.batch_id = batch_course_assignments.batch_id
      AND be.student_id = auth.uid()
      AND be.is_active = true
  )
);
