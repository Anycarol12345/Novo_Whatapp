import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/profile.dart';

class AuthService {
  final SupabaseClient _supabase = supabase;

  // Obter usuário atual
  User? get currentUser => _supabase.auth.currentUser;

  // Stream de mudanças de autenticação
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Verificar se está autenticado
  bool get isAuthenticated => currentUser != null;

  // Cadastrar novo usuário
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    String? fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'full_name': fullName ?? '',
        },
      );

      if (response.user != null) {
        // O perfil é criado automaticamente pelo trigger no banco
        print('[v0] Usuário cadastrado com sucesso: ${response.user!.id}');
      }

      return response;
    } catch (e) {
      print('[v0] Erro ao cadastrar usuário: $e');
      rethrow;
    }
  }

  // Login
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Atualizar status online
        await updateOnlineStatus(true);
      }

      return response;
    } catch (e) {
      print('[v0] Erro ao fazer login: $e');
      rethrow;
    }
  }

  // Logout
  Future<void> signOut() async {
    try {
      // Atualizar status antes de sair
      await updateOnlineStatus(false);
      await _supabase.auth.signOut();
    } catch (e) {
      print('[v0] Erro ao fazer logout: $e');
      rethrow;
    }
  }

  // Obter perfil do usuário atual
  Future<Profile?> getCurrentProfile() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return null;

      final response =
          await _supabase.from('profiles').select().eq('id', userId).single();

      return Profile.fromJson(response);
    } catch (e) {
      print('[v0] Erro ao buscar perfil: $e');
      return null;
    }
  }

  // Atualizar perfil
  Future<void> updateProfile({
    String? username,
    String? fullName,
    String? avatarUrl,
    String? bio,
    String? phone,
    String? status,
    bool? showOnlineStatus,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (fullName != null) updates['full_name'] = fullName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (bio != null) updates['bio'] = bio;
      if (phone != null) updates['phone'] = phone;
      if (status != null) updates['status'] = status;
      if (showOnlineStatus != null)
        updates['show_online_status'] = showOnlineStatus;

      await _supabase.from('profiles').update(updates).eq('id', userId);
    } catch (e) {
      print('[v0] Erro ao atualizar perfil: $e');
      rethrow;
    }
  }

  // Atualizar status online
  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return;

      await _supabase.from('profiles').update({
        'is_online': isOnline,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      print('[v0] Erro ao atualizar status online: $e');
    }
  }

  // Redefinir senha
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      print('[v0] Erro ao redefinir senha: $e');
      rethrow;
    }
  }

  // Atualizar senha
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      print('[v0] Erro ao atualizar senha: $e');
      rethrow;
    }
  }
}
