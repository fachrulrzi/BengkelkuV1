import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../auth/views/login_screen.dart';
import '../viewmodels/bengkel_dashboard_viewmodel.dart';
import 'bengkel_service_list_screen.dart';

class BengkelProfileScreen extends StatefulWidget {
  const BengkelProfileScreen({super.key});

  @override
  State<BengkelProfileScreen> createState() => _BengkelProfileScreenState();
}

class _BengkelProfileScreenState extends State<BengkelProfileScreen> {
  final MapController _mapController = MapController();

  // Edit profil controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _phoneCtrl;

  bool _isEditingProfile = false;
  bool _isSavingProfile = false;
  bool _isDetectingLocation = false;
  bool _isSavingLocation = false;

  // Lokasi yang dipilih (bisa dari GPS atau tap di peta)
  LatLng? _selectedLocation;

  // State jam operasional
  final List<String> _allDays = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  List<bool> _selectedDays = List.filled(7, false);
  TimeOfDay _openTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 17, minute: 0);

  @override
  void initState() {
    super.initState();
    final vm = context.read<BengkelDashboardViewModel>();
    _nameCtrl = TextEditingController(text: vm.bengkelName);
    _addressCtrl = TextEditingController(text: vm.bengkelAddress);
    _descCtrl = TextEditingController(text: vm.description);
    _phoneCtrl = TextEditingController();

    // Init selectedLocation dari data yang ada di viewmodel
    if (vm.latitude != null && vm.longitude != null) {
      _selectedLocation = LatLng(vm.latitude!, vm.longitude!);
    }

    // Parse jam operasional
    _parseOperatingHours(vm.operatingHours);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _parseOperatingHours(String hours) {
    if (hours.isEmpty) {
      for (int i = 0; i < 5; i++) {
        _selectedDays[i] = true;
      }
      return;
    }
    // Format: "Senin, Selasa, ..., HH.MM-HH.MM"
    try {
      final parts = hours.split(', ');
      if (parts.length >= 2) {
        final timeStr = parts.last;
        final timeParts = timeStr.split('-');
        if (timeParts.length == 2) {
          final openParts = timeParts[0].split('.');
          final closeParts = timeParts[1].split('.');
          _openTime = TimeOfDay(
            hour: int.tryParse(openParts[0]) ?? 8,
            minute: int.tryParse(openParts[1]) ?? 0,
          );
          _closeTime = TimeOfDay(
            hour: int.tryParse(closeParts[0]) ?? 17,
            minute: int.tryParse(closeParts[1]) ?? 0,
          );
        }
        for (int i = 0; i < 7; i++) {
          _selectedDays[i] = parts.contains(_allDays[i]);
        }
      }
    } catch (_) {}
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}';

  String _buildOperatingHours() {
    final activeDays = [
      for (int i = 0; i < _selectedDays.length; i++)
        if (_selectedDays[i]) _allDays[i]
    ];
    if (activeDays.isEmpty) return '';
    return '${activeDays.join(', ')}, ${_formatTime(_openTime)}-${_formatTime(_closeTime)}';
  }

  Future<void> _detectCurrentLocation() async {
    setState(() => _isDetectingLocation = true);
    try {
      // Cek permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Izin lokasi ditolak. Aktifkan di pengaturan.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin lokasi diblokir permanen. Aktifkan di pengaturan perangkat.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final newLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedLocation = newLocation;
      });

      // Animasikan peta ke lokasi
      _mapController.move(newLocation, 16.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lokasi terdeteksi: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
            ),
            backgroundColor: const Color(0xFF00C853),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendeteksi lokasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  Future<void> _saveLocation() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih lokasi terlebih dahulu dengan mendeteksi GPS atau tap di peta.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSavingLocation = true);
    try {
      final vm = context.read<BengkelDashboardViewModel>();
      final userId = context.read<AuthViewModel>().currentUser?.id;
      await vm.updateLocation(_selectedLocation!.latitude, _selectedLocation!.longitude, userId: userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokasi bengkel berhasil disimpan!'),
            backgroundColor: Color(0xFF00C853),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan lokasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingLocation = false);
    }
  }

  Future<void> _saveProfile() async {
    final operatingHours = _buildOperatingHours();
    if (_nameCtrl.text.trim().isEmpty ||
        _addressCtrl.text.trim().isEmpty ||
        _descCtrl.text.trim().isEmpty ||
        operatingHours.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua field wajib diisi dan minimal pilih 1 hari operasional.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSavingProfile = true);
    try {
      final vm = context.read<BengkelDashboardViewModel>();
      await vm.updateProfile(
        name: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        operatingHours: operatingHours,
      );
      if (mounted) {
        setState(() => _isEditingProfile = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil bengkel berhasil diperbarui!'),
            backgroundColor: Color(0xFF00C853),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BengkelDashboardViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E2843),
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text(
              'Profil Bengkel',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            actions: [
              if (!_isEditingProfile)
                TextButton.icon(
                  onPressed: () => setState(() => _isEditingProfile = true),
                  icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFFF2B300)),
                  label: const Text(
                    'Edit',
                    style: TextStyle(color: Color(0xFFF2B300), fontWeight: FontWeight.bold),
                  ),
                ),
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.logout_rounded, color: Colors.white70, size: 18),
                  ),
                  onPressed: () async {
                    await context.read<AuthViewModel>().signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Avatar + Nama ───────────────────────────────
                _buildBengkelHeader(vm),
                const SizedBox(height: 20),

                // ─── Section: Info Profil ─────────────────────────
                _buildSectionHeader('Informasi Bengkel', Icons.storefront_outlined),
                const SizedBox(height: 12),
                _isEditingProfile
                    ? _buildEditProfileCard()
                    : _buildViewProfileCard(vm),

                const SizedBox(height: 24),

                // ─── Section: Kelola Layanan ──────────────────────
                if (!_isEditingProfile) ...[
                  _buildSectionHeader('Layanan & Harga', Icons.design_services_outlined),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const BengkelServiceListScreen()));
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1B3A5E),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.build_circle_outlined, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Kelola Layanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                                SizedBox(height: 4),
                                Text('Tambah, edit, atau hapus daftar layanan & harga bengkel Anda', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ─── Section: Jam Operasional ─────────────────────
                if (_isEditingProfile) ...[
                  _buildSectionHeader('Jam Operasional', Icons.schedule_outlined),
                  const SizedBox(height: 12),
                  _buildOperatingHoursEditor(),
                  const SizedBox(height: 16),
                  // Tombol Save Profile
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSavingProfile ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isSavingProfile
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined, color: Colors.white),
                      label: Text(
                        _isSavingProfile ? 'Menyimpan...' : 'Simpan Perubahan',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        // Reset controllers
                        _nameCtrl.text = vm.bengkelName;
                        _addressCtrl.text = vm.bengkelAddress;
                        _descCtrl.text = vm.description;
                        _parseOperatingHours(vm.operatingHours);
                        setState(() => _isEditingProfile = false);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ─── Section: Lokasi di Peta ──────────────────────
                _buildSectionHeader('Lokasi Bengkel', Icons.map_outlined),
                const SizedBox(height: 4),
                Text(
                  'Tap di peta atau gunakan GPS untuk menentukan lokasi bengkelmu. Lokasi ini akan ditampilkan ke customer.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 12),

                // Koordinat tampilan
                if (_selectedLocation != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B3A5E).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF1B3A5E).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.pin_drop_outlined, color: Color(0xFF1B3A5E), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}  |  Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1B3A5E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Peta OpenStreetMap
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedLocation ?? const LatLng(-6.2088, 106.8456),
                        initialZoom: _selectedLocation != null ? 15.0 : 12.0,
                        onTap: (tapPos, latLng) {
                          setState(() {
                            _selectedLocation = latLng;
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.bengkelin.app',
                        ),
                        if (_selectedLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedLocation!,
                                width: 50,
                                height: 60,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1B3A5E),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 6,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.store_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    CustomPaint(
                                      size: const Size(14, 8),
                                      painter: _TrianglePainter(color: const Color(0xFF1B3A5E)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Tombol aksi lokasi
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isDetectingLocation ? null : _detectCurrentLocation,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF1B3A5E)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: _isDetectingLocation
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF1B3A5E),
                                ),
                              )
                            : const Icon(Icons.my_location, color: Color(0xFF1B3A5E), size: 18),
                        label: Text(
                          _isDetectingLocation ? 'Mendeteksi...' : 'Deteksi GPS',
                          style: const TextStyle(
                            color: Color(0xFF1B3A5E),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (_isSavingLocation || _selectedLocation == null)
                            ? null
                            : _saveLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B3A5E),
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: _isSavingLocation
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                        label: Text(
                          _isSavingLocation ? 'Menyimpan...' : 'Simpan Lokasi',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Text(
                  '💡 Tip: Tap langsung di peta untuk memilih lokasi yang lebih presisi.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),

                const SizedBox(height: 32),

                // ─── Tombol Logout ──────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
                          content: const Text('Apakah kamu yakin ingin logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text('Logout', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        await context.read<AuthViewModel>().signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.logout, color: Colors.red, size: 18),
                    label: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBengkelHeader(BengkelDashboardViewModel vm) {
    final isVerified = vm.status == 'diterima' || vm.status == 'active';
    final initial = vm.bengkelName.isNotEmpty ? vm.bengkelName[0].toUpperCase() : 'B';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B3A5E), Color(0xFF2E5C91)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vm.bengkelName.isNotEmpty ? vm.bengkelName : 'Bengkel Saya',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isVerified
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isVerified
                              ? Colors.green.shade200
                              : Colors.orange.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isVerified ? Icons.verified_rounded : Icons.pending_rounded,
                            size: 12,
                            color: isVerified ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isVerified ? 'Terverifikasi' : 'Belum Terverifikasi',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isVerified ? Colors.green.shade700 : Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (vm.bengkelAddress.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          vm.bengkelAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1B3A5E)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildViewProfileCard(BengkelDashboardViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.storefront_outlined, 'Nama Bengkel', vm.bengkelName.isNotEmpty ? vm.bengkelName : '-'),
          const Divider(height: 20, thickness: 0.5),
          _buildInfoRow(Icons.location_on_outlined, 'Alamat', vm.bengkelAddress.isNotEmpty ? vm.bengkelAddress : '-'),
          const Divider(height: 20, thickness: 0.5),
          _buildInfoRow(Icons.description_outlined, 'Deskripsi', vm.description.isNotEmpty ? vm.description : '-'),
          const Divider(height: 20, thickness: 0.5),
          _buildInfoRow(Icons.schedule_outlined, 'Jam Operasional', vm.operatingHours.isNotEmpty ? vm.operatingHours : '-'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1B3A5E)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1B3A5E).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTextField(
            controller: _nameCtrl,
            label: 'Nama Bengkel',
            icon: Icons.storefront_outlined,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _addressCtrl,
            label: 'Alamat Bengkel',
            icon: Icons.location_on_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _descCtrl,
            label: 'Deskripsi Bengkel',
            icon: Icons.description_outlined,
            maxLines: 3,
            hint: 'Contoh: Bengkel spesialis AC, tune up, dan ganti oli...',
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF1B3A5E)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1B3A5E), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildOperatingHoursEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1B3A5E).withValues(alpha: 0.2)),
      ),
      child: StatefulBuilder(
        builder: (context, setLocalState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pilih Hari
              const Text(
                'Hari Buka',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(7, (i) {
                  return GestureDetector(
                    onTap: () {
                      setLocalState(() {
                        _selectedDays[i] = !_selectedDays[i];
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _selectedDays[i]
                            ? const Color(0xFF1B3A5E)
                            : const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedDays[i]
                              ? const Color(0xFF1B3A5E)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Text(
                        _allDays[i].substring(0, 3),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _selectedDays[i] ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              const Text(
                'Jam Operasional',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTimePicker(
                      label: 'Buka',
                      time: _openTime,
                      icon: Icons.wb_sunny_outlined,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _openTime,
                          helpText: 'Pilih Jam Buka',
                        );
                        if (picked != null) setLocalState(() => _openTime = picked);
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('—', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                  ),
                  Expanded(
                    child: _buildTimePicker(
                      label: 'Tutup',
                      time: _closeTime,
                      icon: Icons.nightlight_outlined,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _closeTime,
                          helpText: 'Pilih Jam Tutup',
                        );
                        if (picked != null) setLocalState(() => _closeTime = picked);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Preview
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B3A5E).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1B3A5E).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: Color(0xFF1B3A5E)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _buildOperatingHours().isEmpty
                            ? 'Pilih minimal 1 hari'
                            : _buildOperatingHours(),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF1B3A5E)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay time,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                Text(
                  _formatTime(time),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter untuk segitiga pointer marker peta
class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
