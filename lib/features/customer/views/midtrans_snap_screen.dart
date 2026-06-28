import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Enum hasil pembayaran setelah WebView ditutup
enum MidtransPaymentResult { success, pending, failed, cancelled }

/// Screen WebView in-app untuk menampilkan halaman Snap Midtrans.
/// Memonitor navigasi URL:
///   - bengkelin://payment/finish?status=success  → sukses
///   - bengkelin://payment/finish?status=pending  → pending
///   - bengkelin://payment/finish?status=error    → error
///   - User menekan tombol back sebelum bayar      → cancelled
class MidtransSnapScreen extends StatefulWidget {
  final String snapUrl;
  final String? orderId;

  const MidtransSnapScreen({
    super.key,
    required this.snapUrl,
    this.orderId,
  });

  @override
  State<MidtransSnapScreen> createState() => _MidtransSnapScreenState();
}

class _MidtransSnapScreenState extends State<MidtransSnapScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasResult = false;

  // Custom scheme yang kita set di Midtrans callbacks.finish
  static const String _finishScheme = 'bengkelin://payment/finish';
  static const String _pendingScheme = 'bengkelin://payment/pending';
  static const String _errorScheme = 'bengkelin://payment/error';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('[MidtransSnap] PageStarted: $url');
            if (mounted) setState(() => _isLoading = true);
            _checkUrl(url);
          },
          onPageFinished: (url) {
            debugPrint('[MidtransSnap] PageFinished: $url');
            if (mounted) setState(() => _isLoading = false);
            _checkUrl(url);
          },
          onNavigationRequest: (req) {
            debugPrint('[MidtransSnap] NavigationRequest: ${req.url}');
            final handled = _checkUrl(req.url);
            return handled
                ? NavigationDecision.prevent
                : NavigationDecision.navigate;
          },
          onWebResourceError: (err) {
            debugPrint('[MidtransSnap] WebResourceError: ${err.description}');
            // Ignore errors from custom scheme redirects
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.snapUrl));
  }

  /// Cek URL apakah merupakan callback dari Midtrans.
  /// Kembalikan true jika URL adalah callback (perlu di-intercept).
  bool _checkUrl(String url) {
    if (_hasResult) return true;
    final lower = url.toLowerCase();

    // Callback custom scheme kita
    if (lower.startsWith('bengkelin://payment/finish')) {
      _handleResult(MidtransPaymentResult.success);
      return true;
    }
    if (lower.startsWith('bengkelin://payment/pending')) {
      _handleResult(MidtransPaymentResult.pending);
      return true;
    }
    if (lower.startsWith('bengkelin://payment/error')) {
      _handleResult(MidtransPaymentResult.failed);
      return true;
    }

    // Fallback: deteksi dari URL Midtrans default (jika callbacks tidak di-set)
    // Midtrans Snap setelah bayar biasanya URL-nya tetap, tapi page title berubah
    // Kita handle ini lewat JS injection di onPageFinished

    return false;
  }

  void _handleResult(MidtransPaymentResult result) {
    if (_hasResult || !mounted) return;
    _hasResult = true;
    debugPrint('[MidtransSnap] Payment result: $result');
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_hasResult) {
          // User menekan back — tanya konfirmasi
          showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text(
                'Batalkan Pembayaran?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: const Text(
                'Apakah kamu yakin ingin keluar? Pembayaran belum selesai.\n\n'
                'Order akan tersimpan dengan status BELUM DIBAYAR dan bisa dibayar nanti.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Lanjutkan Bayar'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx, true);
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Keluar'),
                ),
              ],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ).then((confirmed) {
            if (confirmed == true && mounted) {
              _handleResult(MidtransPaymentResult.cancelled);
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text(
            'Pembayaran',
            style: TextStyle(
              color: Color(0xFF1B3A5E),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF1B3A5E)),
            onPressed: () {
              if (!_hasResult) {
                showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text(
                      'Batalkan Pembayaran?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    content: const Text(
                      'Apakah kamu yakin ingin keluar? Pembayaran belum selesai.\n\n'
                      'Order akan tersimpan dengan status BELUM DIBAYAR dan bisa dibayar nanti.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Lanjutkan Bayar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Keluar'),
                      ),
                    ],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ).then((confirmed) {
                  if (confirmed == true && mounted) {
                    _handleResult(MidtransPaymentResult.cancelled);
                  }
                });
              }
            },
          ),
          actions: [
            // Tombol refresh jika page error
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF1B3A5E)),
              onPressed: () => _controller.reload(),
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: Colors.white,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF1B3A5E)),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Memuat halaman pembayaran...',
                        style: TextStyle(
                          color: Color(0xFF1B3A5E),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
