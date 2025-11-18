class AppConstants {
  // Limites de arquivo
  static const int maxFileSize = 20 * 1024 * 1024; // 20 MB
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1920;
  static const int imageQuality = 85;

  // Tempo de edição de mensagens
  static const int messageEditTimeMinutes = 15;

  // Paginação
  static const int messagesPerPage = 50;
  static const int conversationsPerPage = 30;

  // Typing indicator
  static const Duration typingTimeout = Duration(seconds: 3);

  // Retenção de mensagens
  static const int messageRetentionMonths = 12;

  // Storage buckets
  static const String avatarsBucket = 'avatars';
  static const String groupAvatarsBucket = 'group_avatars';
  static const String messageMediaBucket = 'message_media';

  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration realtimeTimeout = Duration(seconds: 2);

  // Allowed file types
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/gif',
    'image/webp',
  ];

  static const List<String> allowedFileTypes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'text/plain',
  ];

  // Reações disponíveis
  static const List<String> availableReactions = [
    '❤️',
    '👍',
    '😂',
    '😮',
    '😢',
    '🙏',
  ];
}
