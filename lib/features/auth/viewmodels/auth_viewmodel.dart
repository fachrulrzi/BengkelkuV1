import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  // Data mekanik yang sedang login (jika role == mekanik)
  Map<String, dynamic>? _mechanicData;
  Map<String, dynamic>? get mechanicData => _mechanicData;
  String? get mechanicBengkelId => _mechanicData?['bengkel_id'] as String?;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }


  Future<void> login(String identifier, String password) async {
    _setLoading(true);
    final trimmedIdentifier = identifier.trim();
    try {
      // 1. Cek dulu apakah ini login mekanik (dari tabel mechanics)
      Map<String, dynamic>? mechanicResult;
      try {
        mechanicResult = await _supabase
            .from('mechanics')
            .select()
            .eq('email', trimmedIdentifier)
            .maybeSingle();

        if (mechanicResult == null) {
          mechanicResult = await _supabase
              .from('mechanics')
              .select()
              .eq('phone', trimmedIdentifier)
              .maybeSingle();
        }

        if (mechanicResult == null) {
          mechanicResult = await _supabase
              .from('mechanics')
              .select()
              .eq('name', trimmedIdentifier)
              .maybeSingle();
        }
      } catch (mechanicLookupError) {
        debugPrint('[Auth] Mechanic lookup failed: $mechanicLookupError');
      }

      if (mechanicResult != null) {
        // Verifikasi password mekanik
        final storedPassword = mechanicResult['password']?.toString() ?? '';
        if (storedPassword != password) {
          throw Exception('Password mekanik salah.');
        }
        _mechanicData = mechanicResult;
        _currentUser = UserModel(
          id: mechanicResult['id'] as String,
          name: mechanicResult['name'] as String? ?? 'Mekanik',
          email: mechanicResult['email'] as String? ?? trimmedIdentifier,
          phone: mechanicResult['phone'] as String?,
          role: UserRole.mekanik,
        );
        _setLoading(false);
        notifyListeners();
        return;
      }

      // 2. Cari email di tabel users by email, phone, atau full_name
      String resolvedEmail = trimmedIdentifier;
      try {
        Map<String, dynamic>? userData;
        
        userData = await _supabase
            .from('users')
            .select()
            .eq('email', trimmedIdentifier)
            .maybeSingle();

        if (userData == null) {
          userData = await _supabase
              .from('users')
              .select()
              .eq('phone', trimmedIdentifier)
              .maybeSingle();
        }

        if (userData == null) {
          userData = await _supabase
              .from('users')
              .select()
              .eq('full_name', trimmedIdentifier)
              .maybeSingle();
        }

        if (userData != null && userData['email'] != null) {
          resolvedEmail = userData['email'] as String;
        }
      } catch (userLookupError) {
        debugPrint('[Auth] User lookup failed: $userLookupError');
      }

      // 3. Login via Supabase Auth
      final response = await _supabase.auth.signInWithPassword(
        email: resolvedEmail,
        password: password,
      );

      if (response.user != null) {
        final userData = await _supabase
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .maybeSingle();

        if (userData != null) {
          _currentUser = UserModel.fromJson(userData);
        } else {
          final data = response.user!.userMetadata;
          _currentUser = UserModel(
            id: response.user!.id,
            name: data?['full_name'] ?? 'User',
            email: response.user!.email ?? resolvedEmail,
            phone: data?['phone'],
            role: UserRole.values.firstWhere(
              (e) => e.name == (data?['role'] ?? 'customer'),
              orElse: () => UserRole.customer,
            ),
          );
        }
      }
    } catch (error) {
      _setLoading(false);
      rethrow;
    }
    _setLoading(false);
  }

  Future<void> loginWithGoogle() async {
    _setLoading(true);
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'bengkelinapp://login-callback',
      );
    } catch (error) {
      _setLoading(false);
      rethrow;
    }
    _setLoading(false);
  }

  Future<void> checkSession() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _setLoading(true);
      try {
        final userData = await _supabase
            .from('users')
            .select()
            .eq('id', session.user.id)
            .maybeSingle();

        if (userData != null) {
          _currentUser = UserModel.fromJson(userData);
        } else {
          final data = session.user.userMetadata;
          _currentUser = UserModel(
            id: session.user.id,
            name: data?['full_name'] ?? 'User',
            email: session.user.email ?? '',
            phone: data?['phone'],
            address: data?['address'],
            role: UserRole.values.firstWhere(
              (e) => e.name == (data?['role'] ?? 'customer'),
              orElse: () => UserRole.customer,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error checking session: $e');
        _currentUser = null;
      } finally {
        _setLoading(false);
      }
    } else {
      _currentUser = null;
      // Do not call notifyListeners here synchronously - it causes setState during build
      Future.microtask(() => notifyListeners());
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      // Jika mekanik, tidak perlu signOut dari Supabase Auth
      if (_currentUser?.role != UserRole.mekanik) {
        await _supabase.auth.signOut();
      }
      _currentUser = null;
      _mechanicData = null;
      notifyListeners();
    } catch (error) {
      _setLoading(false);
      rethrow;
    }
    _setLoading(false);
  }

  Future<void> registerCustomer({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'phone': phone,
          'role': UserRole.customer.name,
        },
      );
    } catch (error) {
      _setLoading(false);
      rethrow;
    }
    _setLoading(false);
  }

  Future<void> registerAdmin({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'phone': phone,
          'role': UserRole.admin.name,
        },
      );
    } catch (error) {
      _setLoading(false);
      rethrow;
    }
    _setLoading(false);
  }

  Future<void> registerPartner({
    required String workshopName,
    required String ownerName,
    required String email,
    required String phone,
    required String address,
    required String specialization,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': ownerName,
          'phone': phone,
          'role': UserRole.bengkel.name,
        },
      );

      final userId = response.user?.id;
      if (userId != null) {
        // Insert directly to bengkels table (public.users is handled by the DB trigger)
        await _supabase.from('bengkels').insert({
          'owner_id': userId,
          'name': workshopName,
          'address': address,
          'phone': phone,
          'specialization': [specialization], // specialization is a text array
          'status': 'pending', // Default status
        });
      }
    } catch (error) {
      _setLoading(false);
      rethrow;
    }
    _setLoading(false);
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
  }) async {
    _setLoading(true);
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('users').update({
          'full_name': name,
          'phone': phone,
        }).eq('id', user.id);

        if (_currentUser != null) {
          _currentUser = UserModel(
            id: _currentUser!.id,
            name: name,
            email: _currentUser!.email,
            phone: phone,
            address: _currentUser!.address,
            role: _currentUser!.role,
          );
          notifyListeners();
        }
      }
    } catch (error) {
      _setLoading(false);
      rethrow;
    }
    _setLoading(false);
  }

  Future<void> updateAddress(String address, {double? latitude, double? longitude}) async {
    _setLoading(true);
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('users').update({
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
        }).eq('id', user.id);

        if (_currentUser != null) {
          _currentUser = UserModel(
            id: _currentUser!.id,
            name: _currentUser!.name,
            email: _currentUser!.email,
            phone: _currentUser!.phone,
            address: address,
            role: _currentUser!.role,
            latitude: latitude ?? _currentUser!.latitude,
            longitude: longitude ?? _currentUser!.longitude,
          );
          notifyListeners();
        }
      }
    } catch (error) {
      _setLoading(false);
      rethrow;
    }
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
