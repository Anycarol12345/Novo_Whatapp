import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../models/profile.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  Profile? _currentProfile;
  bool _isLoading = false;
  String? _errorMessage;

  Profile? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _authService.isAuthenticated;
  User? get currentUser => _authService.currentUser;

  AuthProvider() {
    _init();
  }

  void _init() {
    // Escutar mudanças de autenticação
    _authService.authStateChanges.listen((AuthState state) {
      if (state.event == AuthChangeEvent.signedIn) {
        _loadCurrentProfile();
      } else if (state.event == AuthChangeEvent.signedOut) {
        _currentProfile = null;
        notifyListeners();
      }
    });

    // Carregar perfil se já estiver autenticado
    if (isAuthenticated) {
      _loadCurrentProfile();
    }
  }

  Future<void> _loadCurrentProfile() async {
    try {
      _currentProfile = await _authService.getCurrentProfile();
      notifyListeners();
    } catch (e) {
      print('[v0] Erro ao carregar perfil: $e');
    }
  }

  // Cadastrar
  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
    String? fullName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
        username: username,
        fullName: fullName,
      );

      if (response.user != null) {
        await _loadCurrentProfile();
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadCurrentProfile();
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _currentProfile = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Atualizar perfil
  Future<bool> updateProfile({
    String? username,
    String? fullName,
    String? avatarUrl,
    String? bio,
    String? phone,
    String? status,
    bool? showOnlineStatus,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.updateProfile(
        username: username,
        fullName: fullName,
        avatarUrl: avatarUrl,
        bio: bio,
        phone: phone,
        status: status,
        showOnlineStatus: showOnlineStatus,
      );

      await _loadCurrentProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Redefinir senha
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
