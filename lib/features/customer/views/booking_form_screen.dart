import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../viewmodels/customer_profile_viewmodel.dart';
import '../viewmodels/customer_booking_viewmodel.dart';
import '../models/vehicle_model.dart';
import '../models/booking_model.dart';
import '../models/bengkel_service_model.dart';
import '../viewmodels/bengkel_service_viewmodel.dart';

class BookingFormScreen extends StatefulWidget {
  final Map<String, dynamic> bengkel;
  final String? initialService;

  const BookingFormScreen({super.key, required this.bengkel, this.initialService});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  VehicleModel? _selectedVehicle;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  final _complaintController = TextEditingController();
  final _addressController = TextEditingController();

  double? _latitude;
  double? _longitude;
  bool _isMapLoading = false;
  final MapController _mapController = MapController();

  bool _isHomeService = true;
  final List<BengkelServiceModel> _selectedServices = [];
  List<BookingModel> _existingBookings = [];
  bool _isLoadingBookings = false;

  final List<String> _timeSlots = [
    '08:00', '09:00', '10:00', '11:00',
    '13:00', '14:00', '15:00', '16:00'
  ];

  final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final profileVM = context.read<CustomerProfileViewModel>();
        if (profileVM.activeVehicle != null) {
          setState(() {
            _selectedVehicle = profileVM.activeVehicle;
          });
        }

