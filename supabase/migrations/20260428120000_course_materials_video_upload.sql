-- Migration: Allow video uploads in course-materials bucket
-- Updates the allowed MIME types to include common video formats

UPDATE storage.buckets
SET 
  allowed_mime_types = ARRAY[
    'application/pdf',
    'image/jpeg',
    'image/png',
    'image/webp',
    'video/mp4',
    'video/webm',
    'video/ogg',
    'video/quicktime',
    'video/x-msvideo',
    'video/mpeg'
  ],
  file_size_limit = 524288000  -- 500MB for videos
WHERE id = 'course-materials';
