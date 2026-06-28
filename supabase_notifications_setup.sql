-- 1. NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can delete their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "System can insert notifications" ON public.notifications;

-- Create policies for notifications
CREATE POLICY "Users can view their own notifications"
ON public.notifications FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications"
ON public.notifications FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own notifications"
ON public.notifications FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "System can insert notifications"
ON public.notifications FOR INSERT
TO authenticated, service_role
WITH CHECK (true);


-- 2. TRIGGER FOR ORDERS STATUS CHANGES & PLACEMENTS
CREATE OR REPLACE FUNCTION public.handle_order_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_bengkel_owner_id UUID;
    v_sparepart_name VARCHAR;
BEGIN
    -- A. IF NEW ORDER IS INSERTED (Customer orders product)
    IF (TG_OP = 'INSERT') THEN
        -- Notify Customer
        INSERT INTO public.notifications (user_id, title, message)
        VALUES (
            NEW.user_id,
            'Pesanan Berhasil Dibuat',
            'Pesanan Anda sebesar Rp ' || to_char(NEW.total_price, 'FM999,999,999') || ' telah berhasil dibuat dan sedang menunggu konfirmasi bengkel.'
        );

        -- Find the owner of the workshop for the ordered sparepart
        SELECT b.owner_id, s.name INTO v_bengkel_owner_id, v_sparepart_name
        FROM public.order_items oi
        JOIN public.spareparts s ON oi.sparepart_id = s.id
        JOIN public.bengkels b ON s.bengkel_id = b.id
        WHERE oi.order_id = NEW.id
        LIMIT 1;

        IF v_bengkel_owner_id IS NOT NULL THEN
            INSERT INTO public.notifications (user_id, title, message)
            VALUES (
                v_bengkel_owner_id,
                'Pesanan Masuk Baru',
                'Ada pesanan masuk baru untuk produk "' || COALESCE(v_sparepart_name, 'Produk') || '". Silakan periksa dashboard order Anda.'
            );
        END IF;

    -- B. IF ORDER STATUS IS UPDATED (Bengkel or Courier status updates)
    ELSIF (TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status) THEN
        -- Notify Customer about status change
        INSERT INTO public.notifications (user_id, title, message)
        VALUES (
            NEW.user_id,
            'Status Pesanan Diperbarui: ' || NEW.status,
            CASE NEW.status
                WHEN 'Diproses' THEN 'Pesanan Anda sedang diproses oleh bengkel.'
                WHEN 'Dikirim' THEN 'Pesanan Anda sedang dikirim oleh kurir.' || COALESCE(' No. Resi: ' || NEW.tracking_number, '')
                WHEN 'Selesai' THEN 'Pesanan Anda telah selesai. Terima kasih telah berbelanja!'
                WHEN 'Dibatalkan' THEN 'Pesanan Anda telah dibatalkan.'
                ELSE 'Status pesanan Anda telah berubah menjadi ' || NEW.status || '.'
            END
        );
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create order trigger
DROP TRIGGER IF EXISTS trg_order_notification ON public.orders;
CREATE TRIGGER trg_order_notification
AFTER INSERT OR UPDATE ON public.orders
FOR EACH ROW
EXECUTE FUNCTION public.handle_order_notification();


-- 3. TRIGGER FOR BENGKELS STATUS CHANGES (Admin Verification Approved/Rejected)
CREATE OR REPLACE FUNCTION public.handle_bengkel_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Notify Workshop Owner on verification status update
    IF (TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status) THEN
        INSERT INTO public.notifications (user_id, title, message)
        VALUES (
            NEW.owner_id,
            'Status Verifikasi Bengkel: ' || NEW.status,
            CASE NEW.status
                WHEN 'diterima' THEN 'Selamat! Pendaftaran bengkel Anda ("' || NEW.name || '") telah disetujui oleh admin.'
                WHEN 'di tolak' THEN 'Maaf, pendaftaran bengkel Anda ("' || NEW.name || '") ditolak oleh admin. Silakan periksa kembali berkas Anda.'
                ELSE 'Status verifikasi pendaftaran bengkel Anda telah diubah menjadi ' || NEW.status || '.'
            END
        );
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create bengkel verification trigger
DROP TRIGGER IF EXISTS trg_bengkel_notification ON public.bengkels;
CREATE TRIGGER trg_bengkel_notification
AFTER UPDATE ON public.bengkels
FOR EACH ROW
EXECUTE FUNCTION public.handle_bengkel_notification();


-- 4. TRIGGER FOR SERVICE BOOKINGS STATUS CHANGES & PLACEMENTS
CREATE OR REPLACE FUNCTION public.handle_booking_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_bengkel_owner_id UUID;
    v_bengkel_name VARCHAR;
    v_booking_code VARCHAR;
