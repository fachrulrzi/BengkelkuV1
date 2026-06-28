import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';

class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  State<AdminVerificationScreen> createState() => _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _bengkels = [];
  bool _isLoading = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _fetchBengkels();
  }

  Future<void> _fetchBengkels() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('bengkels')
          .select('*, users(full_name, email)')
          .inFilter('status', ['tahap 2', 'diterima', 'active', 'di tolak'])
          .order('created_at', ascending: false);
      setState(() => _bengkels = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Error fetching bengkels: $e');
    }
    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _filteredBengkels {
    if (_filterStatus == 'all') return _bengkels;
    if (_filterStatus == 'diterima') {
      return _bengkels.where((b) => b['status'] == 'diterima' || b['status'] == 'active').toList();
    }
    return _bengkels.where((b) => b['status'] == _filterStatus).toList();
  }

  int get _pendingCount =>
      _bengkels.where((b) => b['status'] == 'tahap 2').length;

  Future<void> _approve(Map<String, dynamic> bengkel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Verifikasi'),
        content: Text('Verifikasi bengkel "${bengkel['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Verifikasi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _supabase.from('bengkels').update({
        'status': 'diterima',
        'rejection_reason': null,
      }).eq('id', bengkel['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${bengkel['name']} berhasil diverifikasi!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _filterStatus = 'diterima');
        _fetchBengkels();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _reject(Map<String, dynamic> bengkel) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          scrollable: true,
          title: const Text('Tolak Verifikasi', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bengkel: ${bengkel['name']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              const Text('Berikan keterangan alasan penolakan\n(akan ditampilkan ke mitra):',
                  style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextField(
                controller: reasonCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Contoh: Dokumen KTP tidak terbaca, foto bengkel kurang jelas...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              const Text(
                '* Mitra akan melihat catatan alasan penolakan ini di dashboard mereka agar dapat melakukan pengajuan ulang.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (reasonCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Alasan penolakan wajib diisi')),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Tolak', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await _supabase.from('bengkels').update({
        'status': 'di tolak',
        'rejection_reason': reasonCtrl.text.trim(),
      }).eq('id', bengkel['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verifikasi ditolak, mitra akan melihat keterangan.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _filterStatus = 'di tolak');
        _fetchBengkels();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _viewDocument(String? url) async {
    if (url == null || url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dokumen belum diupload')),
        );
      }
      return;
    }

    if (mounted) {
      final isPdf = url.toLowerCase().contains('.pdf');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
              title: const Text('Dokumen Mitra', style: TextStyle(color: Colors.black, fontSize: 16)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                  tooltip: 'Buka di Browser / Unduh',
                )
              ],
            ),
            body: isPdf
                ? PdfPreview(
                    build: (format) async {
                      final response = await http.get(Uri.parse(url));
                      return response.bodyBytes;
                    },
                    allowPrinting: false,
                    allowSharing: false,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    scrollViewDecoration: const BoxDecoration(color: Colors.grey),
                  )
                : InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const CircularProgressIndicator();
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Padding(
                            padding: const EdgeInsets.all(30),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text('Gagal memuat pratinjau. File mungkin bukan gambar atau tidak dapat diakses.', textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () async {
                                    final uri = Uri.parse(url);
                                    try {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    } catch (_) {}
                                  },
                                  child: const Text('Buka di Browser'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'diterima':
      case 'active':
        return Colors.green;
      case 'tahap 2':
        return Colors.orange;
      case 'selesai tahap 1':
        return Colors.blue;
      case 'di tolak':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'diterima':
      case 'active':
        return 'Terverifikasi';
      case 'tahap 2':
        return 'Menunggu Verifikasi';
      case 'selesai tahap 1':
        return 'Profil Lengkap';
      case 'di tolak':
        return 'Ditolak';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Banner pending count
                if (_pendingCount > 0)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '$_pendingCount mitra menunggu verifikasi',
                          style: TextStyle(
                            color: Colors.amber.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Filter tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'Semua'),
                      const SizedBox(width: 8),
                      _buildFilterChip('tahap 2', 'Menunggu'),
                      const SizedBox(width: 8),
                      _buildFilterChip('diterima', 'Terverifikasi'),
                      const SizedBox(width: 8),
                      _buildFilterChip('di tolak', 'Ditolak'),
                    ],
                  ),
                ),
                // List
                Expanded(
                  child: _filteredBengkels.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.storefront_outlined, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text('Tidak ada mitra', style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchBengkels,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _filteredBengkels.length,
                            itemBuilder: (ctx, i) => _buildBengkelCard(_filteredBengkels[i]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final selected = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBengkelCard(Map<String, dynamic> bengkel) {
    final status = bengkel['status'] ?? 'pending';
    final ownerName = bengkel['users']?['full_name'] ?? 'Unknown';
    final canAction = status == 'tahap 2';
    final isRejected = status == 'di tolak';
    final rejectionReason = bengkel['rejection_reason'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        border: isRejected ? Border.all(color: Colors.red.shade200) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bengkel['name'] ?? 'Nama Bengkel',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ownerName,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    if (bengkel['address'] != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              bengkel['address'],
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (bengkel['operating_hours'] != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.access_time, size: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              bengkel['operating_hours'],
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statusColor(status).withValues(alpha: 0.3)),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    color: _statusColor(status),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          // Catatan penolakan
          if (isRejected && rejectionReason != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Colors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Alasan: $rejectionReason',
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Deskripsi
          if (bengkel['description'] != null) ...[
            const SizedBox(height: 8),
            Text(
              bengkel['description'],
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // Action buttons
          if (canAction || (bengkel['document_url'] != null && bengkel['document_url'].toString().isNotEmpty)) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (bengkel['document_url'] != null && bengkel['document_url'].toString().isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _viewDocument(bengkel['document_url']),
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('Lihat Dokumen', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                if (canAction)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _approve(bengkel),
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Setuju', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _reject(bengkel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          elevation: 0,
                          side: BorderSide(color: Colors.red.shade200),
                        ),
                        child: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
