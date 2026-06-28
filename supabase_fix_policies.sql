-- ============================================================
-- BENGKELIN APP - SUPABASE RLS POLICY FIX
-- MASALAH: Infinite recursion antara tabel orders dan order_items
-- SOLUSI: Gunakan SECURITY DEFINER functions untuk memutus recursion
-- Jalankan seluruh script ini di Supabase SQL Editor
-- ============================================================


-- ============================================================
-- STEP 1: DROP SEMUA POLICY LAMA (orders & order_items)
-- ============================================================
DROP POLICY IF EXISTS "Users can view their own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can insert their own orders" ON public.orders;
DROP POLICY IF EXISTS "Bengkel owners can view orders for their products" ON public.orders;
DROP POLICY IF EXISTS "Bengkel owners can update order status" ON public.orders;
DROP POLICY IF EXISTS "Bengkel owners can update status of orders for their products" ON public.orders;
DROP POLICY IF EXISTS "Admin can view all orders" ON public.orders;

DROP POLICY IF EXISTS "Users can view their own order items" ON public.order_items;
DROP POLICY IF EXISTS "Users can insert their own order items" ON public.order_items;
DROP POLICY IF EXISTS "Bengkel owners can view order items for their products" ON public.order_items;
DROP POLICY IF EXISTS "Bengkel owners can update order items" ON public.order_items;


-- ============================================================
-- STEP 2: BUAT SECURITY DEFINER FUNCTIONS
-- Fungsi ini bypass RLS saat dijalankan, sehingga tidak ada recursion
-- ============================================================

-- Fungsi: cek apakah order_id dimiliki oleh user_id tertentu
CREATE OR REPLACE FUNCTION public.order_belongs_to_user(p_order_id UUID, p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.orders
    WHERE id = p_order_id AND user_id = p_user_id
  );
$$;

-- Fungsi: cek apakah order_id berisi sparepart milik bengkel owner
CREATE OR REPLACE FUNCTION public.order_belongs_to_bengkel_owner(p_order_id UUID, p_owner_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.order_items oi
    JOIN public.spareparts sp ON oi.sparepart_id = sp.id
    JOIN public.bengkels b ON sp.bengkel_id = b.id
    WHERE oi.order_id = p_order_id AND b.owner_id = p_owner_id
  );
$$;

-- Fungsi: cek apakah sparepart_id milik bengkel owner tertentu
CREATE OR REPLACE FUNCTION public.sparepart_belongs_to_bengkel_owner(p_sparepart_id UUID, p_owner_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.spareparts sp
    JOIN public.bengkels b ON sp.bengkel_id = b.id
    WHERE sp.id = p_sparepart_id AND b.owner_id = p_owner_id
  );
$$;

