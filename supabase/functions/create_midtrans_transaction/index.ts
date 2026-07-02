// Supabase Edge Function: create_midtrans_transaction
// Dipanggil dari Flutter untuk mendapatkan Midtrans Snap Token

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 1. Ambil Server Key dari Supabase Secrets (sudah di-set di dashboard)
    const serverKey = Deno.env.get('MIDTRANS_SERVER_KEY');
    const isSandbox = Deno.env.get('MIDTRANS_IS_SANDBOX') !== 'false';

    if (!serverKey) {
      return new Response(
        JSON.stringify({ error: 'MIDTRANS_SERVER_KEY tidak ditemukan di secrets.' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 2. Parse body dari Flutter
    const body = await req.json();
    const { transaction_details, item_details, customer_details } = body;

    if (!transaction_details?.order_id || !transaction_details?.gross_amount) {
      return new Response(
        JSON.stringify({ error: 'transaction_details (order_id, gross_amount) wajib diisi.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 3. Tentukan URL Midtrans (Sandbox atau Production)
    const midtransUrl = isSandbox
      ? 'https://app.sandbox.midtrans.com/snap/v1/transactions'
      : 'https://app.midtrans.com/snap/v1/transactions';

    // 4. Panggil API Midtrans Snap
    const midtransRes = await fetch(midtransUrl, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': `Basic ${btoa(serverKey + ':')}`,
      },
      body: JSON.stringify({ transaction_details, item_details, customer_details }),
    });

    const midtransData = await midtransRes.json();

    if (!midtransRes.ok) {
      console.error('Midtrans error:', midtransData);
      return new Response(
        JSON.stringify({ error: 'Gagal membuat transaksi di Midtrans', details: midtransData }),
        { status: midtransRes.status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 5. Kembalikan token ke Flutter
    return new Response(
      JSON.stringify({ token: midtransData.token, redirect_url: midtransData.redirect_url }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (err) {
    console.error('Error:', err);
    return new Response(
      JSON.stringify({ error: err.message || 'Internal Server Error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
