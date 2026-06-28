-- =====================================================
-- DISABLE RLS UNTUK TESTING
-- Ini akan membuat SEMUA operasi database berhasil
-- Gunakan ini untuk testing, nanti kita aktifkan lagi
-- =====================================================

-- DISABLE RLS untuk semua table yang bermasalah
ALTER TABLE public.orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.spareparts DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.bengkels DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles DISABLE ROW LEVEL SECURITY;

-- Verifikasi status RLS
SELECT
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('orders', 'order_items', 'spareparts', 'bengkels', 'vehicles')
ORDER BY tablename;
