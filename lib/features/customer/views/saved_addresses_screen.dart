import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _addressController;
  double? _selectedLat;
  double? _selectedLng;
  bool _isMapLoading = false;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser;
    _addressController = TextEditingController(text: user?.address ?? '');
    _selectedLat = user?.latitude;
    _selectedLng = user?.longitude;
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Saved Address',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Masukkan alamat utama Anda untuk mempermudah pemesanan servis.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  label: 'ALAMAT LENGKAP',
                  hint: 'Jl. Raya Kebon Jeruk No. 12, Jakarta Barat',
                  controller: _addressController,
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Alamat tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TITIK KOORDINAT ALAMAT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        try {
                          setState(() {
                            _isMapLoading = true;
                          });
                          LocationPermission permission = await Geolocator.checkPermission();
                          if (permission == LocationPermission.denied) {
                            permission = await Geolocator.requestPermission();
                          }
                          if (permission == LocationPermission.whileInUse ||
                              permission == LocationPermission.always) {
                            final pos = await Geolocator.getCurrentPosition();
                            final latLng = LatLng(pos.latitude, pos.longitude);
                            setState(() {
                              _selectedLat = pos.latitude;
                              _selectedLng = pos.longitude;
                            });
                            _mapController.move(latLng, 15.0);
                          }
                        } catch (e) {
                          debugPrint('Gagal mengambil lokasi: $e');
                        } finally {
                          setState(() {
                            _isMapLoading = false;
                          });
                        }
                      },
                      icon: const Icon(Icons.my_location, size: 14, color: Colors.blue),
                      label: const Text(
                        'Lokasi Saya',
                        style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: LatLng(
                              _selectedLat ?? -6.2000,
                              _selectedLng ?? 106.8166,
                            ),
                            initialZoom: 15.0,
                            onTap: (tapPosition, latLng) {
                              setState(() {
                                _selectedLat = latLng.latitude;
                                _selectedLng = latLng.longitude;
                              });
                              _mapController.move(latLng, _mapController.camera.zoom);
                            },
                            onPositionChanged: (position, hasGesture) {
                              if (hasGesture && position.center != null) {
                                setState(() {
                                  _selectedLat = position.center!.latitude;
                                  _selectedLng = position.center!.longitude;
                                });
                              }
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.bengkelin_app',
                            ),
                          ],
                        ),
                        const IgnorePointer(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 24),
                              child: Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                        if (_isMapLoading)
                          Container(
                            color: Colors.black12,
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.blue),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_selectedLat != null && _selectedLng != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Koordinat Terpilih: ${_selectedLat!.toStringAsFixed(6)}, ${_selectedLng!.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Simpan Alamat',
                  isLoading: authViewModel.isLoading,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        await authViewModel.updateAddress(
                          _addressController.text.trim(),
                          latitude: _selectedLat,
                          longitude: _selectedLng,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Alamat berhasil disimpan!')),
                          );
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal menyimpan alamat: $e')),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
