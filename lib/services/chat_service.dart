import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/conversation.dart';
import '../models/message.dart';

class ChatService {
  final SupabaseClient _supabase = supabase;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  // Obter todas as conversas do usuário
  Future<List<Conversation>> getUserConversations() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      final response = await _supabase.rpc(
        'get_user_conversations',
        params: {'user_uuid': userId},
      );

      return (response as List)
          .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('[v0] Erro ao buscar conversas: $e');
      rethrow;
    }
  }

  // Stream de conversas em tempo real
  Stream<List<Conversation>> watchUserConversations() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('conversation_participants')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .asyncMap((_) async => await getUserConversations());
  }

  // Criar ou obter conversa individual
  Future<String> getOrCreateDirectConversation(String otherUserId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      final conversationId = await _supabase.rpc(
        'get_or_create_direct_conversation',
        params: {
          'user1_id': userId,
          'user2_id': otherUserId,
        },
      );

      return conversationId as String;
    } catch (e) {
      print('[v0] Erro ao criar/buscar conversa: $e');
      rethrow;
    }
  }

  // Obter mensagens de uma conversa (com paginação)
  Future<List<Message>> getMessages({
    required String conversationId,
    int limit = 50,
    String? beforeMessageId,
  }) async {
    try {
      var query = _supabase.from('messages').select('''
            *,
            profiles:sender_id (
              username,
              full_name,
              avatar_url
            )
          ''').eq('conversation_id', conversationId);

      // Aplicar filtro de paginação ANTES do order
      if (beforeMessageId != null) {
        // Buscar mensagem de referência para paginação
        final beforeMessage = await _supabase
            .from('messages')
            .select('created_at')
            .eq('id', beforeMessageId)
            .single();

        final timestamp = beforeMessage['created_at'] as String;
        query = query.lt('created_at', timestamp);
      }

      // Order e limit vêm por último
      final response =
          await query.order('created_at', ascending: false).limit(limit);

      return (response as List).map((json) {
        final messageJson = json as Map<String, dynamic>;
        final profile = messageJson['profiles'] as Map<String, dynamic>?;

        return Message.fromJson({
          ...messageJson,
          'sender_name': profile?['full_name'] ?? profile?['username'],
          'sender_avatar': profile?['avatar_url'],
        });
      }).toList();
    } catch (e) {
      print('[v0] Erro ao buscar mensagens: $e');
      rethrow;
    }
  }

  // Stream de mensagens em tempo real
  Stream<List<Message>> watchMessages(String conversationId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .asyncMap(
            (_) async => await getMessages(conversationId: conversationId));
  }

  // Enviar mensagem de texto
  Future<Message> sendTextMessage({
    required String conversationId,
    required String content,
    String? replyToId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      final response = await _supabase
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': userId,
            'content': content,
            'message_type': 'text',
            'reply_to_id': replyToId,
          })
          .select()
          .single();

      return Message.fromJson(response);
    } catch (e) {
      print('[v0] Erro ao enviar mensagem: $e');
      rethrow;
    }
  }

  // Enviar mensagem com mídia
  Future<Message> sendMediaMessage({
    required String conversationId,
    required String mediaUrl,
    required String messageType,
    String? mediaName,
    int? mediaSize,
    String? caption,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      final response = await _supabase
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': userId,
            'content': caption,
            'message_type': messageType,
            'media_url': mediaUrl,
            'media_name': mediaName,
            'media_size': mediaSize,
          })
          .select()
          .single();

      return Message.fromJson(response);
    } catch (e) {
      print('[v0] Erro ao enviar mensagem de mídia: $e');
      rethrow;
    }
  }

  // Editar mensagem
  Future<void> editMessage(String messageId, String newContent) async {
    try {
      await _supabase.from('messages').update({
        'content': newContent,
      }).eq('id', messageId);
    } catch (e) {
      print('[v0] Erro ao editar mensagem: $e');
      rethrow;
    }
  }

  // Deletar mensagem
  Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase.from('messages').update({
        'is_deleted': true,
        'content': null,
        'media_url': null,
      }).eq('id', messageId);
    } catch (e) {
      print('[v0] Erro ao deletar mensagem: $e');
    }
  }

  // Marcar mensagens como lidas
  Future<void> markAsRead(String conversationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('conversation_participants')
          .update({'last_read_at': DateTime.now().toIso8601String()})
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    } catch (e) {
      print('[v0] Erro ao marcar como lido: $e');
    }
  }

  // Buscar usuários
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      print('[v0] Buscando usuários com query: $query');

      final response = await _supabase
          .from('profiles')
          .select('id, username, full_name, avatar_url, status, is_online')
          .or('username.ilike.%$query%,full_name.ilike.%$query%')
          .limit(20);

      print('[v0] Resultados da busca: ${(response as List).length}');

      // Filtrar o usuário atual do resultado
      return (response as List)
          .cast<Map<String, dynamic>>()
          .where((profile) => profile['id'] != userId)
          .toList();
    } catch (e) {
      print('[v0] Erro ao buscar usuários: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      print('[v0] Buscando todos os usuários...');

      final response = await _supabase
          .from('profiles')
          .select('id, username, full_name, avatar_url, status, is_online')
          .order('username')
          .limit(100);

      print('[v0] Total de perfis encontrados: ${(response as List).length}');

      // Filtrar o usuário atual do resultado
      final filtered = (response as List)
          .cast<Map<String, dynamic>>()
          .where((profile) => profile['id'] != userId)
          .toList();

      print('[v0] Usuários após filtrar atual: ${filtered.length}');

      return filtered;
    } catch (e) {
      print('[v0] Erro ao buscar todos os usuários: $e');
      rethrow;
    }
  }
}
