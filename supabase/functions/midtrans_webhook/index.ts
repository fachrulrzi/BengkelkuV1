// Supabase Edge Function: midtrans_webhook
// Menerima notifikasi pembayaran dari Midtrans lalu update status di Supabase

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

Deno.serve(async (req: Request) => {
  // Midtrans hanya kirim POST
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405 });
  }

  try {
    // 1. Parse notifikasi dari Midtrans
    const notification = await req.json();

    const { order_id, transaction_status, fraud_status } = notification;

    // Kalau tidak ada order_id (misal ping test dari dashboard), langsung OK
    if (!order_id || !transaction_status) {
      console.log('Test ping diterima dari Midtrans');
      return new Response(JSON.stringify({ message: 'OK' }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    console.log(`Webhook: order=${order_id}, status=${transaction_status}`);

    // 2. Konversi status Midtrans ke status di database kita
    let paymentStatus = 'menunggu pembayaran';

    if (transaction_status === 'capture') {
      paymentStatus = fraud_status === 'accept' ? 'lunas' : 'menunggu verifikasi';
    } else if (transaction_status === 'settlement') {
      paymentStatus = 'lunas';
    } else if (['cancel', 'deny', 'expire'].includes(transaction_status)) {
      paymentStatus = 'gagal';
    } else if (transaction_status === 'pending') {
      paymentStatus = 'menunggu pembayaran';
    }

    // 3. Buat koneksi Supabase dengan Service Role Key (bisa bypass RLS)
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    // 4. Update status pembayaran di tabel bookings
    const { error } = await supabase
      .from('bookings')
      .update({ payment_status: paymentStatus })
      .eq('id', order_id);

    if (error) {
      console.error('Gagal update database:', error.message);
      return new Response(JSON.stringify({ error: 'Gagal update database' }), { status: 500 });
    }

    console.log(`Berhasil update order ${order_id} => ${paymentStatus}`);

    // 5. Balas OK ke Midtrans agar tidak retry
    return new Response(JSON.stringify({ message: 'Webhook berhasil diproses' }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });

  } catch (err) {
    console.error('Error webhook:', err);
    // Tetap balas 200 agar Midtrans tidak retry terus-menerus
    return new Response(JSON.stringify({ message: 'OK' }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
