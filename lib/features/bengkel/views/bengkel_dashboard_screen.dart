import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../auth/views/login_screen.dart';
import '../viewmodels/bengkel_dashboard_viewmodel.dart';
import '../viewmodels/bengkel_orders_viewmodel.dart';
import '../viewmodels/bengkel_booking_viewmodel.dart';
import 'bengkel_finance_report_screen.dart';
import 'bengkel_reviews_screen.dart';

class BengkelDashboardScreen extends StatefulWidget {
  const BengkelDashboardScreen({super.key});

  @override
  State<BengkelDashboardScreen> createState() => _BengkelDashboardScreenState();
}

class _BengkelDashboardScreenState extends State<BengkelDashboardScreen> {
  String _lastFetchedBengkelId = '';

  @override
  Widget build(BuildContext context) {
    final dashboardVM = Provider.of<BengkelDashboardViewModel>(context);
    
    // Fetch orders if we have a bengkelId and haven't fetched for it yet
    if (dashboardVM.bengkelId.isNotEmpty &&
        dashboardVM.bengkelId != _lastFetchedBengkelId) {
      _lastFetchedBengkelId = dashboardVM.bengkelId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<BengkelOrdersViewModel>().fetchBengkelOrders(
                dashboardVM.bengkelId,
              );
          context.read<BengkelBookingViewModel>().fetchBookings();
          context.read<BengkelDashboardViewModel>().fetchBengkelReviews();
        }
      });
    }

    return Consumer3<AuthViewModel, BengkelDashboardViewModel, BengkelOrdersViewModel>(
      builder: (context, authViewModel, bengkelViewModel, ordersViewModel, child) {
        final isVerified = bengkelViewModel.status == 'diterima' || bengkelViewModel.status == 'active';
        final isProfileComplete = bengkelViewModel.isProfileComplete;
        final hasDocument = bengkelViewModel.documentUrl != null;
        final bengkelName = bengkelViewModel.bengkelName.isNotEmpty ? bengkelViewModel.bengkelName : 'Bengkel Saya';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(context, bengkelName, isVerified),
          body: isVerified
              ? _buildVerifiedDashboard(bengkelViewModel, ordersViewModel)
              : _buildUnverifiedDashboard(
                  context,
                  bengkelViewModel.status,
                  isProfileComplete,
                  hasDocument,
                  bengkelViewModel.rejectionReason,
                  bengkelViewModel,
                ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String bengkelName, bool isVerified) {
    final nameInitial = bengkelName.isNotEmpty ? bengkelName[0].toUpperCase() : 'B';
    return AppBar(
      backgroundColor: const Color(0xFF1E2843),
      elevation: 0,
      titleSpacing: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF2B300), Color(0xFFFF8C00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              nameInitial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bengkelName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isVerified ? const Color(0xFF4ADE80) : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  isVerified ? 'Mitra Terverifikasi' : 'Belum Terverifikasi',
                  style: TextStyle(
                    color: isVerified ? const Color(0xFF4ADE80) : Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
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
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ),
      ],
    );
  }


  Widget _buildUnverifiedDashboard(
    BuildContext context,
    String status,
    bool isProfileComplete,
    bool hasDocument,
    String? rejectionReason,
    BengkelDashboardViewModel viewModel,
  ) {
    final isSuspended = status == 'suspended';
    final isWaitingReview = status == 'tahap 2';
    final canUpload = isProfileComplete && !isWaitingReview && !isSuspended;
    final isRejected = status == 'di tolak';

    // Tentukan banner
    Color bannerColor;
    Color bannerBorderColor;
    IconData bannerIcon;
    String bannerTitle;
    String bannerDesc;

    if (isSuspended) {
      bannerColor = Colors.red.shade50;
      bannerBorderColor = Colors.red.shade300;
      bannerIcon = Icons.block_flipped;
      bannerTitle = 'Akun Ditangguhkan (Suspended)';
      bannerDesc = 'Akun bengkel Anda telah ditangguhkan oleh admin karena terindikasi atau terbukti melakukan pelanggaran, kecurangan, atau penipuan.\n\nHarap hubungi customer support admin untuk melakukan banding atau klarifikasi lebih lanjut.';
    } else if (isRejected) {
      bannerColor = Colors.red.shade50;
      bannerBorderColor = Colors.red.shade200;
      bannerIcon = Icons.error_outline_rounded;
      bannerTitle = 'Pendaftaran Ditolak';
      bannerDesc = 'Pengajuan verifikasi mitra Anda ditolak oleh admin dengan alasan:\n\n"${rejectionReason ?? 'Tidak ada alasan khusus.'}"\n\nSilakan perbaiki profil atau upload ulang dokumen verifikasi yang sesuai.';
    } else if (isWaitingReview) {
      bannerColor = Colors.blue.shade50;
      bannerBorderColor = Colors.blue.shade200;
      bannerIcon = Icons.hourglass_top_rounded;
      bannerTitle = 'Dokumen Sedang Ditinjau';
      bannerDesc = 'Dokumen Anda sedang dalam proses peninjauan oleh admin. Harap tunggu pemberitahuan lebih lanjut.';
    } else if (isProfileComplete) {
      bannerColor = Colors.green.shade50;
      bannerBorderColor = Colors.green.shade200;
      bannerIcon = Icons.upload_file_rounded;
      bannerTitle = 'Profil Lengkap!';
      bannerDesc = 'Profil bengkel Anda sudah lengkap. Silakan upload dokumen verifikasi untuk melanjutkan.';
    } else {
      bannerColor = Colors.orange.shade50;
      bannerBorderColor = Colors.orange.shade200;
      bannerIcon = Icons.pending_actions;
      bannerTitle = 'Akun Bengkel Belum Terverifikasi';
      bannerDesc = 'Mohon selesaikan langkah-langkah berikut agar bengkel Anda dapat beroperasi dan menerima pesanan.';
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: bannerColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: bannerBorderColor),
              ),
              child: Column(
                children: [
                  Icon(bannerIcon, size: 64, color: (isRejected || isSuspended) ? Colors.red.shade400 : bannerBorderColor),
                  const SizedBox(height: 16),
                  Text(
                    bannerTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bannerDesc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (isSuspended) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B2E3C),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final phone = '6281234567890'; // Predefined Admin support phone number
                  final text = 'Halo Admin Bengkelin, akun bengkel saya "${viewModel.bengkelName}" ditangguhkan (ID: ${viewModel.bengkelId}). Mohon informasi alasan penangguhan dan langkah selanjutnya.';
                  final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(text)}');
                  try {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gagal membuka WhatsApp. Hubungi admin@bengkelin.com')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.support_agent, color: Colors.white),
                label: const Text(
                  'Hubungi Dukungan Admin',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ] else ...[
              const Text(
                'Langkah Verifikasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildVerificationStep(
                step: 1,
                title: 'Lengkapi Profil Bengkel',
                description: 'Nama bengkel, alamat, deskripsi, dan jam operasional.',
                isDone: isProfileComplete,
                isActive: !isProfileComplete,
                onTap: isProfileComplete ? null : () => _showProfileDialog(context),
              ),
              const SizedBox(height: 12),
              _buildVerificationStep(
                step: 2,
                title: 'Upload Dokumen Verifikasi',
                description: 'Gabungkan KTP Pemilik, SIUP/NIB, dan foto bengkel dalam 1 file PDF.',
                isDone: isWaitingReview,
                isActive: canUpload,
                onTap: canUpload ? () => _showUploadDialog(context) : null,
              ),
              const SizedBox(height: 12),
              _buildVerificationStep(
                step: 3,
                title: 'Status Verifikasi',
                description: isRejected
                    ? 'Ditolak: ${rejectionReason ?? ''}'
                    : isWaitingReview
                        ? 'Dokumen Anda sedang ditinjau oleh admin BengkelKu.'
                        : 'Menunggu peninjauan oleh admin BengkelKu.',
                isDone: false,
                isActive: isWaitingReview || isRejected,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    final viewModel = context.read<BengkelDashboardViewModel>();
    final authViewModel = context.read<AuthViewModel>();
    final defaultName = viewModel.bengkelName.isNotEmpty 
        ? viewModel.bengkelName 
        : (authViewModel.currentUser?.name ?? '');
        
    final nameCtrl = TextEditingController(text: defaultName);
    final addressCtrl = TextEditingController(text: viewModel.bengkelAddress);
    final descCtrl = TextEditingController(text: viewModel.description);
    bool isSaving = false;
    bool hasAttemptedSubmit = false;
    bool isDetectingLocation = false;

    LatLng? selectedLocation = (viewModel.latitude != 0.0 && viewModel.longitude != 0.0 && viewModel.latitude != null && viewModel.longitude != null)
        ? LatLng(viewModel.latitude!, viewModel.longitude!)
        : null;
    final MapController mapController = MapController();

    Future<void> reverseGeocode(LatLng latLng, void Function() onUpdate) async {
      try {
        isDetectingLocation = true;
        onUpdate();
        final url = Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=${latLng.latitude}&lon=${latLng.longitude}&zoom=18&addressdetails=1');
        final response = await http.get(url, headers: {'User-Agent': 'BengkelinApp/1.0'});
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['display_name'] != null) {
            addressCtrl.text = data['display_name'];
          }
        }
      } catch (e) {
        debugPrint('Geocoding error: $e');
      } finally {
        isDetectingLocation = false;
        onUpdate();
      }
    }

    Future<void> detectLocation(void Function() onUpdate) async {
      isDetectingLocation = true;
      onUpdate();
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) throw Exception('GPS tidak aktif');

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) throw Exception('Izin GPS ditolak');
        }
        if (permission == LocationPermission.deniedForever) {
          throw Exception('Izin GPS ditolak permanen');
        }

        final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        final newLocation = LatLng(position.latitude, position.longitude);

        selectedLocation = newLocation;
        mapController.move(newLocation, 16.0);
        
        await reverseGeocode(newLocation, onUpdate);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mendeteksi lokasi: $e'), backgroundColor: Colors.red),
        );
      } finally {
        isDetectingLocation = false;
        onUpdate();
      }
    }

    // State jam operasional
    final List<String> allDays = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final List<bool> selectedDays = List.filled(7, false);
    // Default: Senin-Jumat
    for (int i = 0; i < 5; i++) {
      selectedDays[i] = true;
    }
    TimeOfDay openTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay closeTime = const TimeOfDay(hour: 17, minute: 0);

    String formatTime(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}';

    String buildOperatingHours(List<bool> days, TimeOfDay open, TimeOfDay close) {
      final activeDays = [for (int i = 0; i < days.length; i++) if (days[i]) allDays[i]];
      if (activeDays.isEmpty) return '';
      return '${activeDays.join(', ')}, ${formatTime(open)}-${formatTime(close)}';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Lengkapi Profil Bengkel', style: TextStyle(fontWeight: FontWeight.bold)),
            content: isSaving
                ? const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: nameCtrl,
                          onChanged: (_) {
                            if (hasAttemptedSubmit) setState(() {});
                          },
                          decoration: InputDecoration(
                            labelText: 'Nama Bengkel *',
                            errorText: hasAttemptedSubmit && nameCtrl.text.trim().isEmpty ? 'Nama Bengkel wajib diisi' : null,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.storefront_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: addressCtrl,
                          maxLines: 2,
                          onChanged: (_) {
                            if (hasAttemptedSubmit) setState(() {});
                          },
                          decoration: InputDecoration(
                            labelText: 'Alamat Bengkel *',
                            errorText: hasAttemptedSubmit && addressCtrl.text.trim().isEmpty ? 'Alamat Bengkel wajib diisi' : null,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.map_outlined, color: AppColors.primary),
                              tooltip: 'Pilih lokasi dari peta',
                                onPressed: () {
                                  final initialLocation = selectedLocation;
                                  final initialAddress = addressCtrl.text;
                                  
                                  showDialog(
                                    context: context,
                                    builder: (mapCtx) => StatefulBuilder(
                                      builder: (mapCtx, setMapState) {
                                      void updateStates() {
                                        setMapState(() {});
                                        setState(() {});
                                      }
                                      return AlertDialog(
                                        title: const Text('Pilih Lokasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        content: SizedBox(
                                          width: double.maxFinite,
                                          height: 400,
                                          child: Column(
                                            children: [
                                              Expanded(
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: FlutterMap(
                                                    mapController: mapController,
                                                    options: MapOptions(
                                                      initialCenter: selectedLocation ?? LatLng(-6.2088, 106.8456),
                                                      initialZoom: selectedLocation != null ? 15.0 : 12.0,
                                                      onTap: (tapPos, latLng) {
                                                        selectedLocation = latLng;
                                                        reverseGeocode(latLng, updateStates);
                                                      },
                                                    ),
                                                    children: [
                                                      TileLayer(
                                                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                                        userAgentPackageName: 'com.bengkelin.app',
                                                      ),
                                                      if (selectedLocation != null)
                                                        MarkerLayer(
                                                          markers: [
                                                            Marker(
                                                              point: selectedLocation!,
                                                              width: 40,
                                                              height: 40,
                                                              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                                                            ),
                                                          ],
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: AppColors.surface,
                                                  border: Border.all(color: Colors.grey.shade300),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        addressCtrl.text.isEmpty ? 'Pilih lokasi di peta' : addressCtrl.text,
                                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              SizedBox(
                                                width: double.infinity,
                                                child: OutlinedButton.icon(
                                                  onPressed: isDetectingLocation ? null : () => detectLocation(updateStates),
                                                  icon: isDetectingLocation
                                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                                      : const Icon(Icons.my_location, size: 18),
                                                  label: Text(isDetectingLocation ? 'Mendeteksi...' : 'Gunakan GPS Saat Ini'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              selectedLocation = initialLocation;
                                              addressCtrl.text = initialAddress;
                                              setState(() {});
                                              Navigator.pop(mapCtx);
                                            },
                                            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(mapCtx),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                            ),
                                            child: const Text('Simpan Lokasi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          onChanged: (_) {
                            if (hasAttemptedSubmit) setState(() {});
                          },
                          decoration: InputDecoration(
                            labelText: 'Deskripsi Bengkel *',
                            hintText: 'Contoh: Bengkel spesialis AC mobil...',
                            errorText: hasAttemptedSubmit && descCtrl.text.trim().isEmpty ? 'Deskripsi Bengkel wajib diisi' : null,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.description_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text(
                              'Jam Operasional *',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            if (hasAttemptedSubmit && buildOperatingHours(selectedDays, openTime, closeTime).isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text('(Pilih minimal 1 hari)', style: TextStyle(color: Colors.red, fontSize: 12)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Pilih Hari
                        const Text('Hari buka:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: List.generate(7, (i) {
                            return FilterChip(
                              label: Text(allDays[i].substring(0, 3),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: selectedDays[i] ? Colors.white : AppColors.textPrimary,
                                  )),
                              selected: selectedDays[i],
                              onSelected: (val) => setState(() => selectedDays[i] = val),
                              selectedColor: AppColors.primary,
                              checkmarkColor: Colors.white,
                              backgroundColor: AppColors.surface,
                              showCheckmark: false,
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        // Pilih Jam Buka & Tutup
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: openTime,
                                    helpText: 'Jam Buka',
                                  );
                                  if (picked != null) setState(() => openTime = picked);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.wb_sunny_outlined, size: 18, color: AppColors.textSecondary),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Buka', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                          Text(formatTime(openTime),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('—', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: closeTime,
                                    helpText: 'Jam Tutup',
                                  );
                                  if (picked != null) setState(() => closeTime = picked);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.nightlight_outlined, size: 18, color: AppColors.textSecondary),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Tutup', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                          Text(formatTime(closeTime),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Preview
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.schedule, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  buildOperatingHours(selectedDays, openTime, closeTime).isEmpty
                                      ? 'Pilih hari terlebih dahulu'
                                      : buildOperatingHours(selectedDays, openTime, closeTime),
                                  style: const TextStyle(fontSize: 12, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
            actions: [
              if (!isSaving)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                ),
              if (!isSaving)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () async {
                    setState(() => hasAttemptedSubmit = true);
                    final operatingHours = buildOperatingHours(selectedDays, openTime, closeTime);
                    if (nameCtrl.text.trim().isEmpty ||
                        addressCtrl.text.trim().isEmpty ||
                        descCtrl.text.trim().isEmpty ||
                        operatingHours.isEmpty) {
                      return;
                    }
                    setState(() => isSaving = true);
                    try {
                      await viewModel.updateProfile(
                        name: nameCtrl.text.trim(),
                        address: addressCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        operatingHours: operatingHours,
                        latitude: selectedLocation?.latitude,
                        longitude: selectedLocation?.longitude,
                        userId: context.read<AuthViewModel>().currentUser?.id,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profil bengkel berhasil disimpan!')),
                        );
                      }
                    } catch (e) {
                      setState(() => isSaving = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal menyimpan: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    PlatformFile? selectedFile;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Upload Dokumen'),
            content: isUploading
                ? const SizedBox(
                    height: 100,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Silakan gabungkan dokumen berikut menjadi 1 file PDF:'),
                      const SizedBox(height: 8),
                      const Text(
                        '1. KTP Pemilik\n2. SKU / NIB\n3. Foto Bengkel Tampak Depan',
                        style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      _buildUploadItem(
                        title: 'Upload File PDF',
                        file: selectedFile,
                        onTap: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf'],
                            withData: true,
                          );
                          if (result != null) {
                            setState(() => selectedFile = result.files.first);
                          }
                        },
                      ),
                    ],
                  ),
            actions: [
              if (!isUploading)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                ),
              if (!isUploading)
                ElevatedButton(
                  onPressed: () async {
                    if (selectedFile == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Silakan pilih file PDF terlebih dahulu')),
                      );
                      return;
                    }

                    setState(() => isUploading = true);
                    final viewModel = context.read<BengkelDashboardViewModel>();

                    try {
                      final userId = context.read<AuthViewModel>().currentUser?.id;
                      await viewModel.uploadDocument('document', selectedFile!.bytes!, selectedFile!.name, userId: userId);
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Dokumen berhasil diupload, menunggu verifikasi Admin.')),
                        );
                        final userId = context.read<AuthViewModel>().currentUser?.id;
                        viewModel.fetchBengkelStatus(userId: userId); // Refresh status
                      }
                    } catch (e) {
                      setState(() => isUploading = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal upload: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Kirim Dokumen', style: TextStyle(color: Colors.white)),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUploadItem({required String title, PlatformFile? file, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: file != null ? AppColors.primary : AppColors.border),
          borderRadius: BorderRadius.circular(8),
          color: file != null ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                  if (file != null)
                    Text(
                      file.name,
                      style: const TextStyle(fontSize: 12, color: AppColors.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(
              file != null ? Icons.check_circle : Icons.upload_file,
              color: file != null ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationStep({
    required int step,
    required String title,
    required String description,
    required bool isDone,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.shade50 : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone
              ? Colors.green.shade200
              : isActive
                  ? AppColors.primary
                  : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDone
                  ? Colors.green
                  : isActive
                      ? AppColors.primary
                      : AppColors.border,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '$step',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDone ? Colors.green.shade800 : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (!isDone && !isActive)
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          if (isActive && onTap != null)
            const Icon(Icons.upload_file, color: AppColors.primary),
        ],
      ),
    ),
  );
}

  Widget _buildVerifiedDashboard(BengkelDashboardViewModel bengkelViewModel, BengkelOrdersViewModel ordersViewModel) {
    final now = DateTime.now();
    final bookingsViewModel = context.watch<BengkelBookingViewModel>();
    
    // 1. Pesanan & Booking Hari Ini
    final todayOrders = ordersViewModel.orders.where((order) {
      final orderDate = order.createdAt;
      return orderDate.year == now.year && orderDate.month == now.month && orderDate.day == now.day;
    }).toList();
    
    final todayBookings = bookingsViewModel.bookings.where((b) {
      final bDate = b.bookingDate;
      return bDate.year == now.year && bDate.month == now.month && bDate.day == now.day;
    }).toList();
    
    final todayOrdersCount = todayOrders.length + todayBookings.length;

    // 2. Pendapatan Hari Ini (Sparepart + Booking Selesai)
    final double todayOrderRevenue = todayOrders
        .where((order) => order.isPaid || order.status == 'Selesai')
        .fold(0.0, (sum, order) => sum + order.totalPrice);

    final double todayBookingRevenue = todayBookings
        .where((b) => b.status == 'Selesai' || b.status == 'Ulasan Dikirim')
        .fold(0.0, (sum, b) => sum + (b.totalPrice ?? 0).toDouble());

    final double todayRevenue = todayOrderRevenue + todayBookingRevenue;

    // 3. Total Pelanggan Unik (Orders + Bookings)
    final Set<String> allCustomerIds = {};
    allCustomerIds.addAll(ordersViewModel.orders.map((o) => o.userId));
    allCustomerIds.addAll(bookingsViewModel.bookings.map((b) => b.customerId));
    final uniqueCustomers = allCustomerIds.length;

    // 4. Rating (from bengkelViewModel)
    final rating = bengkelViewModel.rating;
    final reviewsCount = bengkelViewModel.reviewsCount;

    // 5. Chart Data (Past 7 Days Revenue - Spareparts + Bookings)
    final List<FlSpot> spots = [];
    final List<String> dayLabels = [];
    final List<String> weekDays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    double maxRevenue = 0;
    double totalWeekRevenue = 0;

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      dayLabels.add(weekDays[date.weekday - 1]);
      
      final double dayOrderRev = ordersViewModel.orders
          .where((o) => (o.isPaid || o.status == 'Selesai') && 
                        o.createdAt.year == date.year && 
                        o.createdAt.month == date.month && 
                        o.createdAt.day == date.day)
          .fold(0.0, (sum, o) => sum + o.totalPrice);

      final double dayBookingRev = bookingsViewModel.bookings
          .where((b) => (b.status == 'Selesai' || b.status == 'Ulasan Dikirim') && 
                        b.bookingDate.year == date.year && 
                        b.bookingDate.month == date.month && 
                        b.bookingDate.day == date.day)
          .fold(0.0, (sum, b) => sum + (b.totalPrice ?? 0).toDouble());
      
      final double dayRevenue = dayOrderRev + dayBookingRev;
      totalWeekRevenue += dayRevenue;
      if (dayRevenue > maxRevenue) maxRevenue = dayRevenue;
      
      spots.add(FlSpot((6 - i).toDouble(), dayRevenue));
    }
    
    double chartMaxY = maxRevenue > 0 ? maxRevenue * 1.2 : 100.0;

    // Helper formatter
    String formatPrice(double val) {
      if (val >= 1000000) {
        return 'Rp ${(val / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\\\.0$'), '')} Jt';
      } else if (val >= 1000) {
        return 'Rp ${(val / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\\\.0$'), '')} Rb';
      } else {
        return 'Rp ${val.toInt()}';
      }
    }

    final recentOrders = ordersViewModel.orders.take(3).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Laporan Keuangan Quick Access Card
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BengkelFinanceReportScreen()),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Laporan Keuangan Bengkel',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                          ),
                          Text(
                            'Lihat analisis detail pendapatan sparepart & servis',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),

            // Pendapatan & Pesanan Hari Ini
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF243B53), // Dark blue
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pendapatan Hari Ini',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatPrice(todayRevenue),
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: const [
                            Icon(Icons.check_circle_outline, color: Colors.lightBlueAccent, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Sudah dibayar',
                              style: TextStyle(color: Colors.lightBlueAccent, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pesanan Hari Ini',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$todayOrdersCount',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: const [
                            Icon(Icons.assignment_turned_in, color: Colors.green, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Transaksi hari ini',
                              style: TextStyle(color: Colors.green, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Total Pelanggan & Rating
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Pelanggan',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$uniqueCustomers',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: const [
                            Icon(Icons.people_alt, color: Colors.blueAccent, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Pelanggan unik',
                              style: TextStyle(color: Colors.blueAccent, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BengkelReviewsScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rating',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.star, color: Colors.amber, size: 24),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star_border, color: AppColors.textSecondary, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '$reviewsCount ulasan',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pendapatan Minggu Ini (Chart placeholder)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pendapatan 7 Hari Terakhir',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${formatPrice(totalWeekRevenue)} total',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF243B53)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 && value.toInt() < dayLabels.length) {
                                  return Text(dayLabels[value.toInt()], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary));
                                }
                                return const Text('');
                              },
                              reservedSize: 22,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: const Color(0xFF243B53),
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFF243B53).withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                        minX: 0,
                        maxX: 6,
                        minY: 0,
                        maxY: chartMaxY,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pesanan Terbaru
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pesanan Terbaru',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      InkWell(
                        onTap: () {
                          // Navigate to Orders Tab
                        },
                        child: Row(
                          children: const [
                            Text('Semua', style: TextStyle(color: AppColors.primary, fontSize: 14)),
                            Icon(Icons.chevron_right, color: AppColors.primary, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (recentOrders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Text('Belum ada pesanan.', style: TextStyle(color: AppColors.textSecondary)),
                    )
                  else
                    ...recentOrders.map((o) {
                      final itemsText = o.items.map((i) => i.sparepart?.name ?? 'Item').join(', ');
                      final dateText = '${o.createdAt.hour.toString().padLeft(2, '0')}:${o.createdAt.minute.toString().padLeft(2, '0')}';
                      return Column(
                        children: [
                          _buildOrderItem(
                            name: 'Pelanggan',
                            service: itemsText.isNotEmpty ? itemsText : 'Pesanan Sparepart',
                            status: o.status,
                            time: dateText,
                          ),
                          if (o != recentOrders.last) const Divider(),
                        ],
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ulasan Terbaru Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ulasan Terbaru',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const BengkelReviewsScreen()),
                          );
                        },
                        child: Row(
                          children: const [
                            Text('Semua', style: TextStyle(color: AppColors.primary, fontSize: 14)),
                            Icon(Icons.chevron_right, color: AppColors.primary, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (bengkelViewModel.isReviewsLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (bengkelViewModel.reviewsList.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text('Belum ada ulasan.', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    )
                  else
                    ...bengkelViewModel.reviewsList.take(3).map((r) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  (r['customer'] as String).isNotEmpty ? (r['customer'] as String)[0].toUpperCase() : 'P',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          r['customer'] as String,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: r['type'] == 'Servis' ? Colors.orange.shade50 : Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            r['type'] == 'Servis' ? 'Servis' : 'Sparepart',
                                            style: TextStyle(
                                              fontSize: 9, 
                                              fontWeight: FontWeight.bold,
                                              color: r['type'] == 'Servis' ? Colors.orange : Colors.blue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        ...List.generate(5, (index) {
                                          return Icon(
                                            index < (r['rating'] as double).floor() ? Icons.star : Icons.star_border,
                                            color: Colors.amber,
                                            size: 14,
                                          );
                                        }),
                                        const SizedBox(width: 4),
                                        Text(
                                          (r['rating'] as double).toStringAsFixed(1),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      r['type'] == 'Servis' ? 'Layanan: ${r['category']}' : 'Produk: ${r['category']}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      r['comment'] as String,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (r != bengkelViewModel.reviewsList.take(3).last) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                          ],
                        ],
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem({
    required String name,
    required String service,
    required String status,
    required String time,
  }) {
    final bool isActive = status == 'Aktif';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              name[0],
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  service,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.blue.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isActive ? Colors.blue : Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
