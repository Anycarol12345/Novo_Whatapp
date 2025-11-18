class Conversation {
  final String id;
  final String? name;
  final bool isGroup;
  final bool isPublic;
  final String? description;
  final String? avatarUrl;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastMessageAt;

  // Campos adicionais (não no banco, calculados)
  final String? lastMessage;
  final int unreadCount;
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserAvatar;
  final bool? isOnline;

  Conversation({
    required this.id,
    this.name,
    required this.isGroup,
    this.isPublic = false,
    this.description,
    this.avatarUrl,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessageAt,
    this.lastMessage,
    this.unreadCount = 0,
    this.otherUserId,
    this.otherUserName,
    this.otherUserAvatar,
    this.isOnline,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String? ?? json['conversation_id'] as String,
      name: json['name'] as String? ?? json['conversation_name'] as String?,
      isGroup: json['is_group'] as bool? ?? false,
      isPublic: json['is_public'] as bool? ?? false,
      description: json['description'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : DateTime.now(),
      lastMessage: json['last_message'] as String?,
      unreadCount: json['unread_count'] as int? ?? 0,
      otherUserId: json['other_user_id'] as String?,
      otherUserName: json['other_user_name'] as String?,
      otherUserAvatar: json['other_user_avatar'] as String?,
      isOnline: json['is_online'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_group': isGroup,
      'is_public': isPublic,
      'description': description,
      'avatar_url': avatarUrl,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_message_at': lastMessageAt.toIso8601String(),
    };
  }

  String getDisplayName() {
    if (isGroup) {
      return name ?? 'Grupo sem nome';
    }
    return otherUserName ?? 'Usuário';
  }

  String? getDisplayAvatar() {
    if (isGroup) {
      return avatarUrl;
    }
    return otherUserAvatar;
  }
}