        final authVM = context.read<AuthViewModel>();
        if (authVM.currentUser != null) {
          final savedLat = authVM.currentUser!.latitude;
          final savedLng = authVM.currentUser!.longitude;
          setState(() {
            _latitude = savedLat;
            _longitude = savedLng;
            if (authVM.currentUser!.address != null && authVM.currentUser!.address!.isNotEmpty) {
              _addressController.text = authVM.currentUser!.address!;
            } else {
              _addressController.text = "Jl. Bunga Rampai No. 12, Jakarta Timur";
            }
          });
          if (savedLat != null && savedLng != null) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                _mapController.move(LatLng(savedLat, savedLng), 15.0);
              }
            });
          }
        } else {
          _addressController.text = "Jl. Bunga Rampai No. 12, Jakarta Timur";
        }
      }

      if (widget.initialService != null) {
        try {
          final services = context.read<BengkelServiceViewModel>().services;
          final initial = services.firstWhere((s) => s.name == widget.initialService);
          setState(() {
            _selectedServices.add(initial);
          });
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _complaintController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371; // Earth's radius in km
    final dLat = (lat2 - lat1) * (pi / 180);
    final dLon = (lon2 - lon1) * (pi / 180);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double get _currentDistance {
    if (_latitude == null || _longitude == null) {
      return (widget.bengkel['distance_km'] as num?)?.toDouble() ?? 0.0;
    }
    final bLat = (widget.bengkel['latitude'] as num?)?.toDouble();
    final bLng = (widget.bengkel['longitude'] as num?)?.toDouble();
    if (bLat == null || bLng == null) {
      return (widget.bengkel['distance_km'] as num?)?.toDouble() ?? 0.0;
    }
    return _calculateDistance(_latitude!, _longitude!, bLat, bLng);
  }

  int get _totalPrice {
    int total = 0;
    for (var s in _selectedServices) {
      total += s.basePrice;
    }
    if (_isHomeService) {
      total += (_currentDistance * 5000).ceil();
    }
    return total;
  }

  int _parseDurationToMinutes(String durationStr) {
    final normalized = durationStr.toLowerCase().trim();
    if (normalized.contains('menit')) {
      final numberPart = normalized.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(numberPart) ?? 30;
    } else if (normalized.contains('jam')) {
      final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(normalized);
      if (match != null) {
        final val = double.tryParse(match.group(0)!);
        if (val != null) {
          return (val * 60).round();
        }
      }
      return 60;
    }
    return 120; // default 2 hours
  }

  int get _totalDurationMinutes {
    int total = 0;
    for (var s in _selectedServices) {
      total += _parseDurationToMinutes(s.duration);
    }
    return total == 0 ? 120 : total;
  }

  void _fetchExistingBookings() async {
    if (_selectedDate == null) return;
    setState(() => _isLoadingBookings = true);
    try {
      final bookingVM = context.read<CustomerBookingViewModel>();
      final bengkelId = widget.bengkel['id']?.toString() ?? '';
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final list = await bookingVM.fetchBookingsForBengkelAndDate(bengkelId, dateStr);
      setState(() {
        _existingBookings = list;
        // Re-validate current selection
        if (_selectedTimeSlot != null && _isSlotUnavailable(_selectedTimeSlot!)) {
          _selectedTimeSlot = null;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Slot waktu yang dipilih telah terisi atau bentrok.')),
          );
        }
      });
    } catch (e) {
      debugPrint('Error fetching existing bookings: $e');
    } finally {
      setState(() => _isLoadingBookings = false);
    }
  }

  bool _isSlotUnavailable(String slot) {
    final slotParts = slot.split(':');
    if (slotParts.length != 2) return false;
    final slotMinutes = int.parse(slotParts[0]) * 60 + int.parse(slotParts[1]);

    final proposedDuration = _totalDurationMinutes;
    final proposedEnd = slotMinutes + proposedDuration;

    for (var booking in _existingBookings) {
      final startParts = booking.bookingTime.split(':');
      if (startParts.length != 2) continue;
      final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      
      final duration = booking.estimatedDuration;
      final endMinutes = startMinutes + duration;

      if (slotMinutes < endMinutes && startMinutes < proposedEnd) {
        return true;
      }
    }
    return false;
  }

  String get _estimatedFinishTime {
    if (_selectedTimeSlot == null) return '';
    final parts = _selectedTimeSlot!.split(':');
    if (parts.length != 2) return '';
    final minutes = int.parse(parts[0]) * 60 + int.parse(parts[1]) + _totalDurationMinutes;
    
    final endHours = (minutes ~/ 60) % 24;
    final endMins = minutes % 60;
    
    final hoursStr = endHours.toString().padLeft(2, '0');
    final minsStr = endMins.toString().padLeft(2, '0');
    
    return '$hoursStr:$minsStr';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B3A5E),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null; // reset slot on date change
      });
      _fetchExistingBookings();
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicle == null || _selectedServices.isEmpty || _selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi semua pilihan jadwal, kendaraan, dan layanan')),
      );
      return;
    }

    if (_isSlotUnavailable(_selectedTimeSlot!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slot waktu terpilih sudah terisi atau bentrok. Silakan pilih slot lain.')),
      );
      return;
    }

    final bookingVM = context.read<CustomerBookingViewModel>();
    final bengkelId = widget.bengkel['id']?.toString() ?? '';
    final serviceNames = _selectedServices.map((s) => s.name).join(', ');
    
    try {
      final distance = _isHomeService ? _currentDistance : 0.0;
      final fee = _isHomeService ? (distance * 5000).ceil() : 0;

      await bookingVM.createBooking(
        bengkelId: bengkelId,
        vehicleId: _selectedVehicle!.id,
        vehicleName: '${_selectedVehicle!.brand} ${_selectedVehicle!.model}',
        vehiclePlate: _selectedVehicle!.licensePlate,
        serviceCategory: serviceNames,
        bookingDate: _selectedDate!,
        bookingTime: _selectedTimeSlot!,
        complaint: _complaintController.text.trim(),
        isHomeService: _isHomeService,
        customerAddress: _isHomeService ? _addressController.text.trim() : null,
        latitude: _isHomeService ? _latitude : null,
        longitude: _isHomeService ? _longitude : null,
        homeServiceFee: fee,
        initialPaymentAmount: _totalPrice,
        estimatedDuration: _totalDurationMinutes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking berhasil dibuat! Menunggu konfirmasi bengkel.')),
        );
        Navigator.pop(context); // close form
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat booking: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileVM = context.watch<CustomerProfileViewModel>();
    final bookingVM = context.watch<CustomerBookingViewModel>();
    final serviceVM = context.watch<BengkelServiceViewModel>();
    final vehicles = profileVM.vehicles;
    final name = widget.bengkel['name'] as String? ?? 'Bengkel';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Buat Pesanan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      ),
      body: bookingVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Kendaraan (Needed for backend)
                          const Text('Pilih Kendaraan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<VehicleModel>(
                            value: _selectedVehicle,
                            hint: const Text('Pilih dari garasi Anda'),
                            items: vehicles.map((v) {
                              return DropdownMenuItem<VehicleModel>(
                                value: v,
                                child: Text('${v.brand} ${v.model} (${v.licensePlate})'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedVehicle = val);
                              }
                            },
                            validator: (val) => val == null ? 'Pilih kendaraan' : null,
                            decoration: _inputDecoration(),
                          ),
                          if (vehicles.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Anda belum menambahkan kendaraan di Profile.',
                                style: TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            ),
                          const SizedBox(height: 24),

                          // Mode Layanan
                          const Text('Pilih Mode Layanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _isHomeService = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      color: !_isHomeService ? Colors.blue.shade50 : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: !_isHomeService ? const Color(0xFF1B3A5E) : const Color(0xFFEEEEEE),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(Icons.storefront_outlined, color: !_isHomeService ? const Color(0xFF1B3A5E) : AppColors.textSecondary, size: 32),
                                        const SizedBox(height: 8),
                                        Text('Ke Workshop', style: TextStyle(fontWeight: FontWeight.bold, color: !_isHomeService ? const Color(0xFF1B3A5E) : AppColors.textPrimary)),
                                        const SizedBox(height: 4),
                                        const Text('Kendaraan Anda ke\nbengkel', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _isHomeService = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      color: _isHomeService ? Colors.blue.shade50 : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _isHomeService ? const Color(0xFF1B3A5E) : const Color(0xFFEEEEEE),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(Icons.home_outlined, color: _isHomeService ? const Color(0xFF1B3A5E) : AppColors.textSecondary, size: 32),
                                        const SizedBox(height: 8),
                                        Text('Mekanik ke Sini', style: TextStyle(fontWeight: FontWeight.bold, color: _isHomeService ? const Color(0xFF1B3A5E) : AppColors.textPrimary)),
                                        const SizedBox(height: 4),
                                        const Text('Mekanik datang ke lokasi\nAnda', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Pilih Layanan
                          const Text('Pilih Layanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          if (serviceVM.isLoading)
                            const Center(child: CircularProgressIndicator())
                          else if (serviceVM.services.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: Text('Belum ada layanan tersedia', style: TextStyle(color: Colors.grey))),
                            )
                          else
                            ...serviceVM.services.map((service) {
                              final isSelected = _selectedServices.contains(service);
                              final price = service.basePrice;
                              
                              int iconCode = 0xe8b8; // default settings icon
                              if (service.iconCode != null) {
                                final intParsed = int.tryParse(service.iconCode!);
                                if (intParsed != null) {
                                  iconCode = intParsed;
                                }
                              }

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedServices.remove(service);
                                    } else {
                                      _selectedServices.add(service);
                                    }
                                    
                                    // Recheck validity of selected slot with new services duration
                                    if (_selectedTimeSlot != null && _isSlotUnavailable(_selectedTimeSlot!)) {
                                      _selectedTimeSlot = null;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Jadwal bentrok karena durasi layanan berubah.')),
                                      );
                                    }
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.blue.shade50 : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF1B3A5E) : const Color(0xFFEEEEEE),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(IconData(iconCode, fontFamily: 'MaterialIcons'), color: Colors.blue.shade400, size: 28),
                                      const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            service.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            service.description,
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          currencyFormat.format(price),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B3A5E)),
                                        ),
                                        const SizedBox(height: 8),
                                        Icon(
                                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                                          color: isSelected ? const Color(0xFF1B3A5E) : Colors.grey.shade300,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 12),

                          // Alamat Lokasi
                          if (_isHomeService) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Alamat Lokasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                TextButton.icon(
                                  onPressed: () async {
                                    try {
                                      setState(() => _isMapLoading = true);
                                      LocationPermission permission = await Geolocator.checkPermission();
                                      if (permission == LocationPermission.denied) {
                                        permission = await Geolocator.requestPermission();
                                      }
                                      if (permission == LocationPermission.whileInUse ||
                                          permission == LocationPermission.always) {
                                        final pos = await Geolocator.getCurrentPosition();
                                        final latLng = LatLng(pos.latitude, pos.longitude);
                                        setState(() {
                                          _latitude = pos.latitude;
                                          _longitude = pos.longitude;
                                        });
                                        _mapController.move(latLng, 15.0);
                                      }
                                    } catch (e) {
                                      debugPrint('Gagal mengambil lokasi: $e');
                                    } finally {
                                      setState(() => _isMapLoading = false);
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
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _addressController,
                              decoration: _inputDecoration().copyWith(
                                prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.textSecondary),
                                hintText: 'Masukkan alamat pengantaran/servis...',
                              ),
                              validator: (val) {
                                if (_isHomeService && (val == null || val.trim().isEmpty)) {
                                  return 'Masukkan alamat lokasi servis';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 180,
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
                                          _latitude ?? -6.2000,
                                          _longitude ?? 106.8166,
                                        ),
                                        initialZoom: 15.0,
                                        onTap: (tapPosition, latLng) {
                                          setState(() {
                                            _latitude = latLng.latitude;
                                            _longitude = latLng.longitude;
                                          });
                                          _mapController.move(latLng, _mapController.camera.zoom);
                                        },
                                        onPositionChanged: (position, hasGesture) {
                                          if (hasGesture) {
                                            setState(() {
                                              _latitude = position.center.latitude;
                                              _longitude = position.center.longitude;
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
                            if (_latitude != null && _longitude != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Koordinat Terpilih: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                          ],

                          // Jadwal
                          const Text('Jadwal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFF1B3A5E)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedDate == null ? 'dd/mm/yyyy' : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                                    style: TextStyle(fontSize: 15, color: _selectedDate == null ? AppColors.textSecondary : Colors.black),
                                  ),
                                  const Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_selectedDate == null)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'Pilih tanggal terlebih dahulu untuk melihat jam yang tersedia.',
                                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                              ),
                            )
                          else if (_isLoadingBookings)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            )
                          else ...[
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: _timeSlots.map((time) {
                                final isSelected = _selectedTimeSlot == time;
                                final isUnavailable = _isSlotUnavailable(time);
                                
                                return GestureDetector(
                                  onTap: isUnavailable
                                      ? () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Jam $time sudah terisi/bentrok dengan booking lain.'),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      : () => setState(() => _selectedTimeSlot = time),
                                  child: Container(
                                    width: (MediaQuery.of(context).size.width - 40 - 36) / 4, // 4 items per row
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF1B3A5E)
                                          : isUnavailable
                                              ? Colors.grey.shade200
                                              : const Color(0xFFEEEEEE),
                                      borderRadius: BorderRadius.circular(20),
                                      border: isUnavailable
                                          ? Border.all(color: Colors.grey.shade300)
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      time,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : isUnavailable
                                                ? Colors.grey.shade400
                                                : AppColors.textSecondary,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        decoration: isUnavailable ? TextDecoration.lineThrough : null,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                          if (_selectedTimeSlot != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade100),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_filled, color: Colors.blue, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Estimasi Waktu Pengerjaan: $_totalDurationMinutes menit',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B3A5E)),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Selesai sekitar pukul $_estimatedFinishTime WIB',
                                          style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),

                          // Catatan
                          const Text('Catatan untuk Bengkel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _complaintController,
                            maxLines: 4,
                            decoration: _inputDecoration().copyWith(
                              hintText: 'Jelaskan kondisi atau keluhan kendaraan Anda...',
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Panel
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Estimasi Biaya', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                if (_isHomeService) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '+ Ongkos Kunjungan: ${currencyFormat.format(_currentDistance * 5000)}',
                                    style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  currencyFormat.format(_totalPrice),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1B3A5E)),
                                ),
                                const SizedBox(height: 4),
                                const Text('Belum termasuk suku cadang', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                              ],
                            ),
                            const Icon(Icons.shield_outlined, color: Colors.blueGrey, size: 32),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B3A5E),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Langsung Booking →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1B3A5E)),
      ),
      hintStyle: const TextStyle(color: Colors.grey),
    );
  }
}
