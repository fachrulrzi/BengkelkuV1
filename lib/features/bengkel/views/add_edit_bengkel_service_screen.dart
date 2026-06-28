import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../customer/models/bengkel_service_model.dart';
import '../viewmodels/bengkel_manage_service_viewmodel.dart';

class AddEditBengkelServiceScreen extends StatefulWidget {
  final String bengkelId;
  final BengkelServiceModel? service; // Null if adding new

  const AddEditBengkelServiceScreen({super.key, required this.bengkelId, this.service});

  @override
  State<AddEditBengkelServiceScreen> createState() => _AddEditBengkelServiceScreenState();
}

class _AddEditBengkelServiceScreenState extends State<AddEditBengkelServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedCategoryId;
  final _basePriceCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      _selectedCategoryId = widget.service!.categoryId;
      _basePriceCtrl.text = widget.service!.basePrice.toString();
    }
  }

  @override
  void dispose() {
    _basePriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih kategori layanan terlebih dahulu')));
      return;
    }

    setState(() => _isSaving = true);
    final vm = context.read<BengkelManageServiceViewModel>();
    
    try {
      if (widget.service == null) {
        // Add
        await vm.addService(
          bengkelId: widget.bengkelId,
          categoryId: _selectedCategoryId!,
          basePrice: int.parse(_basePriceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')),
          homeServiceFee: 0,
          duration: '',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Layanan berhasil ditambahkan!')));
        }
      } else {
        // Edit
        await vm.updateService(
          serviceId: widget.service!.id,
          bengkelId: widget.bengkelId,
          basePrice: int.parse(_basePriceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')),
          homeServiceFee: 0,
          duration: '',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Layanan berhasil diperbarui!')));
        }
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.service != null;
    final vm = context.watch<BengkelManageServiceViewModel>();
    final categories = vm.masterCategories;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2843),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isEditing ? 'Edit Layanan' : 'Tambah Layanan',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kategori Layanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      hint: const Text('Pilih Kategori'),
                      decoration: _inputDecoration(),
                      items: categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat['id'].toString(),
                          child: Text(cat['name']),
                        );
                      }).toList(),
                      onChanged: isEditing ? null : (val) => setState(() => _selectedCategoryId = val),
                      validator: (val) => val == null ? 'Wajib dipilih' : null,
                    ),
                    if (isEditing)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text('Kategori tidak dapat diubah setelah layanan dibuat.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                    
                    const SizedBox(height: 20),
                    const Text('Harga Layanan (Rp)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _basePriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration().copyWith(hintText: 'Contoh: 50000', prefixText: 'Rp '),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Wajib diisi';
                        if (int.tryParse(val) == null) return 'Hanya angka';
                        return null;
                      },
                    ),

                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B3A5E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                isEditing ? 'Simpan Perubahan' : 'Tambah Layanan',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1B3A5E))),
    );
  }
}
