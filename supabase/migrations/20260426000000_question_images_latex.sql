-- ============================================================
-- CoachLMS: Add image support and has_latex flag to questions
-- Also creates question-images storage bucket with RLS
-- ============================================================

-- ─── 1. ALTER questions TABLE ────────────────────────────────

ALTER TABLE public.questions
ADD COLUMN IF NOT EXISTS question_image_url TEXT,
ADD COLUMN IF NOT EXISTS option_a_image_url TEXT,
ADD COLUMN IF NOT EXISTS option_b_image_url TEXT,
ADD COLUMN IF NOT EXISTS option_c_image_url TEXT,
ADD COLUMN IF NOT EXISTS option_d_image_url TEXT,
ADD COLUMN IF NOT EXISTS has_latex BOOLEAN NOT NULL DEFAULT false;

-- ─── 2. INDEXES ──────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_questions_has_latex ON public.questions(has_latex);

-- ─── 3. STORAGE BUCKET ───────────────────────────────────────
-- Create question-images bucket (public so images render in test engine)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'question-images',
    'question-images',
    true,
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml']
)
ON CONFLICT (id) DO NOTHING;

-- ─── 4. STORAGE RLS POLICIES ─────────────────────────────────

-- Anyone authenticated can read question images
DROP POLICY IF EXISTS "question_images_public_read" ON storage.objects;
CREATE POLICY "question_images_public_read"
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'question-images');

-- Only admins can upload question images
DROP POLICY IF EXISTS "question_images_admin_insert" ON storage.objects;
CREATE POLICY "question_images_admin_insert"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
    bucket_id = 'question-images'
    AND public.is_admin_user()
);

-- Only admins can update question images
DROP POLICY IF EXISTS "question_images_admin_update" ON storage.objects;
CREATE POLICY "question_images_admin_update"
ON storage.objects FOR UPDATE TO authenticated
USING (
    bucket_id = 'question-images'
    AND public.is_admin_user()
);

-- Only admins can delete question images
DROP POLICY IF EXISTS "question_images_admin_delete" ON storage.objects;
CREATE POLICY "question_images_admin_delete"
ON storage.objects FOR DELETE TO authenticated
USING (
    bucket_id = 'question-images'
    AND public.is_admin_user()
);
