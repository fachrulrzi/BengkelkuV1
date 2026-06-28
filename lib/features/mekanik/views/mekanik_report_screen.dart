import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodels/mekanik_dashboard_viewmodel.dart';
import '../models/mechanic_task_model.dart';

class MekanikReportScreen extends StatefulWidget {
  final MechanicTaskModel task;
  const MekanikReportScreen({super.key, required this.task});

  @override
  State<MekanikReportScreen> createState() => _MekanikReportScreenState();
}

class _MekanikReportScreenState extends State<MekanikReportScreen> {
  final _reportController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  bool _isLoading = false;

  Uint8List? _selectedFileBytes;
  String? _selectedFileName;

  final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  @override
  void dispose() {
    _reportController.dispose();
    _priceController.dispose();
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
      debugPrint('Error picking file: $e');
    }
  }

  Future<String?> _uploadProofImage() async {
    if (_selectedFileBytes == null || _selectedFileName == null) return null;
    
    final supabase = Supabase.instance.client;
    final fileExt = _selectedFileName!.split('.').last;
    final filePath = 'proof-${widget.task.id}-${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    try {
      await supabase.storage.from('service_proofs').uploadBinary(
            filePath,
            _selectedFileBytes!,
            fileOptions: const FileOptions(upsert: true),
          );
      final publicUrl = supabase.storage.from('service_proofs').getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      debugPrint('[Upload] Error uploading proof image: $e');
      rethrow;
    }
  }

  Future<void> _submit() async {
    if (_reportController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan pengerjaan tidak boleh kosong')),
      );
      return;
    }

    final additionalPrice = int.tryParse(
          _priceController.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;

    setState(() => _isLoading = true);
    try {
      String? proofUrl;
      if (_selectedFileBytes != null) {
        proofUrl = await _uploadProofImage();
      }

      await context.read<MekanikDashboardViewModel>().completeTask(
            bookingId: widget.task.id,
            report: _reportController.text.trim(),
            additionalPrice: additionalPrice,
            initialPaymentAmount: widget.task.initialPaymentAmount,
            serviceProofUrl: proofUrl,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Servis berhasil diselesaikan! ✅'),
            backgroundColor: Color(0xFF00C853),
          ),
        );
        Navigator.pop(context); // back to list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyelesaikan servis: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Laporan Servis',
          style: TextStyle(
            color: Color(0xFF1B3A5E),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1B3A5E)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.shortId,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.serviceCategory,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF1B3A5E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${task.customerName ?? 'Customer'} · ${task.vehicleName ?? '-'}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  if (task.vehiclePoliceNumber != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      task.vehiclePoliceNumber!,
                      style: const TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                  ],
                  if (task.complaint != null && task.complaint!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Keluhan Customer:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Text(
                        task.complaint!,
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Report Form Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Laporan Pengerjaan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1B3A5E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _reportController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Jelaskan pengerjaan servis, penggantian suku cadang, dll...',
                      hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Biaya Tambahan Input
                  const Text(
                    'Biaya Tambahan / Sparepart (Rp)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1B3A5E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Contoh: 150000 (Isi 0 jika tidak ada)',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Upload Bukti Foto Servis
                  const Text(
                    'Bukti Foto Servis (Opsional)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1B3A5E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _selectedFileBytes != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    _selectedFileBytes!,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Container(
                                  color: Colors.black38,
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Ubah Foto',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, color: Colors.grey, size: 36),
                                SizedBox(height: 8),
                                Text(
                                  'Pilih Foto Bukti Pekerjaan',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                    ),
                  ),
                  if (_selectedFileName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Terpilih: $_selectedFileName',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: const Text(
                  'Selesaikan Servis & Kirim Laporan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
