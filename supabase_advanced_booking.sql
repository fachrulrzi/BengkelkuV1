-- ============================================================
-- BENGKELIN APP - ALUR BOOKING TINGKAT LANJUT & LIVE TRACKING
-- Jalankan seluruh script ini di Supabase SQL Editor Anda
-- ============================================================

-- 1. Tambah Kolom ke Tabel service_bookings
ALTER TABLE public.service_bookings
ADD COLUMN IF NOT EXISTS initial_payment_status VARCHAR DEFAULT 'unpaid',
ADD COLUMN IF NOT EXISTS initial_payment_amount INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS additional_price INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS additional_payment_status VARCHAR DEFAULT 'none',
ADD COLUMN IF NOT EXISTS service_proof_url TEXT,
ADD COLUMN IF NOT EXISTS mechanic_latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS mechanic_longitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS rating_score INTEGER CHECK (rating_score BETWEEN 1 AND 5),
ADD COLUMN IF NOT EXISTS rating_comment TEXT,
ADD COLUMN IF NOT EXISTS rating_mechanic_name TEXT;

-- 2. Storage Bucket untuk Foto Bukti Pengerjaan Servis
INSERT INTO storage.buckets (id, name, public)
VALUES ('service_proofs', 'service_proofs', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Kebijakan RLS untuk storage bucket 'service_proofs'
DROP POLICY IF EXISTS "Public read service proofs" ON storage.objects;
DROP POLICY IF EXISTS "Public upload service proofs" ON storage.objects;
DROP POLICY IF EXISTS "Public manage service proofs" ON storage.objects;
DROP POLICY IF EXISTS "Auth upload service proofs" ON storage.objects;
DROP POLICY IF EXISTS "Auth manage service proofs" ON storage.objects;

CREATE POLICY "Public read service proofs"
ON storage.objects FOR SELECT
USING (bucket_id = 'service_proofs');

CREATE POLICY "Public upload service proofs"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'service_proofs');

CREATE POLICY "Public manage service proofs"
ON storage.objects FOR ALL
TO public
USING (bucket_id = 'service_proofs')
WITH CHECK (bucket_id = 'service_proofs');

-- 3. Hubungkan customer_id ke tabel users jika belum ada foreign key constraint
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_service_bookings_customer'
    ) THEN
        ALTER TABLE public.service_bookings
        ADD CONSTRAINT fk_service_bookings_customer
        FOREIGN KEY (customer_id)
        REFERENCES public.users(id)
        ON DELETE SET NULL;
    END IF;
END $$;
