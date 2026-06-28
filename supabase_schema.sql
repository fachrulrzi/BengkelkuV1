-- SQL migration script to set up tables and RLS for vehicles, vehicle configuration, and spare parts inventory.

-- 1. VEHICLE BRANDS TABLE
CREATE TABLE IF NOT EXISTS public.vehicle_brands (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for vehicle_brands
ALTER TABLE public.vehicle_brands ENABLE ROW LEVEL SECURITY;

-- Policies for vehicle_brands
CREATE POLICY "Allow read access for vehicle_brands to authenticated users"
ON public.vehicle_brands FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow full access for vehicle_brands to admins"
ON public.vehicle_brands FOR ALL
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


-- 2. VEHICLE TYPES TABLE
CREATE TABLE IF NOT EXISTS public.vehicle_types (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for vehicle_types
ALTER TABLE public.vehicle_types ENABLE ROW LEVEL SECURITY;

-- Policies for vehicle_types
CREATE POLICY "Allow read access for vehicle_types to authenticated users"
ON public.vehicle_types FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow full access for vehicle_types to admins"
ON public.vehicle_types FOR ALL
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


-- 3. SERVICE CATEGORIES TABLE
CREATE TABLE IF NOT EXISTS public.service_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for service_categories
ALTER TABLE public.service_categories ENABLE ROW LEVEL SECURITY;

-- Policies for service_categories
CREATE POLICY "Allow read access for service_categories to authenticated users"
ON public.service_categories FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow full access for service_categories to admins"
ON public.service_categories FOR ALL
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


-- 4. CUSTOMER VEHICLES TABLE
CREATE TABLE IF NOT EXISTS public.vehicles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    brand VARCHAR NOT NULL,
    model VARCHAR NOT NULL,
    year INT NOT NULL,
    license_plate VARCHAR NOT NULL,
    status VARCHAR DEFAULT 'Active' NOT NULL,
    type VARCHAR DEFAULT 'mobil' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for vehicles
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;

-- Policies for vehicles (users can only manage their own vehicles)
CREATE POLICY "Users can view their own vehicles"
ON public.vehicles FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Bengkel owners can view customer vehicles for orders"
ON public.vehicles FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.orders
        JOIN public.order_items ON orders.id = order_items.order_id
        JOIN public.spareparts ON order_items.sparepart_id = spareparts.id
        JOIN public.bengkels ON spareparts.bengkel_id = bengkels.id
        WHERE orders.user_id = vehicles.user_id AND bengkels.owner_id = auth.uid()
    )
);

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


-- 5. SPAREPARTS TABLE
CREATE TABLE IF NOT EXISTS public.spareparts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    bengkel_id UUID NOT NULL REFERENCES public.bengkels(id) ON DELETE CASCADE,
    name VARCHAR NOT NULL,
    sku VARCHAR NOT NULL UNIQUE,
    category VARCHAR NOT NULL,
    price NUMERIC(15, 2) DEFAULT 0.0 NOT NULL,
    stock INT DEFAULT 0 NOT NULL,
    image_url VARCHAR,
    discount_percentage INT DEFAULT 0 NOT NULL,
    rating NUMERIC(2, 1) DEFAULT 4.5 NOT NULL,
    review_count INT DEFAULT 0 NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Safe migration check for existing tables
ALTER TABLE public.spareparts ADD COLUMN IF NOT EXISTS image_url VARCHAR;
ALTER TABLE public.spareparts ADD COLUMN IF NOT EXISTS discount_percentage INT DEFAULT 0;
ALTER TABLE public.spareparts ADD COLUMN IF NOT EXISTS rating NUMERIC(2, 1) DEFAULT 4.5;
ALTER TABLE public.spareparts ADD COLUMN IF NOT EXISTS review_count INT DEFAULT 0;
ALTER TABLE public.spareparts ADD COLUMN IF NOT EXISTS description TEXT;

-- Enable RLS for spareparts
ALTER TABLE public.spareparts ENABLE ROW LEVEL SECURITY;

-- Policies for spareparts
CREATE POLICY "Allow read access for spareparts to authenticated users"
ON public.spareparts FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow write/update/delete access for spareparts to bengkel owner"
ON public.spareparts FOR ALL
TO authenticated
USING (
    bengkel_id IN (
        SELECT id FROM public.bengkels WHERE owner_id = auth.uid()
    )
)
WITH CHECK (
    bengkel_id IN (
        SELECT id FROM public.bengkels WHERE owner_id = auth.uid()
    )
);


-- 6. SPAREPART COMPATIBILITIES (JOIN TABLE)
CREATE TABLE IF NOT EXISTS public.sparepart_compatibilities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    sparepart_id UUID NOT NULL REFERENCES public.spareparts(id) ON DELETE CASCADE,
    vehicle_brand_id UUID NOT NULL REFERENCES public.vehicle_brands(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(sparepart_id, vehicle_brand_id)
);

