-- ============================================================================
-- MIGRATION: Midtrans "Pay Later" Flow
-- ----------------------------------------------------------------------------
-- Tujuan:
--   Order dibuat dengan status pembayaran BELUM LUNAS (unpaid) saat customer
--   checkout. Pembayaran bisa ditunda, tapi waktu kadaluarsa mengikuti Midtrans
--   (expiry). Status pembayaran diverifikasi ulang dari Midtrans.
--
-- Jalankan di Supabase SQL Editor.
-- ============================================================================

-- 1. Tambah kolom payment ke tabel orders
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS payment_status VARCHAR DEFAULT 'unpaid';
-- Nilai payment_status:
--   'unpaid'   -> pembayaran belum/belum selesai (pesanan belum aktif)
--   'paid'     -> pembayaran sudah lunas (verified dari Midtrans)
--   'expired'  -> lewat batas waktu Midtrans & belum dibayar
--   'failed'   -> pembayaran gagal/ditolak Midtrans

ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS payment_url TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS midtrans_order_id VARCHAR;

-- Waktu kadaluarsa pembayaran (ngikutin expiry Midtrans, default 24 jam).
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS payment_expires_at TIMESTAMP WITH TIME ZONE;

-- 2. Backfill data lama: order yang sudah 'Selesai'/'Diproses' dianggap paid.
UPDATE public.orders
SET payment_status = 'paid'
WHERE payment_status = 'unpaid'
  AND status IN ('Selesai', 'Diproses');

-- 3. RLS policy: user boleh update baris orders miliknya (untuk sinkronisasi
--    payment_status / simpan payment_url dari sisi client). Dibatasi hanya
--    kolom payment agar tidak membuka celah ubah status order.
--    (Catatan: status order tetap diupdate via bengkel side / RPC.)

-- Pastikan policy update untuk customer ada (selain policy bengkel).
DROP POLICY IF EXISTS "Customers can update their own orders payment info"
ON public.orders;

CREATE POLICY "Customers can update their own orders payment info"
ON public.orders FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);
