import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../viewmodels/mekanik_dashboard_viewmodel.dart';
import '../models/mechanic_task_model.dart';

class MekanikJourneyScreen extends StatefulWidget {
  final MechanicTaskModel task;
  const MekanikJourneyScreen({super.key, required this.task});

  @override
  State<MekanikJourneyScreen> createState() => _MekanikJourneyScreenState();
}

class _MekanikJourneyScreenState extends State<MekanikJourneyScreen> {
  late LatLng _customerLoc;
  LatLng? _mechanicLoc;
  String _currentStatus = '';
  bool _isActionLoading = false;

  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSubscription;
  Timer? _simTimer;
  bool _isTrackingInitialized = false;
  bool _isSimulating = false;
  List<LatLng> _routePoints = [];
  List<LatLng> _simPoints = [];

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.task.status;
    
    LatLng parsedLoc;
    if (widget.task.latitude != null && widget.task.longitude != null) {
      parsedLoc = LatLng(widget.task.latitude!, widget.task.longitude!);
    } else {
      // Generate deterministic customer coordinates based on task ID
      final double latOffset = (widget.task.id.hashCode % 100) / 10000.0 - 0.005;
      final double lngOffset = (widget.task.id.hashCode % 100) / 10000.0 - 0.005;
      parsedLoc = LatLng(-6.2088 + latOffset, 106.8456 + lngOffset);
      if (widget.task.customerAddress != null) {
        final match = RegExp(r'\((-?\d+\.\d+),\s*(-?\d+\.\d+)\)').firstMatch(widget.task.customerAddress!);
        if (match != null) {
          final lat = double.tryParse(match.group(1) ?? '');
          final lng = double.tryParse(match.group(2) ?? '');
          if (lat != null && lng != null) {
            parsedLoc = LatLng(lat, lng);
          }
        }
      }
    }
    _customerLoc = parsedLoc;

