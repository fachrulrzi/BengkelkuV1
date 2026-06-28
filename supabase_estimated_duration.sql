-- ============================================================
-- BENGKELIN APP - ADD ESTIMATED DURATION TO BOOKINGS
-- Jalankan script ini di Supabase SQL Editor Anda
-- ============================================================

-- Add estimated_duration column to service_bookings table
ALTER TABLE public.service_bookings
ADD COLUMN IF NOT EXISTS estimated_duration INTEGER DEFAULT 120;

-- Update any existing bookings to have the default duration if it's currently NULL
UPDATE public.service_bookings
SET estimated_duration = 120
WHERE estimated_duration IS NULL;
