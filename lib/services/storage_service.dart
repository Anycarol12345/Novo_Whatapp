import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class StorageService {
  final SupabaseClient _supabase = supabase;

  // Upload de avatar de usuário
  Future<String> uploadAvatar(File file, String userId) async {
    try {
      final fileExtension = file.path.split('.').last;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final filePath = '$userId/$fileName';

      // Fazer upload
      await _supabase.storage.from('avatars').upload(
            filePath,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      // Obter URL pública
      final publicUrl =
          _supabase.storage.from('avatars').getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('[v0] Erro ao fazer upload de avatar: $e');
      rethrow;
    }
  }

  // Upload de mídia de chat (imagem, arquivo)
  Future<String> uploadChatMedia({
    required File file,
    required String conversationId,
    required String userId,
  }) async {
    try {
      final fileExtension = file.path.split('.').last;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final filePath = '$conversationId/$userId/$fileName';

      // Verificar tamanho (máx 20 MB conforme requisito)
      final fileSize = await file.length();
      if (fileSize > 20 * 1024 * 1024) {
        throw Exception('Arquivo muito grande. Máximo: 20 MB');
      }

      // Fazer upload
      await _supabase.storage.from('chat-media').upload(
            filePath,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Obter URL com assinatura (privado, válido por 1 ano)
      final signedUrl = await _supabase.storage
          .from('chat-media')
          .createSignedUrl(filePath, 31536000); // 1 ano em segundos

      return signedUrl;
    } catch (e) {
      print('[v0] Erro ao fazer upload de mídia: $e');
      rethrow;
    }
  }

  // Deletar avatar antigo
  Future<void> deleteAvatar(String avatarUrl) async {
    try {
      // Extrair caminho do arquivo da URL
      final uri = Uri.parse(avatarUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf('avatars');

      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
        await _supabase.storage.from('avatars').remove([filePath]);
      }
    } catch (e) {
      print('[v0] Erro ao deletar avatar: $e');
    }
  }

  // Deletar mídia de chat
  Future<void> deleteChatMedia(String mediaUrl) async {
    try {
      final uri = Uri.parse(mediaUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf('chat-media');

      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
        await _supabase.storage.from('chat-media').remove([filePath]);
      }
    } catch (e) {
      print('[v0] Erro ao deletar mídia: $e');
    }
  }
}
