-- ============================================================
-- BENGKELIN APP - MIGRATION: Midtrans Integration for Bookings
-- Jalankan seluruh script ini di Supabase SQL Editor Anda
-- ============================================================

ALTER TABLE public.service_bookings
ADD COLUMN IF NOT EXISTS midtrans_order_id VARCHAR,
ADD COLUMN IF NOT EXISTS payment_url TEXT,
ADD COLUMN IF NOT EXISTS payment_expires_at TIMESTAMP WITH TIME ZONE;
