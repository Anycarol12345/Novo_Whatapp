import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class PresenceService {
  final SupabaseClient _supabase = supabase;

  // Atualizar status online
  Future<void> setOnlineStatus(bool isOnline) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('profiles').update({
        'is_online': isOnline,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      print('[v0] Erro ao atualizar status online: $e');
    }
  }

  // Iniciar status de digitação
  Future<void> startTyping(String conversationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('typing_status').upsert({
        'conversation_id': conversationId,
        'user_id': userId,
        'is_typing': true,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('[v0] Erro ao iniciar digitação: $e');
    }
  }

  // Parar status de digitação
  Future<void> stopTyping(String conversationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('typing_status')
          .delete()
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    } catch (e) {
      print('[v0] Erro ao parar digitação: $e');
    }
  }

  // Stream de usuários digitando
  Stream<List<Map<String, dynamic>>> watchTypingUsers(String conversationId) {
    final userId = _supabase.auth.currentUser?.id;

    return _supabase
        .from('typing_status')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .map((data) {
          return (data as List)
              .where((item) {
                // Filtrar por usuário diferente do atual
                if (item['user_id'] == userId) return false;

                // Considerar apenas últimos 5 segundos
                final updatedAt = DateTime.parse(item['updated_at'] as String);
                final diff = DateTime.now().difference(updatedAt);
                return diff.inSeconds < 5;
              })
              .toList()
              .cast<Map<String, dynamic>>();
        });
  }

  // Stream de status online de um usuário
  Stream<bool> watchUserOnlineStatus(String userId) {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) {
          if (data.isEmpty) return false;
          final profile = data.first;
          return profile['is_online'] as bool? ?? false;
        });
  }
}
