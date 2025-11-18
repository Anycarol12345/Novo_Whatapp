class Profile {
  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final String? phone;
  final String status;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool showOnlineStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.phone,
    this.status = 'Hey there! I am using WhatsApp Clone',
    this.isOnline = false,
    this.lastSeen,
    this.showOnlineStatus = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      phone: json['phone'] as String?,
      status:
          json['status'] as String? ?? 'Hey there! I am using WhatsApp Clone',
      isOnline: json['is_online'] as bool? ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'] as String)
          : null,
      showOnlineStatus: json['show_online_status'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'phone': phone,
      'status': status,
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
      'show_online_status': showOnlineStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Profile copyWith({
    String? username,
    String? fullName,
    String? avatarUrl,
    String? bio,
    String? phone,
    String? status,
    bool? isOnline,
    DateTime? lastSeen,
    bool? showOnlineStatus,
  }) {
    return Profile(
      id: id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
