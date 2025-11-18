import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

// group_service.dart - Versão corrigida
class GroupService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> createGroup({
    required String name,
    required String description,
    required bool isPublic,
    required List<String> initialMemberIds,
  }) async {
    try {
      final response =
          await _supabase.rpc('create_group_with_participants', params: {
        'group_name': name,
        'group_description': description,
        'is_public': isPublic,
        'initial_member_ids': initialMemberIds,
      });

      return response as String;
    } catch (e) {
      print('Erro ao criar grupo via RPC: $e');
      rethrow;
    }
  }
}
