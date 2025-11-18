import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class ReactionService {
  final SupabaseClient _supabase = supabase;

  // Adicionar reação
  Future<void> addReaction({
    required String messageId,
    required String emoji,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      await _supabase.from('message_reactions').upsert({
        'message_id': messageId,
        'user_id': userId,
        'emoji': emoji,
      });
    } catch (e) {
      print('[v0] Erro ao adicionar reação: $e');
      rethrow;
    }
  }

  // Remover reação
  Future<void> removeReaction({
    required String messageId,
    required String emoji,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      await _supabase
          .from('message_reactions')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', userId)
          .eq('emoji', emoji);
    } catch (e) {
      print('[v0] Erro ao remover reação: $e');
      rethrow;
    }
  }

  // Obter reações de uma mensagem
  Future<Map<String, List<String>>> getMessageReactions(
      String messageId) async {
    try {
      final response = await _supabase
          .from('message_reactions')
          .select('emoji, user_id, profiles:user_id(username)')
          .eq('message_id', messageId);

      // Agrupar por emoji
      final Map<String, List<String>> reactions = {};
      for (var reaction in response as List) {
        final emoji = reaction['emoji'] as String;
        final profile = reaction['profiles'] as Map<String, dynamic>;
        final username = profile['username'] as String;

        if (!reactions.containsKey(emoji)) {
          reactions[emoji] = [];
        }
        reactions[emoji]!.add(username);
      }

      return reactions;
    } catch (e) {
      print('[v0] Erro ao buscar reações: $e');
      return {};
    }
  }

  // Stream de reações em tempo real
  Stream<Map<String, List<String>>> watchMessageReactions(String messageId) {
    return _supabase
        .from('message_reactions')
        .stream(primaryKey: ['id'])
        .eq('message_id', messageId)
        .asyncMap((_) async => await getMessageReactions(messageId));
  }
}
