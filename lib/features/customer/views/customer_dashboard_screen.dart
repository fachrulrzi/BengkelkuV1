import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../viewmodels/customer_profile_viewmodel.dart';
import '../viewmodels/customer_dashboard_viewmodel.dart';
import 'vehicle_list_screen.dart';
import 'add_vehicle_screen.dart';
import 'edit_vehicle_screen.dart';
import '../viewmodels/notification_viewmodel.dart';
import 'notification_screen.dart';
import 'customer_main_screen.dart';
import 'workshop_detail_screen.dart';
import 'emergency_sos_screen.dart';
import 'booking_service_screen.dart';
import '../viewmodels/customer_booking_viewmodel.dart';

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProfileViewModel>().fetchVehicles();
      context.read<CustomerProfileViewModel>().fetchVehicleModels();
      context.read<CustomerBookingViewModel>().fetchBookings();
      context.read<CustomerDashboardViewModel>().fetchBengkels();
      context.read<CustomerDashboardViewModel>().fetchFrequentlyVisitedBengkels();
      context.read<NotificationViewModel>().fetchNotifications();
    });
  }

  void _showGarageMenu(BuildContext context, List<dynamic> vehicles) {
    final profileViewModel = context.read<CustomerProfileViewModel>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'My Garage',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (vehicles.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    'Garasi kosong. Silakan tambahkan kendaraan.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: vehicles.length,
                    itemBuilder: (itemCtx, index) {
                      final v = vehicles[index];
                      final isSelected =
                          index == profileViewModel.selectedVehicleIndex;
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.background,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            v.type == 'motor'
                                ? Icons.motorcycle_outlined
                                : Icons.directions_car_outlined,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                        title: Text(
                          '${v.brand} ${v.model}',
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(v.licensePlate),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              onPressed: () {
                                Navigator.pop(sheetCtx); // close bottom sheet
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditVehicleScreen(vehicle: v),
                                  ),
                                ).then((_) {
                                  if (context.mounted) {
                                    context
                                        .read<CustomerProfileViewModel>()
                                        .fetchVehicles();
                                  }
                                });
                              },
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                        onTap: () {
                          profileViewModel.setSelectedVehicleIndex(index);
                          Navigator.pop(sheetCtx);
                        },
                      );
                    },
                  ),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Add New Vehicle',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx); // close bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddVehicleScreen(),
                    ),
                  ).then((_) {
                    if (context.mounted) {
                      context.read<CustomerProfileViewModel>().fetchVehicles();
                    }
                  });
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.list_alt,
                  color: AppColors.textPrimary,
                ),
                title: const Text('Manage All Vehicles'),
                onTap: () {
                  Navigator.pop(sheetCtx); // close bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VehicleListScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // Ultra premium light grey background
      body: Consumer3<AuthViewModel, CustomerProfileViewModel, CustomerDashboardViewModel>(
        builder: (context, authViewModel, profileViewModel, dashboardViewModel, child) {
          final user = authViewModel.currentUser;
          final vehicles = profileViewModel.vehicles;
          final activeVehicle = profileViewModel.activeVehicle;
          final bengkels = dashboardViewModel.bengkels;
          final isBengkelsLoading = dashboardViewModel.isLoading;

          // Lookup active vehicle's image URL from matching vehicle model
          String? vehicleImageUrl;
          if (activeVehicle != null && profileViewModel.vehicleModels.isNotEmpty) {
            final matchedModel = profileViewModel.vehicleModels.firstWhere(
              (m) =>
                  m['brand']?.toString().toLowerCase() == activeVehicle.brand.toLowerCase() &&
                  m['name']?.toString().toLowerCase() == activeVehicle.model.toLowerCase(),
              orElse: () => <String, dynamic>{},
            );
            vehicleImageUrl = matchedModel['image_url'] as String?;
          }

          // Filter bengkels based on active vehicle's type (mobil vs motor)
          final filteredBengkels = bengkels.where((b) {
            if (activeVehicle == null) return true;
            final specialization = List<String>.from(b['specialization'] as List? ?? []);
            if (specialization.isEmpty) return true; // generic/all

            final String activeType = activeVehicle.type.toLowerCase();
            if (activeType == 'mobil') {
              return specialization.any((spec) =>
                  spec.toLowerCase().contains('mobil') ||
                  spec.toLowerCase().contains('motor & mobil') ||
                  spec.toLowerCase().contains('mobil & motor'));
            } else if (activeType == 'motor') {
              return specialization.any((spec) =>
                  spec.toLowerCase().contains('motor') ||
                  spec.toLowerCase().contains('motor & mobil') ||
                  spec.toLowerCase().contains('mobil & motor'));
            }
            return true;
          }).toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Redesigned Header Container matching mockup
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    bottom: 20,
                    left: 24,
                    right: 24,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E2843), // Solid premium dark navy
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Hamburger + Notifications
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                            onPressed: () {
                              // Buka drawer dari parent Scaffold (CustomerMainScreen)
                              final scaffold = context.findRootAncestorStateOfType<ScaffoldState>();
                              scaffold?.openDrawer();
                            },
                          ),
                          Consumer<NotificationViewModel>(
                            builder: (context, notifViewModel, child) {
                              final unreadCount = notifViewModel.unreadCount;
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const NotificationScreen(),
                                    ),
                                  ).then((_) {
                                    context.read<NotificationViewModel>().fetchNotifications();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      const Icon(
                                        Icons.notifications_none_outlined,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      if (unreadCount > 0)
                                        Positioned(
                                          right: -2,
                                          top: -2,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 14,
                                              minHeight: 14,
                                            ),
                                            child: Text(
                                              '$unreadCount',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Hello greetings
                      Text(
                        'Hello, ${user?.name ?? 'User'} 👋',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'What would you like to do today?',
                        style: TextStyle(
                          color: Color(0xFF8C96A8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Search Bar Container
                      Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.search,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Cari bengkel atau sparepart...',
                                  hintStyle: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Active Vehicle Dropdown Card
                if (activeVehicle != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GestureDetector(
                      onTap: () => _showGarageMenu(context, vehicles),
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2843),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Stack(
                          children: [
                            // Text Content on the Left
                            Positioned(
                              left: 20,
                              top: 20,
                              bottom: 20,
                              right: 150, // leave space for car image
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Active Vehicle Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF2B300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Active Vehicle',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Brand, Model, Spec
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          activeVehicle.brand,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          activeVehicle.model,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${activeVehicle.year} • 1.5L Turbo',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // License Plate & Mileage
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.white30, width: 1.2),
                                        ),
                                        child: Text(
                                          activeVehicle.licensePlate,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        '28.540 km',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Top Right Arrow Icon
                            Positioned(
                              right: 16,
                              top: 16,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                            // Right Car Image
                            Positioned(
                              right: -10,
                              bottom: 10,
                              top: 40,
                              width: 170,
                              child: _buildVehicleImage(vehicleImageUrl, activeVehicle.type),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddVehicleScreen(),
                          ),
                        ).then((_) {
                          context.read<CustomerProfileViewModel>().fetchVehicles();
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2843),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.add_circle_outline, color: Colors.white, size: 48),
                            SizedBox(height: 12),
                            Text(
                              'Tambahkan Kendaraan Baru',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Ketuk di sini untuk mulai menambahkan',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),


                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildGridCard(
                          icon: Icons.calendar_month,
                          iconColor: const Color(0xFFF2B300),
                          title: 'Booking\nService',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BookingServiceScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGridCard(
                          icon: Icons.warning_amber_rounded,
                          iconColor: Colors.red,
                          title: 'Emergency\nSOS',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EmergencySosScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGridCard(
                          icon: Icons.settings,
                          iconColor: Colors.white,
                          title: 'Sparepart\n',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CustomerMainScreen(initialIndex: 1),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Special Promo Banner
                _buildPromoBanner(),
                const SizedBox(height: 24),

                // [NEW] Sparepart Recommendations
                _buildSparepartRecommendations(),
                const SizedBox(height: 24),

                // Frequently Visited Workshops Section
                Consumer<CustomerDashboardViewModel>(
                  builder: (context, vm, child) {
                    final frequent = vm.frequentBengkels;
                    if (frequent.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sering Dikunjungi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: frequent.length,
                              itemBuilder: (context, index) {
                                final b = frequent[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => WorkshopDetailScreen(bengkel: b),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 240,
                                    margin: const EdgeInsets.only(right: 16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: AppColors.border.withValues(alpha: 0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: b['image_url'] != null && b['image_url'].toString().isNotEmpty
                                              ? Image.network(
                                                  b['image_url'] as String,
                                                  width: 50,
                                                  height: 50,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Container(
                                                    color: AppColors.primary.withValues(alpha: 0.1),
                                                    width: 50,
                                                    height: 50,
                                                    child: const Icon(Icons.store, color: AppColors.primary, size: 20),
                                                  ),
                                                )
                                              : Container(
                                                  color: AppColors.primary.withValues(alpha: 0.1),
                                                  width: 50,
                                                  height: 50,
                                                  child: const Icon(Icons.store, color: AppColors.primary, size: 20),
                                                ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                b['name'] as String? ?? 'Bengkel',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(Icons.star, color: Colors.amber, size: 12),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    '${b['rating'] ?? 4.5}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '${b['total_bookings'] ?? 1}x booking',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: AppColors.primary,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${(b['distance_km'] ?? b['distance'] as num?)?.toStringAsFixed(1) ?? '0.0'} km',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // [NEW] Automotive Tips
                _buildAutomotiveTips(),
                const SizedBox(height: 24),

                  // Nearby Workshops Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Bengkel Terdekat',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text(
                                'Lihat Semua',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Loading state
                        if (isBengkelsLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        // Empty state
                        else if (filteredBengkels.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.store_mall_directory_outlined,
                                    size: 48,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    activeVehicle != null
                                        ? 'Tidak ada bengkel yang melayani jenis ${activeVehicle.type}'
                                        : 'Belum ada bengkel yang terdaftar',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        // Dynamic list dari Supabase
                        else
                          ...filteredBengkels.map((b) => GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => WorkshopDetailScreen(bengkel: b),
                                    ),
                                  );
                                },
                                child: _buildWorkshopCard(
                                  imageUrl: b['image_url'] as String? ?? '',
                                  name: b['name'] as String? ?? 'Bengkel',
                                  rating: (b['rating'] as num?)?.toDouble() ?? 4.5,
                                  reviewsCount: (b['reviews_count'] as num?)?.toInt() ?? 0,
                                  distance: (b['distance_km'] ?? b['distance'] as num?)?.toDouble() ?? 0.0,
                                  address: b['address'] as String? ?? '-',
                                  services: List<String>.from(
                                    b['specialization'] as List? ?? [],
                                  ),
                                ),
                              )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
        },
      ),
    );
  }

  Widget _buildVehicleImage(String? url, String type) {
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(type),
      );
    }
    return _buildPlaceholder(type);
  }

  Widget _buildPlaceholder(String type) {
    return Icon(
      type == 'motor' ? Icons.motorcycle_outlined : Icons.directions_car_outlined,
      color: Colors.white24,
      size: 96,
    );
  }

  Widget _buildGridCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    double height = 100.0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2843),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: iconColor, size: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 8,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2843),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Special Promo',
                  style: TextStyle(
                    color: Color(0xFFF2B300),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Diskon Service\nhingga 30%',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '30%',
                    style: TextStyle(
                      color: Color(0xFF1E2843),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'OFF',
                    style: TextStyle(
                      color: Color(0xFF1E2843),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildWorkshopCard({
    required String imageUrl,
    required String name,
    required double rating,
    required int reviewsCount,
    required double distance,
    required String address,
    required List<String> services,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workshop image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 80,
                height: 80,
                color: Colors.grey.shade100,
                child: const Icon(
                  Icons.storefront,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '($reviewsCount) • ${distance.toStringAsFixed(1)} km',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.textSecondary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: services
                      .map(
                        (s) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            s,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceReminder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.build_circle_outlined, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Waktunya Servis Rutin!',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Terakhir servis 3 bulan lalu. Yuk cek kondisi kendaraanmu.',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.red, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildSparepartRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sparepart Terlaris',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                width: 140,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: const Center(
                        child: Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 40),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Oli Motul 5100',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rp 120.000',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAutomotiveTips() {
    final tips = [
      {
        'title': 'Kapan Waktu Terbaik Ganti Oli Mesin?',
        'image': 'assets/images/tip_oil.png',
        'icon': Icons.water_drop_outlined,
        'color': Colors.blue,
        'content': 'Oli mesin sebaiknya diganti setiap 5.000 km hingga 10.000 km, tergantung jenis oli yang digunakan dan intensitas pemakaian. Oli sintetik biasanya bisa bertahan lebih lama hingga 10.000 km, sementara oli mineral disarankan diganti pada 5.000 km.\n\nJangan menunda penggantian oli karena oli yang sudah kotor dapat menyebabkan gesekan mesin menjadi lebih kasar, performa mesin menurun, konsumsi bahan bakar lebih boros, dan pada akhirnya merusak komponen mesin dari dalam.',
      },
      {
        'title': '5 Ciri Kampas Rem Mulai Habis',
        'image': 'assets/images/tip_brake.png',
        'icon': Icons.tire_repair_outlined,
        'color': Colors.orange,
        'content': 'Sistem pengereman sangat vital bagi keselamatan. Berikut 5 tanda Anda harus segera mengganti kampas rem:\n\n1. Terdengar bunyi decit (squealing) yang tajam saat mengerem.\n2. Pedal rem terasa lebih dalam (blong) saat diinjak.\n3. Mobil atau motor terasa bergetar tidak wajar saat dilakukan pengereman.\n4. Terasa ada tarikan ke satu sisi saat mengerem.\n5. Minyak rem berkurang secara drastis di reservoir.\n\nJika mengalami salah satu dari gejala ini, segera bawa kendaraan Anda ke bengkel terdekat!',
      },
      {
        'title': 'Cara Merawat Aki Agar Tahan Lama',
        'image': 'assets/images/tip_battery.png',
        'icon': Icons.battery_charging_full_outlined,
        'color': Colors.green,
        'content': 'Aki merupakan sumber kelistrikan utama. Agar aki awet, perhatikan hal berikut:\n\n- Panaskan kendaraan secara rutin minimal 2-3 kali seminggu jika kendaraan jarang dipakai.\n- Periksa ketinggian air aki (untuk aki basah) setiap bulan. Jangan biarkan air berada di bawah batas lower level.\n- Pastikan terminal aki selalu bersih dari kerak putih (sulfur) yang dapat menghambat arus listrik.\n- Matikan perangkat elektronik (AC, radio, lampu) sebelum mematikan mesin.',
      },
      {
        'title': 'Pentingnya Spooring & Balancing Ban',
        'image': 'assets/images/tip_spooring.png',
        'icon': Icons.car_repair_outlined,
        'color': Colors.redAccent,
        'content': 'Spooring dan Balancing sangat penting dilakukan minimal setiap 10.000 km atau saat setir terasa bergetar dan menarik ke satu arah.\n\n- Spooring meluruskan kembali sudut roda agar sesuai spesifikasi pabrik, sehingga keausan ban menjadi merata.\n- Balancing menyeimbangkan titik berat ban dan velg, mencegah getaran di kemudi pada kecepatan tinggi.\n\nRutin melakukan spooring dan balancing tidak hanya menghemat umur ban, tapi juga membuat komponen kaki-kaki kendaraan (seperti tie rod, ball joint) jauh lebih awet.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            'Tips & Perawatan',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: tips.length,
            itemBuilder: (context, index) {
              final tip = tips[index];
              return GestureDetector(
                onTap: () {
                  _showTipDetailBottomSheet(context, tip);
                },
                child: Container(
                  width: 240,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                          image: tip['image'] != null
                              ? DecorationImage(
                                  image: AssetImage(tip['image'] as String),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                tip['title'] as String,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Baca selengkapnya',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
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
            },
          ),
        ),
      ],
    );
  }

  void _showTipDetailBottomSheet(BuildContext context, Map<String, dynamic> tip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (tip['color'] as Color).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(tip['icon'] as IconData, color: tip['color'] as Color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    tip['title'] as String,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              tip['content'] as String,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Tutup',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}