    // Initial mechanic coordinates
    final mLat = widget.task.mechanicLatitude ?? -6.2000;
    final mLng = widget.task.mechanicLongitude ?? 106.8166;
    _mechanicLoc = LatLng(mLat, mLng);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _simTimer?.cancel();
    super.dispose();
  }

  Future<void> _initLocationUpdates(MekanikDashboardViewModel vm) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        if (!_isSimulating) {
          _updateLocation(vm, LatLng(pos.latitude, pos.longitude));
          _fetchRoute();
        }
        
        _positionSubscription?.cancel();
        _positionSubscription = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((position) {
          if (!_isSimulating && mounted) {
            _updateLocation(vm, LatLng(position.latitude, position.longitude));
            _fetchRoute();
          }
        });
      }
    } catch (e) {
      debugPrint('[GPS] Error tracking location: $e');
    }
  }

  void _updateLocation(MekanikDashboardViewModel vm, LatLng loc) {
    if (mounted) {
      setState(() {
        _mechanicLoc = loc;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(loc, _mapController.camera.zoom);
        }
      });
    }
    vm.updateLiveLocation(widget.task.id, loc.latitude, loc.longitude);
  }

  Future<void> _fetchRoute() async {
    if (_mechanicLoc == null) return;
    
    final startLat = _mechanicLoc!.latitude;
    final startLng = _mechanicLoc!.longitude;
    final endLat = _customerLoc.latitude;
    final endLng = _customerLoc.longitude;

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson'
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final coords = data['routes'][0]['geometry']['coordinates'] as List;
          final parsedPoints = coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList();
          
          if (mounted) {
            setState(() {
              _routePoints = parsedPoints;
            });
            _generateSimPoints();
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('[OSRM] Error fetching route: $e');
    }

    // Fallback to straight line if OSRM fails
    _generateFallbackSimPoints(startLat, startLng, endLat, endLng);
  }

  void _generateSimPoints() {
    if (_routePoints.isEmpty) return;
    const int totalSteps = 8;
    final List<LatLng> points = [];
    if (_routePoints.length <= totalSteps) {
      points.addAll(_routePoints);
      while (points.length < totalSteps) {
        points.add(_routePoints.last);
      }
    } else {
      for (int i = 0; i < totalSteps; i++) {
        final int index = ((i / (totalSteps - 1)) * (_routePoints.length - 1)).round();
        points.add(_routePoints[index]);
      }
    }
    setState(() {
      _simPoints = points;
    });
  }

  void _generateFallbackSimPoints(double startLat, double startLng, double endLat, double endLng) {
    const int totalSteps = 8;
    final List<LatLng> points = [];
    for (int i = 1; i <= totalSteps; i++) {
      final double progress = i / totalSteps;
      final double lat = startLat + (endLat - startLat) * progress;
      final double lng = startLng + (endLng - startLng) * progress;
      points.add(LatLng(lat, lng));
    }
    setState(() {
      _routePoints = [LatLng(startLat, startLng), LatLng(endLat, endLng)];
      _simPoints = points;
    });
  }

  Future<void> _launchWhatsApp(String? phone) async {
    if (phone == null || phone.isEmpty || phone == '-') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nomor telepon customer tidak tersedia')),
        );
      }
      return;
    }
    String formattedPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '62${formattedPhone.substring(1)}';
    }
    final whatsappUrl = Uri.parse('https://wa.me/$formattedPhone');
    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membuka WhatsApp')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka WhatsApp')),
        );
      }
    }
  }

  void _startSimulation(MekanikDashboardViewModel vm) {
    _simTimer?.cancel();
    _positionSubscription?.cancel();
    _isSimulating = true;

    if (_simPoints.isEmpty) {
      final startLat = _mechanicLoc?.latitude ?? -6.2000;
      final startLng = _mechanicLoc?.longitude ?? 106.8166;
      _generateFallbackSimPoints(startLat, startLng, _customerLoc.latitude, _customerLoc.longitude);
    }

    int currentStep = 0;
    final int totalSteps = _simPoints.length;

    _simTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (currentStep >= totalSteps) {
        timer.cancel();
        _arriveAtCustomer(vm);
        return;
      }

      final nextLoc = _simPoints[currentStep];
      currentStep++;
      _updateLocation(vm, nextLoc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTW: Mekanik menuju lokasi ($currentStep/$totalSteps) 🏍️'),
            duration: const Duration(milliseconds: 1500),
            backgroundColor: Colors.purple,
          ),
        );
      }
    });
  }

  Future<void> _launchGoogleMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${_customerLoc.latitude},${_customerLoc.longitude}'
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membuka Google Maps')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka Google Maps')),
        );
      }
    }
  }

  Future<void> _startJourney(MekanikDashboardViewModel vm) async {
    setState(() => _isActionLoading = true);
    try {
      await vm.startJourney(widget.task.id);
      setState(() {
        _currentStatus = 'Menuju Lokasi';
        _mechanicLoc ??= const LatLng(-6.2000, 106.8166);
      });
      await _initLocationUpdates(vm);
      await _fetchRoute();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perjalanan Dimulai! Status: Menuju Lokasi'),
            backgroundColor: Colors.purple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Future<void> _arriveAtCustomer(MekanikDashboardViewModel vm) async {
    setState(() => _isActionLoading = true);
    try {
      await vm.arriveAtLocation(widget.task.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mekanik telah sampai di lokasi customer! ✅'),
            backgroundColor: Colors.teal,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MekanikDashboardViewModel>();
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    // Initial avatar characters
    final initials = (widget.task.customerName ?? 'C')
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();

    final isOtw = _currentStatus == 'Menuju Lokasi';

    if (!_isTrackingInitialized) {
      _isTrackingInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchRoute();
        _initLocationUpdates(vm);
      });
    }

    final statusColor = vm.mechanicStatus == 'Tersedia'
        ? const Color(0xFF00C853)
        : vm.mechanicStatus == 'Bertugas'
            ? Colors.orange
            : Colors.grey;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF1B3A5E),
              radius: 18,
              child: Text(
                vm.mechanicName.isNotEmpty ? vm.mechanicName[0].toUpperCase() : 'M',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    vm.mechanicName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B3A5E),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vm.mechanicStatus,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Color(0xFF1B3A5E)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Map View
              Expanded(
                flex: 4,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _customerLoc,
                        initialZoom: 14.5,
                        onTap: (_, _) => _launchGoogleMaps(),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.bengkelin_app',
                        ),
                        if (_routePoints.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints,
                                color: Colors.blue.withValues(alpha: 0.8),
                                strokeWidth: 4.0,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: [
                            // Customer marker
                            Marker(
                              point: _customerLoc,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.person_pin_circle,
                                color: Colors.blue,
                                size: 40,
                              ),
                            ),
                            // Mechanic marker (only when journey starts)
                            if (isOtw && _mechanicLoc != null)
                              Marker(
                                point: _mechanicLoc!,
                                width: 40,
                                height: 40,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.motorcycle,
                                    color: Colors.red,
                                    size: 24,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    // Back Button Overlay
                    Positioned(
                      top: 16,
                      left: 16,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                    // Shortcut/Navigation pointer overlay
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton(
                        mini: true,
                        backgroundColor: const Color(0xFF1B3A5E),
                        foregroundColor: Colors.white,
                        onPressed: _launchGoogleMaps,
                        tooltip: 'Navigasi via Google Maps',
                        child: const Icon(Icons.navigation, size: 20),
                      ),
                    ),
                    // Home/Center Button Overlay
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: GestureDetector(
                        onTap: () {
                          if (_mechanicLoc != null) {
                            _mapController.move(_mechanicLoc!, 14.5);
                          } else {
                            _mapController.move(_customerLoc, 14.5);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.home_outlined, color: Color(0xFF1B3A5E), size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Customer & Task Info details
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Profile Row
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              radius: 24,
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Color(0xFF1B3A5E),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.task.customerName ?? 'Customer',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF1B3A5E),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${widget.task.vehicleName ?? "-"} · ${widget.task.vehiclePoliceNumber ?? ""}',
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.phone, color: Color(0xFF1B3A5E)),
                              onPressed: () => _launchWhatsApp(widget.task.customerPhone),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Location & Time Detail
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: Colors.grey, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.task.customerAddress ?? 'Lokasi tidak dispesifikasikan',
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.grey, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Jadwal: ${DateFormat('dd/MM/yyyy').format(widget.task.bookingDate)} | ${widget.task.bookingTime}',
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Home Service',
                              style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Services Detail
                      const Text(
                        'Layanan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B3A5E)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.build, color: Colors.grey, size: 14),
                          const SizedBox(width: 8),
                          Text(widget.task.serviceCategory, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Complaint Note
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.sticky_note_2_outlined, color: Colors.amber, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.task.complaint != null && widget.task.complaint!.isNotEmpty
                                    ? '"${widget.task.complaint}"'
                                    : '"Tidak ada keluhan khusus dari pelanggan."',
                                style: const TextStyle(fontSize: 12, color: Colors.black87, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Estimasi Jasa Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Estimasi Jasa',
                            style: TextStyle(color: Colors.black54, fontSize: 13),
                          ),
                          Text(
                            currency.format(widget.task.totalPrice > 0 ? widget.task.totalPrice : (widget.task.initialPaymentAmount > 0 ? widget.task.initialPaymentAmount : widget.task.homeServiceFee)),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3A5E)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 80), // bottom spacer
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Action Button Overlay
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 50,
              width: double.infinity,
              child: _isActionLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B3A5E)))
                  : !isOtw
                      ? ElevatedButton.icon(
                          onPressed: () => _startJourney(vm),
                          icon: const Icon(Icons.send, color: Colors.white, size: 18),
                          label: const Text(
                            'Mulai Perjalanan ke Lokasi',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B3A5E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _startSimulation(vm),
                                icon: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                                label: const Text(
                                  'Simulasi OTW',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _arriveAtCustomer(vm),
                                icon: const Icon(Icons.check, color: Colors.white, size: 18),
                                label: const Text(
                                  'Tiba di Lokasi',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00C853),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
