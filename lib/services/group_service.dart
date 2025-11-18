import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class GroupService {
  final SupabaseClient _supabase = supabase;

  // Criar grupo
  Future<String> createGroup({
    required String name,
    String? description,
    String? avatarUrl,
    bool isPublic = false,
    List<String>? initialMemberIds,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      // Criar conversa de grupo
      final conversationResponse = await _supabase
          .from('conversations')
          .insert({
            'name': name,
            'description': description,
            'avatar_url': avatarUrl,
            'is_group': true,
            'is_public': isPublic,
            'created_by': userId,
          })
          .select()
          .single();

      final conversationId = conversationResponse['id'] as String;

      // Adicionar criador como admin
      await _supabase.from('conversation_participants').insert({
        'conversation_id': conversationId,
        'user_id': userId,
        'role': 'admin',
      });

      // Adicionar membros iniciais
      if (initialMemberIds != null && initialMemberIds.isNotEmpty) {
        final participants = initialMemberIds
            .map((memberId) => {
                  'conversation_id': conversationId,
                  'user_id': memberId,
                  'role': 'member',
                })
            .toList();

        await _supabase.from('conversation_participants').insert(participants);
      }

      return conversationId;
    } catch (e) {
      print('[v0] Erro ao criar grupo: $e');
      rethrow;
    }
  }

  // Adicionar membro ao grupo
  Future<void> addMember({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await _supabase.from('conversation_participants').insert({
        'conversation_id': conversationId,
        'user_id': userId,
        'role': 'member',
      });
    } catch (e) {
      print('[v0] Erro ao adicionar membro: $e');
      rethrow;
    }
  }

  // Remover membro do grupo
  Future<void> removeMember({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await _supabase
          .from('conversation_participants')
          .delete()
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    } catch (e) {
      print('[v0] Erro ao remover membro: $e');
      rethrow;
    }
  }

  // Promover membro a admin
  Future<void> promoteToAdmin({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await _supabase
          .from('conversation_participants')
          .update({'role': 'admin'})
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    } catch (e) {
      print('[v0] Erro ao promover membro: $e');
      rethrow;
    }
  }

  // Obter membros do grupo
  Future<List<Map<String, dynamic>>> getGroupMembers(
      String conversationId) async {
    try {
      final response =
          await _supabase.from('conversation_participants').select('''
            *,
            profiles:user_id (
              id,
              username,
              full_name,
              avatar_url,
              is_online
            )
          ''').eq('conversation_id', conversationId);

      return (response as List).map((json) {
        final participant = json as Map<String, dynamic>;
        final profile = participant['profiles'] as Map<String, dynamic>;
        return {
          ...profile,
          'role': participant['role'],
          'joined_at': participant['joined_at'],
        };
      }).toList();
    } catch (e) {
      print('[v0] Erro ao buscar membros: $e');
      rethrow;
    }
  }

  // Atualizar informações do grupo
  Future<void> updateGroup({
    required String conversationId,
    String? name,
    String? description,
    String? avatarUrl,
    bool? isPublic,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (isPublic != null) updates['is_public'] = isPublic;

      if (updates.isNotEmpty) {
        await _supabase
            .from('conversations')
            .update(updates)
            .eq('id', conversationId);
      }
    } catch (e) {
      print('[v0] Erro ao atualizar grupo: $e');
      rethrow;
    }
  }

  // Buscar grupos públicos
  Future<List<Map<String, dynamic>>> searchPublicGroups(String query) async {
    try {
      final response = await _supabase
          .from('conversations')
          .select('id, name, description, avatar_url, created_at')
          .eq('is_group', true)
          .eq('is_public', true)
          .ilike('name', '%$query%')
          .limit(20);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('[v0] Erro ao buscar grupos: $e');
      rethrow;
    }
  }

  // Sair do grupo
  Future<void> leaveGroup(String conversationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      await _supabase
          .from('conversation_participants')
          .delete()
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    } catch (e) {
      print('[v0] Erro ao sair do grupo: $e');
      rethrow;
    }
  }
}
