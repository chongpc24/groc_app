import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_service.dart';
import 'cart_service.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Session? get currentSession => _client.auth.currentSession;

  bool get isLoggedIn => currentSession != null && currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> register({
    required String fullName,
    required String email,
    required String icNumber,
    required String phoneNumber,
    required String gender,
    required String address,
    required String password,
  }) async {
    return _client.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'ic_number': normalizeIc(icNumber),
        'phone_number': normalizePhone(phoneNumber),
        'gender': gender,
        'address': address.trim(),
      },
    );
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim().toLowerCase());
  }

  Future<void> logout() async {
    final userId = currentUser?.id;
    if (userId != null) {
      await DatabaseService().clearPrivateCache(userId);
    }
    CartService().clearCart();
    await _client.auth.signOut();
  }

  static String normalizeIc(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 12) return value.trim();
    return '${digits.substring(0, 6)}-${digits.substring(6, 8)}-${digits.substring(8, 12)}';
  }

  static String normalizePhone(String value) {
    var normalized = value.replaceAll(RegExp(r'[\s-]'), '');
    if (normalized.startsWith('+60')) {
      normalized = '0${normalized.substring(3)}';
    } else if (normalized.startsWith('60') && normalized.length > 10) {
      normalized = '0${normalized.substring(2)}';
    }
    return normalized;
  }

  static String? validateFullName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Full name is required';
    if (text.length < 2) return 'Enter your full name';
    return null;
  }

  static String? validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email is required';
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(text)) return 'Enter a valid email address';
    return null;
  }

  static String? validateIc(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'IC number is required';
    if (digits.length != 12) return 'IC must contain 12 digits';
    return null;
  }

  static String? validatePhone(String? value) {
    final normalized = normalizePhone(value ?? '');
    if (normalized.isEmpty) return 'Phone number is required';
    if (!RegExp(r'^01\d{8,9}$').hasMatch(normalized)) {
      return 'Enter a valid Malaysian mobile number';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    final text = value ?? '';
    if (text.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(text)) return 'Add at least one uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(text)) return 'Add at least one lowercase letter';
    if (!RegExp(r'\d').hasMatch(text)) return 'Add at least one number';
    return null;
  }
}
