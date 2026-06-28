import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/customer_profile_viewmodel.dart';
import '../viewmodels/customer_booking_viewmodel.dart';
import '../models/booking_model.dart';
import 'transaction_payment_screen.dart';

class EmergencySosScreen extends StatefulWidget {
  const EmergencySosScreen({super.key});

  @override
  State<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends State<EmergencySosScreen> {
  int _currentStep = 1; // 1: Form, 2: Searching, 3: Choose Mechanic, 4: Selected Mechanic
  final _problemController = TextEditingController();
  final _addressController = TextEditingController(text: 'Mengambil lokasi Anda...');
  final _detailsController = TextEditingController();
  Position? _currentPosition;
  bool _isLocationLoading = true;
  final MapController _mapController = MapController();
  
  // Mechanics loaded from Supabase or mock fallback
  List<Map<String, dynamic>> _mechanics = [];
  bool _isMechanicsLoading = false;
  int _selectedMechanicIndex = -1;
  
  final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _problemController.dispose();
    _addressController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _addressController.text = 'Lokasi Terpilih (${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)})';
            _isLocationLoading = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
            } catch (_) {}
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _addressController.text = 'GPS Terbatas';
            _isLocationLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('[GPS] Error: $e');
      if (mounted) {
        setState(() {
          _addressController.text = 'GPS Error';
          _isLocationLoading = false;
        });
      }
    }
  }

  bool _isFormValid(dynamic activeVehicle) {
    if (activeVehicle == null) return false;
    if (_problemController.text.trim().isEmpty) return false;
    if (_addressController.text.trim().isEmpty) return false;
    if (_addressController.text == 'Mengambil lokasi Anda...') return false;
    if (_addressController.text == 'GPS Error') return false;
    if (_addressController.text == 'GPS Terbatas') return false;
    if (_detailsController.text.trim().isEmpty) return false;
    return true;
  }

  Future<void> _fetchAvailableMechanics() async {
    setState(() {
      _isMechanicsLoading = true;
    });
    try {
      final supabase = Supabase.instance.client;
      // Fetch available mechanics
      final response = await supabase
          .from('mechanics')
          .select('*, bengkels(name)')
          .eq('status', 'Tersedia');

      final List<dynamic> data = response;
      
      // Map data and generate simulated distance
      final List<Map<String, dynamic>> temp = [];
      double baseDist = 1.2;
      for (var i = 0; i < data.length; i++) {
        final m = data[i];
        final dist = baseDist + (i * 0.4);
        final travelFee = (dist * 5000).toInt(); // Rp 5,000 per km
        final callingFee = 50000 + travelFee;    // Base Rp 50,000 + travel fee
        
        temp.add({
          'id': m['id'],
          'name': m['name'],
          'specialist': m['specialist'] ?? 'Umum',
          'rating': (m['rating'] as num?)?.toDouble() ?? 4.8,
          'services_count': (m['services_count'] as num?)?.toInt() ?? 120,
          'bengkel_id': m['bengkel_id'],
          'bengkel_name': m['bengkels']?['name'] ?? 'Mitra Bengkel',
          'distance': dist,
          'travel_fee': travelFee,
          'calling_fee': callingFee,
          'experience_years': 5 + (i * 2), // Mock years of experience
          'time_estimate': (5 + (i * 3)).toString(),
        });
      }

      // If no available mechanics, fallback to some mock data to prevent empty states
      if (temp.isEmpty) {
        temp.addAll([
          {
            'id': 'mock-m1',
            'name': 'Budi Santoso',
            'specialist': 'Mesin & Transmisi',
            'rating': 4.9,
            'services_count': 234,
            'bengkel_id': 'mock-b1',
            'bengkel_name': 'Mitra Jaya Motor',
            'distance': 1.2,
            'travel_fee': 6000, // 1.2 km * 5000
            'calling_fee': 75000,
            'experience_years': 8,
            'time_estimate': '5',
          },
          {
            'id': 'mock-m2',
            'name': 'Ahmad Wijaya',
            'specialist': 'Kelistrikan & AC',
            'rating': 4.8,
            'services_count': 189,
            'bengkel_id': 'mock-b1',
            'bengkel_name': 'Mitra Jaya Motor',
            'distance': 1.5,
            'travel_fee': 7500, // 1.5 km * 5000
            'calling_fee': 70000,
            'experience_years': 6,
            'time_estimate': '7',
          },
          {
            'id': 'mock-m3',
            'name': 'Dedi Kurniawan',
            'specialist': 'Rem & Kaki-kaki',
            'rating': 4.7,
            'services_count': 142,
            'bengkel_id': 'mock-b2',
            'bengkel_name': 'Sentosa Motor',
            'distance': 2.1,
            'travel_fee': 10500, // 2.1 km * 5000
            'calling_fee': 65000,
            'experience_years': 5,
            'time_estimate': '10',
          },
        ]);
      }

      setState(() {
        _mechanics = temp;
        _isMechanicsLoading = false;
      });
    } catch (e) {
      debugPrint('[Mechanics] Error: $e');
      setState(() {
        _isMechanicsLoading = false;
      });
    }
  }

  void _startSearchSimulation() {
    setState(() {
      _currentStep = 2; // Loading search
    });
    
    // Fetch available mechanics in background
    _fetchAvailableMechanics();

    // After 2.5s simulated loader, transition to selection screen
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _currentStep = 3;
        });
      }
    });
  }

  Future<void> _submitSosOrder(Map<String, dynamic> mechanic) async {
    final profileVM = context.read<CustomerProfileViewModel>();
    final bookingVM = context.read<CustomerBookingViewModel>();
    
    if (profileVM.vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan kendaraan aktif di Garasi terlebih dahulu')),
      );
      return;
    }
    
    final vehicle = profileVM.vehicles[profileVM.selectedVehicleIndex];
    
    try {
      setState(() {
        _isLocationLoading = true; // Show overlay loading
      });

      final createdBooking = await bookingVM.createSosBooking(
        bengkelId: mechanic['bengkel_id']?.toString() ?? 'mock-b1',
        mechanicId: mechanic['id']?.toString() ?? 'mock-m1',
        mechanicName: mechanic['name']?.toString() ?? 'Budi Santoso',
        vehicleId: vehicle.id,
        vehicleName: '${vehicle.brand} ${vehicle.model}',
        vehiclePlate: vehicle.licensePlate,
        complaint: _problemController.text.trim().isNotEmpty
            ? _problemController.text.trim()
            : 'Panggilan Darurat SOS',
        customerAddress: _detailsController.text.trim().isNotEmpty
            ? '${_addressController.text.trim()} (Detail: ${_detailsController.text.trim()})'
            : _addressController.text.trim(),
        travelFee: mechanic['travel_fee'] as int,
      );

      if (mounted) {
        Navigator.pop(context); // Close SOS modal
        // Route customer to Payment Screen for the travel fee DP
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionPaymentScreen(
              booking: createdBooking,
              isInitial: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat pesanan darurat: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileVM = context.watch<CustomerProfileViewModel>();
    final vehicles = profileVM.vehicles;
    final activeVehicle = vehicles.isNotEmpty 
        ? vehicles[profileVM.selectedVehicleIndex] 
        : null;

    Widget body;
    if (_currentStep == 1) {
      body = _buildStepForm(activeVehicle);
    } else if (_currentStep == 2) {
      body = _buildStepSearching();
    } else if (_currentStep == 3) {
      body = _buildStepChooseMechanic();
    } else {
      body = _buildStepSelectedMechanic();
    }

    return Scaffold(
      backgroundColor: _currentStep == 1 ? Colors.white : const Color(0xFFF8FAFC),
      body: body,
    );
  }

  // STEP 1: SOS Form Request
  Widget _buildStepForm(dynamic activeVehicle) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(bottom: 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header backplate
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B3A5E), Color(0xFF102A43)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Emergency SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Get immediate roadside assistance',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Describe Your Problem',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B3A5E)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _problemController,
                    maxLines: 3,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'E.g., Flat tire, engine won\'t start, overheating...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1B3A5E)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Active Vehicle
                  const Text(
                    'Active Vehicle',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B3A5E)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: activeVehicle != null
                        ? Row(
                            children: [
                              Icon(
                                activeVehicle.type == 'motor' ? Icons.motorcycle : Icons.directions_car,
                                color: const Color(0xFF1B3A5E),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${activeVehicle.brand} ${activeVehicle.model}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    activeVehicle.licensePlate,
                                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                                  ),
                                ],
                              )
                            ],
                          )
                        : const Text(
                            'No active vehicle. Please select/add in Garage.',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Location
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Peta Lokasi',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B3A5E)),
                      ),
                      TextButton.icon(
                        onPressed: _determinePosition,
                        icon: const Icon(Icons.my_location, size: 16, color: Colors.blue),
                        label: const Text('Lokasi Saya', style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _currentPosition != null
                                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                                  : const LatLng(-6.2000, 106.8166),
                              initialZoom: 15.0,
                              onTap: (tapPosition, latLng) {
                                setState(() {
                                  _currentPosition = Position(
                                    latitude: latLng.latitude,
                                    longitude: latLng.longitude,
                                    timestamp: DateTime.now(),
                                    accuracy: 1.0,
                                    altitude: 0.0,
                                    altitudeAccuracy: 0.0,
                                    heading: 0.0,
                                    headingAccuracy: 0.0,
                                    speed: 0.0,
                                    speedAccuracy: 0.0,
                                  );
                                  _addressController.text = 'Lokasi Terpilih (${latLng.latitude.toStringAsFixed(6)}, ${latLng.longitude.toStringAsFixed(6)})';
                                });
                                _mapController.move(latLng, _mapController.camera.zoom);
                              },
                              onPositionChanged: (position, hasGesture) {
                                if (hasGesture && position.center != null) {
                                  setState(() {
                                    _currentPosition = Position(
                                      latitude: position.center!.latitude,
                                      longitude: position.center!.longitude,
                                      timestamp: DateTime.now(),
                                      accuracy: 1.0,
                                      altitude: 0.0,
                                      altitudeAccuracy: 0.0,
                                      heading: 0.0,
                                      headingAccuracy: 0.0,
                                      speed: 0.0,
                                      speedAccuracy: 0.0,
                                    );
                                    _addressController.text = 'Lokasi Terpilih (${position.center!.latitude.toStringAsFixed(6)}, ${position.center!.longitude.toStringAsFixed(6)})';
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
                          // Custom centered marker to mimic a draggable/movable experience
                          IgnorePointer(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: Icon(
                                  Icons.location_on,
                                  color: Colors.red.shade700,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                          if (_isLocationLoading)
                            Container(
                              color: Colors.black.withValues(alpha: 0.1),
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.blue),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Alamat / Koordinat Input
                  const Text(
                    'Alamat / Koordinat Lokasi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B3A5E)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _addressController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Alamat atau koordinat lokasi...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: const Icon(Icons.location_on, color: Colors.red, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1B3A5E)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Catatan Detail Lokasi Input
                  const Text(
                    'Catatan Detail Lokasi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B3A5E)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _detailsController,
                    maxLines: 2,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Cth: Samping Indomaret, patokan ruko merah, pagar hitam...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1B3A5E)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isFormValid(activeVehicle) ? () => _startSearchSimulation() : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFormValid(activeVehicle)
                            ? const Color(0xFF1B3A5E)
                            : Colors.grey.shade300,
                        foregroundColor: _isFormValid(activeVehicle)
                            ? Colors.white
                            : Colors.grey.shade500,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: _isFormValid(activeVehicle) ? 2 : 0,
                      ),
                      child: const Text(
                        'Request Emergency Mechanic',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  // STEP 2: Searching Screen
  Widget _buildStepSearching() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      child: SafeArea(
        child: Column(
          children: [
            // Red gradient status bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              color: const Color(0xFFD32F2F),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _currentStep = 1),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Panggilan Darurat',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Mekanik Terdekat Siap Membantu',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Search Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Wrench circle
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue.shade100, width: 2),
                    ),
                    child: const Icon(Icons.build, size: 40, color: Color(0xFF1A73E8)),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Mencari Bengkel Partner...',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B3A5E)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Mohon tunggu, kami sedang mencari bengkel terdekat untuk Anda',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(color: Color(0xFF1B3A5E)),
                ],
              ),
            ),
            
            const Spacer(),
          ],
        ),
      ),
    );
  }

  // STEP 3: Choose Mechanic List
  Widget _buildStepChooseMechanic() {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Red gradient status bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              color: const Color(0xFFD32F2F),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _currentStep = 1),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Panggilan Darurat',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Mekanik Terdekat Siap Membantu',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                'Pilih Mekanik',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B3A5E)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Bengkel Partner Mitra rekomendasi mekanik terdekat',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
            
            Expanded(
              child: _isMechanicsLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _mechanics.length,
                      itemBuilder: (context, idx) {
                        final m = _mechanics[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: const Color(0xFF1B3A5E).withValues(alpha: 0.1),
                                    child: const Icon(Icons.engineering, color: Color(0xFF1B3A5E)),
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
                                              m['name'],
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade50,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.star, color: Colors.amber, size: 12),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    '${m['rating']}',
                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '${m['specialist']} · ${m['bengkel_name']}',
                                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Stats row
                              Row(
                                children: [
                                  _buildBadge(Icons.location_on_outlined, '${m['distance']} km'),
                                  const SizedBox(width: 8),
                                  _buildBadge(Icons.access_time, '~${m['time_estimate']} menit'),
                                  const SizedBox(width: 8),
                                  _buildBadge(Icons.workspace_premium_outlined, '${m['experience_years']} tahun'),
                                ],
                              ),
                              const Divider(height: 24),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    currency.format(m['calling_fee']),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B3A5E)),
                                  ),
                                  Row(
                                    children: [
                                      OutlinedButton(
                                        onPressed: () {
                                          // Skip to next or dismiss
                                          if (idx < _mechanics.length - 1) {
                                            // Scroll to next
                                          }
                                        },
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                        ),
                                        child: const Text('Lewati', style: TextStyle(fontSize: 12)),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedMechanicIndex = idx;
                                            _currentStep = 4; // Detail confirmation
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1B3A5E),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                        ),
                                        child: const Text('Pilih Mekanik', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 4: Selected Mechanic / Confirmation
  Widget _buildStepSelectedMechanic() {
    final m = _mechanics[_selectedMechanicIndex];
    return Container(
      color: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Column(
          children: [
            // Red gradient status bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              color: const Color(0xFFD32F2F),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _currentStep = 3),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Panggilan Darurat',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Mekanik Terdekat Siap Membantu',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            
            // Detail Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mekanik Terpilih',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF1B3A5E).withValues(alpha: 0.1),
                        child: const Icon(Icons.engineering, color: Color(0xFF1B3A5E), size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1B3A5E)),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${m['rating']} (${m['services_count']} ulasan)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m['specialist'],
                              style: const TextStyle(color: Colors.black54, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  
                  const Divider(height: 32),
                  
                  _buildDetailRow('Estimasi tiba', '~${m['time_estimate']} menit'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Jarak', '${m['distance']} km'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Biaya ongkir / DP (Rp 5.000/km)', currency.format(m['travel_fee'])),
                  const SizedBox(height: 12),
                  _buildDetailRow('Biaya Panggilan', currency.format(m['calling_fee'])),
                  
                  const Divider(height: 32),
                  
                  // Note box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Catatan: Biaya panggilan di atas adalah estimasi panggilan mekanik. Biaya ongkir sebesar ${currency.format(m['travel_fee'])} wajib dibayarkan terlebih dahulu sebagai DP sebelum mekanik berangkat.',
                            style: const TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _currentStep = 3),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Ganti Mekanik', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _submitSosOrder(m),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C853),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Konfirmasi Pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.black45),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B3A5E))),
      ],
    );
  }
}
