-- ============================================================
-- BENGKELIN APP - FITUR PELAPORAN BENGKEL & SUSPENSI BENGKEL
-- Jalankan skrip ini di SQL Editor Supabase Anda
-- ============================================================

-- 1. Buat Tabel workshop_reports
CREATE TABLE IF NOT EXISTS public.workshop_reports (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    reporter_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    bengkel_id UUID NOT NULL REFERENCES public.bengkels(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    evidence_url VARCHAR,
    status VARCHAR DEFAULT 'pending' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Aktifkan Row Level Security (RLS)
ALTER TABLE public.workshop_reports ENABLE ROW LEVEL SECURITY;

-- 2. Kebijakan RLS untuk tabel workshop_reports
DROP POLICY IF EXISTS "Allow read access for workshop_reports to authenticated users" ON public.workshop_reports;
CREATE POLICY "Allow read access for workshop_reports to authenticated users"
ON public.workshop_reports FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Allow insert for workshop_reports to authenticated users" ON public.workshop_reports;
CREATE POLICY "Allow insert for workshop_reports to authenticated users"
ON public.workshop_reports FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = reporter_id);

DROP POLICY IF EXISTS "Allow full access for workshop_reports to admins" ON public.workshop_reports;
CREATE POLICY "Allow full access for workshop_reports to admins"
ON public.workshop_reports FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- 3. Storage Bucket untuk bukti pelaporan (report_proofs)
INSERT INTO storage.buckets (id, name, public)
VALUES ('report_proofs', 'report_proofs', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Hapus kebijakan storage jika sudah ada untuk menghindari error duplikasi
DROP POLICY IF EXISTS "Allow public read access to report_proofs bucket" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated upload to report_proofs bucket" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated update/delete to report_proofs bucket" ON storage.objects;

-- Buat kebijakan storage untuk bucket report_proofs
CREATE POLICY "Allow public read access to report_proofs bucket"
ON storage.objects FOR SELECT
USING (bucket_id = 'report_proofs');

CREATE POLICY "Allow authenticated upload to report_proofs bucket"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'report_proofs');

CREATE POLICY "Allow authenticated update/delete to report_proofs bucket"
ON storage.objects FOR ALL
TO authenticated
USING (bucket_id = 'report_proofs')
WITH CHECK (bucket_id = 'report_proofs');

-- 4. Fungsi pembantu & Kebijakan RLS tambahan agar Admin dapat mengelola tabel public.users tanpa rekursi RLS
CREATE OR REPLACE FUNCTION public.is_admin(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE id = p_user_id AND role = 'admin'
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_admin(UUID) TO authenticated, anon;

DROP POLICY IF EXISTS "Allow admin to manage all users" ON public.users;
CREATE POLICY "Allow admin to manage all users"
ON public.users FOR ALL
TO authenticated
USING (
    public.is_admin(auth.uid())
)
WITH CHECK (
    public.is_admin(auth.uid())
);

-- 5. Fungsi postgres (RPC) untuk mendaftarkan user baru oleh Admin (menghindari login otomatis)
CREATE OR REPLACE FUNCTION public.create_new_user(
    p_email TEXT,
    p_password TEXT,
    p_full_name TEXT,
    p_phone TEXT,
    p_address TEXT,
    p_role TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_user_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = lower(p_email)) THEN
        RAISE EXCEPTION 'Email % sudah terdaftar.', p_email;
    END IF;

    INSERT INTO auth.users (
        id,
        email,
        phone,
        phone_confirmed_at,
        encrypted_password,
        email_confirmed_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at,
        role,
        aud
    )
    VALUES (
        gen_random_uuid(),
        lower(p_email),
        p_phone,
        now(),
        extensions.crypt(p_password, extensions.gen_salt('bf')),
        now(),
        jsonb_build_object('provider', 'email', 'providers', array['email']),
        jsonb_build_object('full_name', p_full_name, 'phone', p_phone, 'role', p_role),
        now(),
        now(),
        'authenticated',
        'authenticated'
    )
    RETURNING id INTO new_user_id;

    -- Insert identity ke auth.identities agar user bisa login
    INSERT INTO auth.identities (
        id,
        user_id,
        provider_id,
        provider,
        identity_data,
        created_at,
        updated_at
    )
    VALUES (
        gen_random_uuid(),
        new_user_id,
        new_user_id::text,
        'email',
        jsonb_build_object(
            'sub', new_user_id::text,
            'role', p_role,
            'email', lower(p_email),
            'phone', p_phone,
            'full_name', p_full_name,
            'email_verified', true,
            'phone_verified', false
        ),
        now(),
        now()
    );

    -- Update info address di tabel public.users
    UPDATE public.users
    SET address = p_address
    WHERE id = new_user_id;

    RETURN new_user_id;
END;
$$;

-- 6. Fungsi postgres (RPC) untuk mengubah data user oleh Admin (Email dibuat immutable/read-only)
CREATE OR REPLACE FUNCTION public.update_existing_user(
    p_user_id UUID,
    p_email TEXT,
    p_full_name TEXT,
    p_phone TEXT,
    p_address TEXT,
    p_role TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update auth.users (TIDAK mengubah email untuk kestabilan otentikasi)
    UPDATE auth.users
    SET 
        phone = p_phone,
        raw_user_meta_data = jsonb_build_object(
            'full_name', p_full_name,
            'phone', p_phone,
            'role', p_role
        ),
        updated_at = now()
    WHERE id = p_user_id;

    -- Upsert identity ke auth.identities (menggunakan email lama dari parameter, tidak mengubah pemetaan email)
    INSERT INTO auth.identities (
        id,
        user_id,
        provider_id,
        provider,
        identity_data,
        created_at,
        updated_at
    )
    VALUES (
        gen_random_uuid(),
        p_user_id,
        p_user_id::text,
        'email',
        jsonb_build_object(
            'sub', p_user_id::text,
            'role', p_role,
            'email', lower(p_email),
            'phone', p_phone,
            'full_name', p_full_name,
            'email_verified', true,
            'phone_verified', false
        ),
        now(),
        now()
    )
    ON CONFLICT (provider_id, provider) DO UPDATE
    SET
        identity_data = EXCLUDED.identity_data,
        updated_at = now();

    -- Update public.users (TIDAK mengubah email)
    UPDATE public.users
    SET
        full_name = p_full_name,
        phone = p_phone,
        address = p_address,
        role = p_role
    WHERE id = p_user_id;
END;
$$;

-- 7. Fungsi postgres (RPC) untuk menghapus user secara permanen
CREATE OR REPLACE FUNCTION public.delete_existing_user(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM auth.users WHERE id = p_user_id;
END;
$$;

-- 8. Fungsi postgres (RPC) untuk inspeksi kolom auth.users guna debugging
CREATE OR REPLACE FUNCTION public.inspect_user(p_email TEXT)
RETURNS TABLE (
    u_id UUID,
    u_email VARCHAR,
    u_email_confirmed_at TIMESTAMP WITH TIME ZONE,
    u_email_change VARCHAR,
    u_email_change_token_new VARCHAR,
    u_email_change_confirm_status SMALLINT,
    u_raw_user_meta_data JSONB
)
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT 
        id, 
        email, 
        email_confirmed_at, 
        email_change, 
        email_change_token_new, 
        email_change_confirm_status, 
        raw_user_meta_data
    FROM auth.users
    WHERE email = p_email OR email_change = p_email;
$$;

GRANT EXECUTE ON FUNCTION public.inspect_user(TEXT) TO authenticated, anon;
