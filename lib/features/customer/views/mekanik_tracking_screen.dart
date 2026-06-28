import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/booking_model.dart';

class MekanikTrackingScreen extends StatefulWidget {
  final BookingModel booking;
  const MekanikTrackingScreen({super.key, required this.booking});

  @override
  State<MekanikTrackingScreen> createState() => _MekanikTrackingScreenState();
}

class _MekanikTrackingScreenState extends State<MekanikTrackingScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Timer? _timer;
  double? _mechanicLat;
  double? _mechanicLng;
  String _status = '';
  bool _isLoading = true;

  late LatLng _customerLocation;
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _mechanicLat = widget.booking.mechanicLatitude;
    _mechanicLng = widget.booking.mechanicLongitude;
    _status = widget.booking.status;
    
    LatLng parsedLoc;
    if (widget.booking.latitude != null && widget.booking.longitude != null) {
      parsedLoc = LatLng(widget.booking.latitude!, widget.booking.longitude!);
    } else {
      // Generate deterministic customer coordinates based on booking ID (must match mechanic journey screen)
      final double latOffset = (widget.booking.id.hashCode % 100) / 10000.0 - 0.005;
      final double lngOffset = (widget.booking.id.hashCode % 100) / 10000.0 - 0.005;
      parsedLoc = LatLng(-6.2088 + latOffset, 106.8456 + lngOffset);
      if (widget.booking.customerAddress != null) {
        final match = RegExp(r'\((-?\d+\.\d+),\s*(-?\d+\.\d+)\)').firstMatch(widget.booking.customerAddress!);
        if (match != null) {
          final lat = double.tryParse(match.group(1) ?? '');
          final lng = double.tryParse(match.group(2) ?? '');
          if (lat != null && lng != null) {
            parsedLoc = LatLng(lat, lng);
          }
        }
      }
    }
    _customerLocation = parsedLoc;
    
    _startTracking();
  }

  void _startTracking() {
    _fetchLatestLocation();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _fetchLatestLocation();
    });
  }

  Future<void> _fetchLatestLocation() async {
    try {
      final res = await _supabase
          .from('service_bookings')
          .select('mechanic_latitude, mechanic_longitude, status')
          .eq('id', widget.booking.id)
          .maybeSingle();

      if (res != null && mounted) {
        final double? newLat = (res['mechanic_latitude'] as num?)?.toDouble();
        final double? newLng = (res['mechanic_longitude'] as num?)?.toDouble();
        final String newStatus = res['status']?.toString() ?? '';

        setState(() {
          _mechanicLat = newLat;
          _mechanicLng = newLng;
          _status = newStatus;
          _isLoading = false;
        });

        // Fit camera bounds to show both customer and mechanic
        if (newLat != null && newLng != null) {
          _fetchRoute(newLat, newLng);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              try {
                final bounds = LatLngBounds.fromPoints([
                  _customerLocation,
                  LatLng(newLat, newLng),
                ]);
                _mapController.fitCamera(
                  CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.all(60.0),
                  ),
                );
              } catch (_) {
                // Fallback to midpoint centering
                final centerLat = (_customerLocation.latitude + newLat) / 2;
                final centerLng = (_customerLocation.longitude + newLng) / 2;
                _mapController.move(LatLng(centerLat, centerLng), 13.0);
              }
            }
          });
        }

        if (_status == 'Sampai Lokasi') {
          _timer?.cancel();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mekanik telah sampai di lokasi Anda! 🏍️'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      debugPrint('[Tracking] Error fetching live location: $e');
    }
  }

  Future<void> _fetchRoute(double mechLat, double mechLng) async {
    final startLat = mechLat;
    final startLng = mechLng;
    final endLat = _customerLocation.latitude;
    final endLng = _customerLocation.longitude;

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
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('[OSRM Customer] Error fetching route: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LatLng mechPos = _mechanicLat != null && _mechanicLng != null
        ? LatLng(_mechanicLat!, _mechanicLng!)
        : const LatLng(-6.2000, 106.8166); // Jakarta default 2

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Live Tracking Mekanik',
          style: TextStyle(color: Color(0xFF1B3A5E), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1B3A5E)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B3A5E)))
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _mechanicLat != null && _mechanicLng != null
                        ? LatLng(_mechanicLat!, _mechanicLng!)
                        : _customerLocation,
                    initialZoom: 14.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.bengkelin_app',
                    ),
                    MarkerLayer(
                      markers: [
                        // Customer Marker
                        Marker(
                          point: _customerLocation,
                          width: 45,
                          height: 45,
                          child: const Icon(
                            Icons.person_pin_circle,
                            color: Colors.blue,
                            size: 45,
                          ),
                        ),
                        // Mechanic Marker
                        if (_mechanicLat != null && _mechanicLng != null)
                          Marker(
                            point: LatLng(_mechanicLat!, _mechanicLng!),
                            width: 45,
                            height: 45,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.motorcycle,
                                color: Colors.red,
                                size: 32,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (_mechanicLat != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints.isNotEmpty ? _routePoints : [_customerLocation, mechPos],
                            color: Colors.blue.withValues(alpha: 0.8),
                            strokeWidth: 4.0,
                            pattern: _routePoints.isNotEmpty ? const StrokePattern.solid() : StrokePattern.dashed(segments: const [10, 10]),
                          ),
                        ],
                      ),
                  ],
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF1B3A5E).withValues(alpha: 0.1),
                                child: const Icon(Icons.engineering, color: Color(0xFF1B3A5E)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.booking.mechanicName ?? 'Mekanik Anda',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      'Status: $_status',
                                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          const Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.blue),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Peta memantau perjalanan mekanik dari bengkel ke lokasi Anda.',
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
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
    );
  }
}