-- Enable RLS for sparepart_compatibilities
ALTER TABLE public.sparepart_compatibilities ENABLE ROW LEVEL SECURITY;

-- Policies for sparepart_compatibilities
CREATE POLICY "Allow read access for sparepart_compatibilities to authenticated users"
ON public.sparepart_compatibilities FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow write/update/delete access for sparepart_compatibilities to bengkel owner"
ON public.sparepart_compatibilities FOR ALL
TO authenticated
USING (
    sparepart_id IN (
        SELECT id FROM public.spareparts WHERE bengkel_id IN (
            SELECT id FROM public.bengkels WHERE owner_id = auth.uid()
        )
    )
)
WITH CHECK (
    sparepart_id IN (
        SELECT id FROM public.spareparts WHERE bengkel_id IN (
            SELECT id FROM public.bengkels WHERE owner_id = auth.uid()
        )
    )
);


-- 7. STORAGE BUCKET FOR SPAREPARTS IMAGES
INSERT INTO storage.buckets (id, name, public)
VALUES ('spareparts', 'spareparts', true)
ON CONFLICT (id) DO NOTHING;

-- Drop existing storage policies if they exist to avoid duplicate errors
DROP POLICY IF EXISTS "Allow public read access to spareparts bucket" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated upload to spareparts bucket" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated update/delete to spareparts bucket" ON storage.objects;

-- Create policies for storage objects
CREATE POLICY "Allow public read access to spareparts bucket"
ON storage.objects FOR SELECT
USING (bucket_id = 'spareparts');

CREATE POLICY "Allow authenticated upload to spareparts bucket"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'spareparts');

CREATE POLICY "Allow authenticated update/delete to spareparts bucket"
ON storage.objects FOR ALL
TO authenticated
USING (bucket_id = 'spareparts')
WITH CHECK (bucket_id = 'spareparts');


-- 8. POLICIES FOR BENGKELS TABLE (IF NOT ALREADY CREATED)
-- Enable RLS for bengkels table just in case
ALTER TABLE public.bengkels ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow read access for bengkels to authenticated users" ON public.bengkels;
CREATE POLICY "Allow read access for bengkels to authenticated users"
ON public.bengkels FOR SELECT
TO authenticated
USING (true);


-- 9. ORDERS TABLE
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    total_price NUMERIC(15, 2) DEFAULT 0.0 NOT NULL,
    discount NUMERIC(15, 2) DEFAULT 0.0 NOT NULL,
    shipping_fee NUMERIC(15, 2) DEFAULT 0.0 NOT NULL,
    status VARCHAR DEFAULT 'Pending' NOT NULL,
    payment_method VARCHAR DEFAULT 'GoPay' NOT NULL,
    recipient_name VARCHAR,
    recipient_phone VARCHAR,
    shipping_address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Add new columns for existing tables
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS recipient_name VARCHAR;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS recipient_phone VARCHAR;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS shipping_address TEXT;

-- Enable RLS for orders
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- Policies for orders
CREATE POLICY "Users can view their own orders"
ON public.orders FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Bengkel owners can view orders for their products"
ON public.orders FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.order_items
        JOIN public.spareparts ON order_items.sparepart_id = spareparts.id
        JOIN public.bengkels ON spareparts.bengkel_id = bengkels.id
        WHERE order_items.order_id = orders.id AND bengkels.owner_id = auth.uid()
    )
);

CREATE POLICY "Bengkel owners can update status of orders for their products"
ON public.orders FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.order_items
        JOIN public.spareparts ON order_items.sparepart_id = spareparts.id
        JOIN public.bengkels ON spareparts.bengkel_id = bengkels.id
        WHERE order_items.order_id = orders.id AND bengkels.owner_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.order_items
        JOIN public.spareparts ON order_items.sparepart_id = spareparts.id
        JOIN public.bengkels ON spareparts.bengkel_id = bengkels.id
        WHERE order_items.order_id = orders.id AND bengkels.owner_id = auth.uid()
    )
);

CREATE POLICY "Users can insert their own orders"
ON public.orders FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);


-- 10. ORDER ITEMS TABLE
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    sparepart_id UUID NOT NULL REFERENCES public.spareparts(id) ON DELETE CASCADE,
    quantity INT NOT NULL,
    price NUMERIC(15, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for order_items
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- Policies for order_items
CREATE POLICY "Users can view their own order items"
ON public.order_items FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.orders
        WHERE orders.id = order_items.order_id AND orders.user_id = auth.uid()
    )
);

CREATE POLICY "Bengkel owners can view order items for their products"
ON public.order_items FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.spareparts
        JOIN public.bengkels ON spareparts.bengkel_id = bengkels.id
        WHERE spareparts.id = order_items.sparepart_id AND bengkels.owner_id = auth.uid()
    )
);

CREATE POLICY "Users can insert their own order items"
ON public.order_items FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.orders
        WHERE orders.id = order_items.order_id AND orders.user_id = auth.uid()
    )
);