BEGIN
    -- Code booking singkat (cth: BKG-ABC)
    v_booking_code := 'BKG-' || UPPER(SUBSTRING(REPLACE(NEW.id::text, '-', ''), 1, 4));

    -- Get bengkel details
    SELECT owner_id, name INTO v_bengkel_owner_id, v_bengkel_name
    FROM public.bengkels
    WHERE id = NEW.bengkel_id;

    -- A. IF NEW BOOKING IS INSERTED
    IF (TG_OP = 'INSERT') THEN
        -- Notify Customer
        INSERT INTO public.notifications (user_id, title, message)
        VALUES (
            NEW.customer_id,
            'Booking Servis Berhasil Dibuat',
            'Booking servis Anda (' || v_booking_code || ') di ' || COALESCE(v_bengkel_name, 'bengkel') || ' berhasil dibuat. Menunggu konfirmasi dari bengkel.'
        );

        -- Notify Bengkel Owner
        IF v_bengkel_owner_id IS NOT NULL THEN
            INSERT INTO public.notifications (user_id, title, message)
            VALUES (
                v_bengkel_owner_id,
                'Booking Servis Baru Masuk',
                'Ada booking servis baru (' || v_booking_code || ') masuk. Silakan konfirmasi ketersediaan di dashboard bengkel Anda.'
            );
        END IF;

    -- B. IF BOOKING STATUS IS UPDATED
    ELSIF (TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status) THEN
        -- Notify Customer about status change
        INSERT INTO public.notifications (user_id, title, message)
        VALUES (
            NEW.customer_id,
            'Status Booking Diperbarui: ' || NEW.status,
            CASE NEW.status
                WHEN 'Diterima' THEN 'Booking Anda (' || v_booking_code || ') telah diterima. Silakan selesaikan pembayaran awal agar mekanik dikirim.'
                WHEN 'Menunggu Pembayaran Jasa' THEN 'Booking Anda (' || v_booking_code || ') disetujui. Silakan selesaikan pembayaran awal sebesar Rp ' || to_char(NEW.initial_payment_amount, 'FM999,999,999') || '.'
                WHEN 'Pembayaran Awal Lunas' THEN 'Pembayaran awal untuk ' || v_booking_code || ' berhasil diverifikasi. Bengkel akan segera menugaskan mekanik.'
                WHEN 'Mekanik Ditugaskan' THEN 'Mekanik ' || COALESCE(NEW.mechanic_name, '') || ' telah ditugaskan untuk booking ' || v_booking_code || '.'
                WHEN 'Menuju Lokasi' THEN 'Mekanik ' || COALESCE(NEW.mechanic_name, '') || ' sedang menuju lokasi Anda. Silakan pantau di menu tracking.'
                WHEN 'Sampai Lokasi' THEN 'Mekanik ' || COALESCE(NEW.mechanic_name, '') || ' telah sampai di lokasi Anda.'
                WHEN 'Diproses' THEN 'Pengerjaan servis kendaraan Anda untuk ' || v_booking_code || ' sedang diproses.'
                WHEN 'Menunggu Pembayaran Tambahan' THEN 'Pengerjaan servis selesai. Silakan lakukan pembayaran tambahan sebesar Rp ' || to_char(NEW.additional_price, 'FM999,999,999') || ' untuk suku cadang/jasa tambahan.'
                WHEN 'Selesai' THEN 'Servis ' || v_booking_code || ' telah selesai sepenuhnya. Terima kasih telah mempercayai layanan kami!'
                WHEN 'Ulasan Dikirim' THEN 'Terima kasih atas ulasan Anda untuk servis ' || v_booking_code || '!'
                WHEN 'Dibatalkan' THEN 'Booking ' || v_booking_code || ' Anda telah dibatalkan.'
                ELSE 'Status booking Anda (' || v_booking_code || ') telah berubah menjadi ' || NEW.status || '.'
            END
        );

        -- Notify Mechanic if assigned
        IF (NEW.status = 'Mekanik Ditugaskan' OR (NEW.status = OLD.status AND OLD.mechanic_id IS NULL AND NEW.mechanic_id IS NOT NULL)) THEN
            IF NEW.mechanic_id IS NOT NULL THEN
                INSERT INTO public.notifications (user_id, title, message)
                VALUES (
                    NEW.mechanic_id,
                    'Tugas Servis Baru',
                    'Anda telah ditugaskan untuk pengerjaan booking ' || v_booking_code || ' (' || COALESCE(NEW.service_category, 'Servis') || ').'
                );
            END IF;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create booking trigger
DROP TRIGGER IF EXISTS trg_booking_notification ON public.service_bookings;
CREATE TRIGGER trg_booking_notification
AFTER INSERT OR UPDATE ON public.service_bookings
FOR EACH ROW
EXECUTE FUNCTION public.handle_booking_notification();
