-- ============================================================
-- BENGKELIN APP - SECURITY DEFINER FOR SPAREPART REVIEWS
-- Jalankan ini di Supabase SQL Editor untuk memungkinkannya
-- membaca ulasan dari user lain tanpa melanggar RLS
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_sparepart_reviews(p_sparepart_id UUID)
RETURNS TABLE (
    rating INT,
    note TEXT,
    customer_name VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT 
      o.rating,
      o.rating_note,
      o.recipient_name,
      o.created_at
  FROM public.order_items oi
  JOIN public.orders o ON oi.order_id = o.id
  WHERE oi.sparepart_id = p_sparepart_id AND o.rating IS NOT NULL;
$$;

-- Grant access ke authenticated dan anon users
GRANT EXECUTE ON FUNCTION public.get_sparepart_reviews(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_sparepart_reviews(UUID) TO anon;
