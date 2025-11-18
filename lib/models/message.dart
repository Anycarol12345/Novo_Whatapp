class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String? content;
  final MessageType messageType;
  final String? mediaUrl;
  final String? mediaName;
  final int? mediaSize;
  final String? replyToId;
  final bool isEdited;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? editedAt;

  // Campos adicionais (não no banco)
  final String? senderName;
  final String? senderAvatar;
  final Message? replyToMessage;
  final Map<String, List<String>>? reactions; // Adicionar reações

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.content,
    this.messageType = MessageType.text,
    this.mediaUrl,
    this.mediaName,
    this.mediaSize,
    this.replyToId,
    this.isEdited = false,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.editedAt,
    this.senderName,
    this.senderAvatar,
    this.replyToMessage,
    this.reactions, // Adicionar ao construtor
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String?,
      messageType: _messageTypeFromString(json['message_type'] as String?),
      mediaUrl: json['media_url'] as String?,
      mediaName: json['media_name'] as String?,
      mediaSize: json['media_size'] as int?,
      replyToId: json['reply_to_id'] as String?,
      isEdited: json['is_edited'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'] as String)
          : null,
      senderName: json['sender_name'] as String?,
      senderAvatar: json['sender_avatar'] as String?,
      reactions:
          json['reactions'] !=
              null // Parse reações
          ? Map<String, List<String>>.from(json['reactions'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType.name,
      'media_url': mediaUrl,
      'media_name': mediaName,
      'media_size': mediaSize,
      'reply_to_id': replyToId,
      'is_edited': isEdited,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'edited_at': editedAt?.toIso8601String(),
      'reactions': reactions, // Incluir reações
    };
  }

  static MessageType _messageTypeFromString(String? type) {
    switch (type) {
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'audio':
        return MessageType.audio;
      default:
        return MessageType.text;
    }
  }

  bool canEdit() {
    // Mensagens podem ser editadas por até 15 minutos
    final fifteenMinutesAgo = DateTime.now().subtract(
      const Duration(minutes: 15),
    );
    return createdAt.isAfter(fifteenMinutesAgo) && !isDeleted;
  }

  Message copyWith({Map<String, List<String>>? reactions}) {
    return Message(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      messageType: messageType,
      mediaUrl: mediaUrl,
      mediaName: mediaName,
      mediaSize: mediaSize,
      replyToId: replyToId,
      isEdited: isEdited,
      isDeleted: isDeleted,
      createdAt: createdAt,
      updatedAt: updatedAt,
      editedAt: editedAt,
      senderName: senderName,
      senderAvatar: senderAvatar,
      replyToMessage: replyToMessage,
      reactions: reactions ?? this.reactions,
    );
  }
}

enum MessageType { text, image, file, audio }