-- Grant execute ke authenticated users
GRANT EXECUTE ON FUNCTION public.order_belongs_to_user(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.order_belongs_to_bengkel_owner(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.sparepart_belongs_to_bengkel_owner(UUID, UUID) TO authenticated;


-- ============================================================
-- STEP 3: BUAT POLICY BARU UNTUK TABEL orders
-- (Menggunakan fungsi SECURITY DEFINER, tidak ada subquery ke order_items)
-- ============================================================

-- Customer bisa lihat ordernya sendiri
CREATE POLICY "Users can view their own orders"
ON public.orders FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Customer bisa insert order untuk dirinya sendiri
CREATE POLICY "Users can insert their own orders"
ON public.orders FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Bengkel owner bisa lihat order yang mengandung produknya
-- Menggunakan fungsi SECURITY DEFINER → tidak ada recursion
CREATE POLICY "Bengkel owners can view orders for their products"
ON public.orders FOR SELECT
TO authenticated
USING (
  public.order_belongs_to_bengkel_owner(id, auth.uid())
);

-- Bengkel owner bisa update status order yang mengandung produknya
CREATE POLICY "Bengkel owners can update order status"
ON public.orders FOR UPDATE
TO authenticated
USING (
  public.order_belongs_to_bengkel_owner(id, auth.uid())
)
WITH CHECK (
  public.order_belongs_to_bengkel_owner(id, auth.uid())
);


-- ============================================================
-- STEP 4: BUAT POLICY BARU UNTUK TABEL order_items
-- (Menggunakan fungsi SECURITY DEFINER, tidak ada subquery ke orders secara langsung)
-- ============================================================

-- Customer bisa lihat item dari ordernya sendiri
-- Menggunakan fungsi SECURITY DEFINER → tidak ada recursion
CREATE POLICY "Users can view their own order items"
ON public.order_items FOR SELECT
TO authenticated
USING (
  public.order_belongs_to_user(order_id, auth.uid())
);

-- Customer bisa insert item ke order miliknya
CREATE POLICY "Users can insert their own order items"
ON public.order_items FOR INSERT
TO authenticated
WITH CHECK (
  public.order_belongs_to_user(order_id, auth.uid())
);

-- Bengkel owner bisa lihat item yang sparepartnya milik mereka
-- Menggunakan fungsi SECURITY DEFINER → tidak ada recursion
CREATE POLICY "Bengkel owners can view order items for their products"
ON public.order_items FOR SELECT
TO authenticated
USING (
  public.sparepart_belongs_to_bengkel_owner(sparepart_id, auth.uid())
);

-- Bengkel owner bisa update item yang sparepartnya milik mereka
CREATE POLICY "Bengkel owners can update order items"
ON public.order_items FOR UPDATE
TO authenticated
USING (
  public.sparepart_belongs_to_bengkel_owner(sparepart_id, auth.uid())
);


-- ============================================================
-- STEP 5: FIX Storage bucket spareparts
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('spareparts', 'spareparts', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Public read spareparts" ON storage.objects;
DROP POLICY IF EXISTS "Auth upload spareparts" ON storage.objects;
DROP POLICY IF EXISTS "Auth manage spareparts" ON storage.objects;

CREATE POLICY "Public read spareparts"
ON storage.objects FOR SELECT
USING (bucket_id = 'spareparts');

CREATE POLICY "Auth upload spareparts"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'spareparts');

CREATE POLICY "Auth manage spareparts"
ON storage.objects FOR ALL
TO authenticated
USING (bucket_id = 'spareparts')
WITH CHECK (bucket_id = 'spareparts');


-- ============================================================
-- STEP 6: Pastikan tabel & kolom yang dibutuhkan ada
-- ============================================================

-- Tabel orders - kolom opsional
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS recipient_name VARCHAR;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS recipient_phone VARCHAR;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS shipping_address TEXT;

-- Tabel spareparts - kolom opsional
ALTER TABLE public.spareparts ADD COLUMN IF NOT EXISTS image_url VARCHAR;
ALTER TABLE public.spareparts ADD COLUMN IF NOT EXISTS discount_percentage INT DEFAULT 0;
ALTER TABLE public.spareparts ADD COLUMN IF NOT EXISTS rating NUMERIC(3, 1) DEFAULT 4.5;
ALTER TABLE public.spareparts ADD COLUMN IF NOT EXISTS review_count INT DEFAULT 0;
ALTER TABLE public.spareparts ADD COLUMN IF NOT EXISTS description TEXT;


-- ============================================================
-- STEP 7: Policy READ untuk tabel pendukung
-- ============================================================

-- Spareparts: semua user authenticated bisa baca
DROP POLICY IF EXISTS "Allow read access for spareparts to authenticated users" ON public.spareparts;
CREATE POLICY "Allow read access for spareparts to authenticated users"
ON public.spareparts FOR SELECT
TO authenticated
USING (true);

-- Bengkels: semua user authenticated bisa baca
ALTER TABLE public.bengkels ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow read access for bengkels to authenticated users" ON public.bengkels;
CREATE POLICY "Allow read access for bengkels to authenticated users"
ON public.bengkels FOR SELECT
TO authenticated
USING (true);

-- Vehicle brands: semua user authenticated bisa baca
DROP POLICY IF EXISTS "Allow read access for vehicle_brands to authenticated users" ON public.vehicle_brands;
CREATE POLICY "Allow read access for vehicle_brands to authenticated users"
ON public.vehicle_brands FOR SELECT
TO authenticated
USING (true);

-- Vehicles: user hanya bisa akses kendaraannya sendiri
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own vehicles" ON public.vehicles;
DROP POLICY IF EXISTS "Users can insert their own vehicles" ON public.vehicles;
DROP POLICY IF EXISTS "Users can update their own vehicles" ON public.vehicles;
DROP POLICY IF EXISTS "Users can delete their own vehicles" ON public.vehicles;

CREATE POLICY "Users can view their own vehicles"
ON public.vehicles FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own vehicles"
ON public.vehicles FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own vehicles"
ON public.vehicles FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own vehicles"
ON public.vehicles FOR DELETE
TO authenticated
USING (auth.uid() = user_id);


-- ============================================================
-- SELESAI - Cek hasilnya:
-- SELECT schemaname, tablename, policyname FROM pg_policies
-- WHERE tablename IN ('orders', 'order_items');
-- ============================================================
