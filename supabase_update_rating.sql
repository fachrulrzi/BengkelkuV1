-- ============================================================
-- BENGKELIN APP - UPDATE WORKSHOP RATINGS & REVIEWS COUNT
-- Run this script in the Supabase SQL Editor to update
-- the rating calculation and include reviews count.
-- ============================================================

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
    rating NUMERIC,
    reviews_count INT
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
            (
                WITH combined_ratings AS (
                    SELECT sb.rating_score::NUMERIC AS rating
                    FROM public.service_bookings sb
                    WHERE sb.bengkel_id = b.id AND sb.rating_score IS NOT NULL
                    UNION ALL
                    SELECT o.rating::NUMERIC AS rating
                    FROM public.orders o
                    WHERE o.rating IS NOT NULL
                      AND o.id IN (
                        SELECT oi.order_id 
                        FROM public.order_items oi
                        JOIN public.spareparts s ON s.id = oi.sparepart_id
                        WHERE s.bengkel_id = b.id
                      )
                )
                SELECT AVG(rating) FROM combined_ratings
            ),
            4.5
        )::NUMERIC(3,1) AS rating,
        COALESCE(
            (
                WITH combined_ratings AS (
                    SELECT sb.rating_score::NUMERIC AS rating
                    FROM public.service_bookings sb
                    WHERE sb.bengkel_id = b.id AND sb.rating_score IS NOT NULL
                    UNION ALL
                    SELECT o.rating::NUMERIC AS rating
                    FROM public.orders o
                    WHERE o.rating IS NOT NULL
                      AND o.id IN (
                        SELECT oi.order_id 
                        FROM public.order_items oi
                        JOIN public.spareparts s ON s.id = oi.sparepart_id
                        WHERE s.bengkel_id = b.id
                      )
                )
                SELECT COUNT(rating) FROM combined_ratings
            ),
            0
        )::INT AS reviews_count
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
