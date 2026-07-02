import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// WebView hanya diimport di platform non-web
// Kalau di web, cukup pakai url_launcher buka tab baru
import 'package:webview_flutter/webview_flutter.dart';

/// Enum hasil pembayaran setelah WebView ditutup
enum MidtransPaymentResult { success, pending, failed, cancelled }

/// Screen untuk menampilkan halaman Snap Midtrans.
/// - Mobile (Android/iOS): menggunakan WebView in-app
/// - Web (Chrome/Edge): membuka tab baru via url_launcher
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
  // Untuk mobile WebView
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasResult = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Di web: langsung buka tab baru
      _openWebPayment();
    } else {
      // Di mobile: pakai WebView in-app
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
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.snapUrl));
    }
  }

  Future<void> _openWebPayment() async {
    final uri = Uri.parse(widget.snapUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool _checkUrl(String url) {
    if (_hasResult) return true;
    final lower = url.toLowerCase();

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

    return false;
  }

  void _handleResult(MidtransPaymentResult result) {
    if (_hasResult || !mounted) return;
    _hasResult = true;
    debugPrint('[MidtransSnap] Payment result: $result');
    Navigator.of(context).pop(result);
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    // Web: tampilkan halaman konfirmasi manual
    if (kIsWeb) {
      return _buildWebConfirmationScreen();
    }

    // Mobile: tampilkan WebView
    return _buildMobileWebView();
  }

  /// Halaman konfirmasi untuk web (Chrome/Edge)
  Widget _buildWebConfirmationScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F0FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.open_in_new_rounded,
                  size: 44,
                  color: Color(0xFF1A73E8),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Halaman Pembayaran Dibuka',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B3A5E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Halaman pembayaran Midtrans telah dibuka di tab baru.\n\n'
                'Setelah selesai melakukan pembayaran, kembali ke sini dan pilih status pembayaranmu.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Buka ulang jika tab tertutup
              TextButton.icon(
                onPressed: _openWebPayment,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Buka Ulang Tab Pembayaran'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1A73E8),
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Status Pembayaran Saya:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1B3A5E),
                ),
              ),
              const SizedBox(height: 16),

              // Tombol Sukses
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _handleResult(MidtransPaymentResult.success),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('✅  Pembayaran Berhasil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B3A5E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Tombol Pending
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _handleResult(MidtransPaymentResult.pending),
                  icon: const Icon(Icons.hourglass_bottom_outlined),
                  label: const Text('⏳  Pembayaran Masih Diproses'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade700,
                    side: BorderSide(color: Colors.orange.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Tombol Batal
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _handleResult(MidtransPaymentResult.cancelled),
                  icon: const Icon(Icons.close),
                  label: const Text('Batalkan / Bayar Nanti'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// WebView in-app untuk mobile
  Widget _buildMobileWebView() {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_hasResult) {
          _showCancelDialog();
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
              if (!_hasResult) _showCancelDialog();
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF1B3A5E)),
              onPressed: () => _controller?.reload(),
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller!),
            if (_isLoading)
              Container(
                color: Colors.white,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF1B3A5E),
                        ),
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

  void _showCancelDialog() {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        _handleResult(MidtransPaymentResult.cancelled);
      }
    });
  }
}
