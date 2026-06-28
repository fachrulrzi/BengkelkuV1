import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/workshop_report_viewmodel.dart';

class WorkshopReportScreen extends StatefulWidget {
  final Map<String, dynamic> bengkel;

  const WorkshopReportScreen({super.key, required this.bengkel});

  @override
  State<WorkshopReportScreen> createState() => _WorkshopReportScreenState();
}

class _WorkshopReportScreenState extends State<WorkshopReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  
  bool _isUploading = false;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFileBytes = result.files.first.bytes;
          _selectedFileName = result.files.first.name;
        });
      }
    } catch (e) {
      debugPrint('[Report] Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memilih gambar bukti')),
        );
      }
    }
  }

  Future<String?> _uploadEvidence() async {
    if (_selectedFileBytes == null || _selectedFileName == null) return null;

    final supabase = Supabase.instance.client;
    final fileExt = _selectedFileName!.split('.').last;
    final fileName = 'evidence-${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    try {
      await supabase.storage.from('report_proofs').uploadBinary(
            fileName,
            _selectedFileBytes!,
            fileOptions: const FileOptions(upsert: true),
          );
      final publicUrl = supabase.storage.from('report_proofs').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('[Upload Evidence] Error: $e');
      rethrow;
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);
    
    try {
      String? evidenceUrl;
      if (_selectedFileBytes != null) {
        evidenceUrl = await _uploadEvidence();
      }

      final bengkelId = widget.bengkel['id']?.toString() ?? '';
      final reason = _reasonController.text.trim();

      if (mounted) {
        final success = await context.read<WorkshopReportViewModel>().submitReport(
              bengkelId: bengkelId,
              reason: reason,
              evidenceUrl: evidenceUrl,
            );

        if (success) {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 28),
                    SizedBox(width: 10),
                    Text('Laporan Terkirim', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                content: const Text(
                  'Laporan Anda telah berhasil dikirim ke Admin. Kami akan meninjau laporan ini dan mengambil tindakan segera.',
                  style: TextStyle(height: 1.4),
                ),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx); // Close dialog
                      Navigator.pop(context); // Back to detail
                    },
                    child: const Text('OK', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }
        } else {
          if (mounted) {
            final errorMsg = context.read<WorkshopReportViewModel>().error ?? 'Terjadi kesalahan saat mengirim laporan';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal mengirim laporan: $errorMsg'), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunggah bukti: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.bengkel['name'] as String? ?? 'Bengkel';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Laporkan Bengkel',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isUploading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Sedang mengirim laporan...', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Warning Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber.shade800, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Perhatian Sebelum Melaporkan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Mohon berikan laporan yang jujur dan objektif serta masukkan bukti foto (seperti nota pembayaran, hasil servis yang cacat, atau chat penipuan) untuk memperkuat laporan Anda.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.amber.shade800,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    
                    // Bengkel info details
                    Text(
                      'Mencurigai Kecurangan di:',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Alasan Laporan
                    const Text(
                      'Alasan Pelaporan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 5,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Alasan pelaporan wajib diisi';
                        }
                        if (val.trim().length < 10) {
                          return 'Berikan alasan yang jelas (minimal 10 karakter)';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Jelaskan secara detail tindakan kecurangan, penipuan, atau pelanggaran yang dilakukan oleh bengkel...',
                        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Unggah Bukti
                    const Text(
                      'Bukti Pelaporan (Foto/Screenshot)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            style: _selectedFileBytes == null ? BorderStyle.solid : BorderStyle.none,
                          ),
                        ),
                        child: _selectedFileBytes != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      _selectedFileBytes!,
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.change_circle_outlined, color: Colors.white, size: 36),
                                        const SizedBox(height: 8),
                                        Text(
                                          _selectedFileName ?? 'Ganti Bukti',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      icon: const Icon(Icons.cancel, color: Colors.white),
                                      onPressed: () {
                                        setState(() {
                                          _selectedFileBytes = null;
                                          _selectedFileName = null;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, color: Colors.grey, size: 40),
                                  SizedBox(height: 10),
                                  Text(
                                    'Pilih Gambar Bukti',
                                    style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Dapat berupa nota, bukti pembayaran, chat, dll.',
                                    style: TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Submit Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F), // Red action button for report
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _submitReport,
                      child: const Text(
                        'Kirim Laporan Resmi',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
