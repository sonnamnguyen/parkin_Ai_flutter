import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _error;
  String? _token;

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  String? get token => _token;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  // Login method
  Future<bool> login({
    required String phone,
    required String password,
  }) async {
    try {
      _setStatus(AuthStatus.loading);
      
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock successful login
      _token = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
      _user = User(
        id: 1,
        username: 'user123',
        fullName: 'Nguyễn Văn A',
        email: 'user@example.com',
        phone: phone,
        role: 'user',
        walletBalance: 500000.0,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      );
      
      _setStatus(AuthStatus.authenticated);
      
      // TODO: Save token to local storage
      return true;
    } catch (e) {
      _error = e.toString();
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  // Register method
  Future<bool> register({
    required String fullName,
    required String username,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      _setStatus(AuthStatus.loading);
      
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock successful registration
      // In real app, this would not set user until verification is complete
      _setStatus(AuthStatus.unauthenticated);
      
      return true;
    } catch (e) {
      _error = e.toString();
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  // Verify code method
  Future<bool> verifyCode({
    required String phone,
    required String code,
  }) async {
    try {
      _setStatus(AuthStatus.loading);
      
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock successful verification
      _token = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
      _user = User(
        id: 1,
        username: 'newuser123',
        fullName: 'Người dùng mới',
        email: 'newuser@example.com',
        phone: phone,
        role: 'user',
        walletBalance: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _setStatus(AuthStatus.authenticated);
      
      // TODO: Save token to local storage
      return true;
    } catch (e) {
      _error = e.toString();
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  // Resend verification code
  Future<bool> resendCode({required String phone}) async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    try {
      // TODO: Call logout API endpoint
      // TODO: Clear local storage
      
      _user = null;
      _token = null;
      _error = null;
      _setStatus(AuthStatus.unauthenticated);
    } catch (e) {
      _error = e.toString();
      _setStatus(AuthStatus.error);
    }
  }

  // Check authentication status on app start
  Future<void> checkAuthStatus() async {
    try {
      _setStatus(AuthStatus.loading);
      
      // TODO: Check if token exists in local storage
      // TODO: Validate token with backend
      // TODO: Load user data
      
      // For now, simulate checking stored auth
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock: assume not authenticated on first launch
      _setStatus(AuthStatus.unauthenticated);
    } catch (e) {
      _error = e.toString();
      _setStatus(AuthStatus.error);
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
  }) async {
    if (_user == null) return false;
    
    try {
      _setStatus(AuthStatus.loading);
      
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      
      _user = _user!.copyWith(
        fullName: fullName ?? _user!.fullName,
        email: email ?? _user!.email,
        phone: phone ?? _user!.phone,
        avatarUrl: avatarUrl ?? _user!.avatarUrl,
        updatedAt: DateTime.now(),
      );
      
      _setStatus(AuthStatus.authenticated);
      return true;
    } catch (e) {
      _error = e.toString();
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Private helper method
  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }
}