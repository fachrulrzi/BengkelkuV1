-- ============================================================
-- BENGKELIN APP - TAMBAHAN FITUR LOKASI, ONGKIR, RESI, RATING
-- Jalankan ini SETELAH supabase_fix_policies.sql
-- ============================================================

-- ─── Kolom lokasi bengkel ────────────────────────────────────
ALTER TABLE public.bengkels ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE public.bengkels ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- ─── Kolom lokasi user / Tabel users ─────────────────────────
-- Buat tabel public.users jika belum ada (misal di database baru)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name VARCHAR,
    email VARCHAR,
    phone VARCHAR,
    address TEXT,
    role VARCHAR DEFAULT 'customer',
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Pastikan kolom latitude, longitude, dan address ada
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS address TEXT;

-- Buat/update fungsi trigger untuk auto-sync data dari auth.users ke public.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.users (id, full_name, email, phone, role)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', ''),
    new.email,
    new.raw_user_meta_data->>'phone',
    COALESCE(new.raw_user_meta_data->>'role', 'customer')
  )
  ON CONFLICT (id) DO UPDATE
  SET
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    phone = EXCLUDED.phone,
    role = EXCLUDED.role;
  RETURN NEW;
END;
$$;

-- Daftarkan trigger ke auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Enable RLS pada public.users jika belum aktif
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Buat policies untuk public.users
DROP POLICY IF EXISTS "Allow public read access to users" ON public.users;
CREATE POLICY "Allow public read access to users"
ON public.users FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Allow users to update their own profile" ON public.users;
CREATE POLICY "Allow users to update their own profile"
ON public.users FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Lakukan sinkronisasi data awal untuk user yang sudah terlanjur daftar di auth.users
INSERT INTO public.users (id, full_name, email, phone, role)
SELECT 
  id,
  COALESCE(raw_user_meta_data->>'full_name', ''),
  email,
  raw_user_meta_data->>'phone',
  COALESCE(raw_user_meta_data->>'role', 'customer')
FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- ─── Kolom tambahan di orders ────────────────────────────────
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS tracking_number VARCHAR;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS shipping_photo_url VARCHAR;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS rating INT CHECK (rating BETWEEN 1 AND 5);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS rating_note TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS is_pickup BOOLEAN DEFAULT FALSE;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;
-- is_pickup = TRUE → customer ambil sendiri (tidak ada ongkir)
-- is_pickup = FALSE → barang dikirim ke alamat customer

-- ─── Kolom lokasi di service_bookings ────────────────────────
ALTER TABLE public.service_bookings ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE public.service_bookings ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- ─── Kolom rating di spareparts ──────────────────────────────
ALTER TABLE public.spareparts ADD COLUMN IF NOT EXISTS rating NUMERIC(3,1) DEFAULT 4.5;
ALTER TABLE public.spareparts ADD COLUMN IF NOT EXISTS review_count INT DEFAULT 0;
ALTER TABLE public.spareparts ADD COLUMN IF NOT EXISTS description TEXT;

-- ─── Fungsi cari bengkel terdekat (Haversine, tanpa PostGIS) ─
DROP FUNCTION IF EXISTS public.find_nearby_bengkels(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION);
CREATE OR REPLACE FUNCTION public.find_nearby_bengkels(
    customer_lat DOUBLE PRECISION,

    customer_lng DOUBLE PRECISION,
    radius_km DOUBLE PRECISION DEFAULT 50.0
)
RETURNS TABLE (
    id UUID,
    name VARCHAR,
    address VARCHAR,
    description TEXT,
    operating_hours VARCHAR,
    phone VARCHAR,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    distance_km DOUBLE PRECISION,
    status VARCHAR,
    specialization JSONB,
    rating NUMERIC
)
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT
        b.id,
        b.name,
        b.address,
        b.description,
        b.operating_hours,
        b.phone,
        b.latitude,
        b.longitude,
        (6371 * acos(
            LEAST(1.0,
                cos(radians(customer_lat))
                * cos(radians(b.latitude))
                * cos(radians(b.longitude) - radians(customer_lng))
                + sin(radians(customer_lat))
                * sin(radians(b.latitude))
            )
        )) AS distance_km,
        b.status,
        to_jsonb(b.specialization) AS specialization,
        COALESCE(
            (SELECT AVG(sp.rating) FROM public.spareparts sp WHERE sp.bengkel_id = b.id),
            4.5
        )::NUMERIC(3,1) AS rating
    FROM public.bengkels b
    WHERE
        b.latitude IS NOT NULL
        AND b.longitude IS NOT NULL
        AND b.status IN ('diterima', 'active')
        AND (6371 * acos(
            LEAST(1.0,
                cos(radians(customer_lat))
                * cos(radians(b.latitude))
                * cos(radians(b.longitude) - radians(customer_lng))
                + sin(radians(customer_lat))
                * sin(radians(b.latitude))
            )
        )) <= radius_km
    ORDER BY distance_km ASC;
$$;

GRANT EXECUTE ON FUNCTION public.find_nearby_bengkels(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated;

-- ─── Fungsi update rating sparepart dari semua order-nya ─────
DROP FUNCTION IF EXISTS public.recalculate_sparepart_rating(UUID);
CREATE OR REPLACE FUNCTION public.recalculate_sparepart_rating(p_sparepart_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    avg_rating NUMERIC;
    cnt INT;
BEGIN
    SELECT
        AVG(o.rating::NUMERIC),
        COUNT(*)
    INTO avg_rating, cnt
    FROM public.orders o
    JOIN public.order_items oi ON oi.order_id = o.id
    WHERE oi.sparepart_id = p_sparepart_id
      AND o.rating IS NOT NULL;

    UPDATE public.spareparts
    SET
        rating = ROUND(COALESCE(avg_rating, 4.5), 1),
        review_count = cnt
    WHERE id = p_sparepart_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.recalculate_sparepart_rating(UUID) TO authenticated;

-- ─── Policy update untuk orders (update rating & tracking) ───
DROP POLICY IF EXISTS "Users can update rating of their own orders" ON public.orders;
CREATE POLICY "Users can update rating of their own orders"
ON public.orders FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- ─── Policy update tracking untuk bengkel ────────────────────
DROP POLICY IF EXISTS "Bengkel owners can update tracking info" ON public.orders;
CREATE POLICY "Bengkel owners can update tracking info"
ON public.orders FOR UPDATE
TO authenticated
USING (public.order_belongs_to_bengkel_owner(id, auth.uid()))
WITH CHECK (public.order_belongs_to_bengkel_owner(id, auth.uid()));

-- ─── Storage bucket untuk foto pengiriman ────────────────────
INSERT INTO storage.buckets (id, name, public)
VALUES ('shipping_photos', 'shipping_photos', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Public read shipping photos" ON storage.objects;
DROP POLICY IF EXISTS "Auth upload shipping photos" ON storage.objects;

CREATE POLICY "Public read shipping photos"
ON storage.objects FOR SELECT
USING (bucket_id = 'shipping_photos');

CREATE POLICY "Auth upload shipping photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'shipping_photos');

-- ─── Verifikasi ──────────────────────────────────────────────
-- SELECT column_name FROM information_schema.columns
-- WHERE table_name = 'orders'
-- AND column_name IN ('tracking_number','shipping_photo_url','rating','is_pickup');
