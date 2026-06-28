-- SQL function to safely decrement sparepart stock during checkout
-- Using SECURITY DEFINER to run with administrative privileges and bypass RLS constraints for users who don't own the workshop.

CREATE OR REPLACE FUNCTION public.decrease_sparepart_stock(
    p_sparepart_id UUID,
    p_quantity INT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.spareparts
    SET stock = GREATEST(0, stock - p_quantity)
    WHERE id = p_sparepart_id;
END;
$$;

-- Grant execute permission on the function to authenticated users
GRANT EXECUTE ON FUNCTION public.decrease_sparepart_stock(UUID, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.decrease_sparepart_stock(UUID, INT) TO anon;
GRANT EXECUTE ON FUNCTION public.decrease_sparepart_stock(UUID, INT) TO service_role;
