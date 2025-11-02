class AudioMessage {
  final String id;
  final String matchId;
  final String senderId;
  final String audioUrl;
  final int duration; // Duration in seconds
  final int fileSize; // File size in bytes
  final DateTime createdAt;
  final bool isRead;
  final String? localFilePath; // For local playback
  final bool deletedForEveryone;
  final List<String> deletedBy;
  final DateTime? deletedAt;

  AudioMessage({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.audioUrl,
    required this.duration,
    required this.fileSize,
    required this.createdAt,
    this.isRead = false,
    this.localFilePath,
    bool? deletedForEveryone,
    List<String>? deletedBy,
    this.deletedAt,
  })  : deletedForEveryone = deletedForEveryone ?? false,
        deletedBy = List.unmodifiable(deletedBy ?? const []);

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'match_id': matchId,
      'sender_id': senderId,
      'audio_url': audioUrl,
      'duration': duration,
      'file_size': fileSize,
      // Persist UTC so Postgres timestamptz stores the correct instant
      'created_at': createdAt.toUtc().toIso8601String(),
      'is_read': isRead,
      'deleted_for_everyone': deletedForEveryone,
      'deleted_by': deletedBy,
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
    };
  }

  bool get isDeletedForEveryone => deletedForEveryone;

  // Create from Map (database response)
  factory AudioMessage.fromMap(Map<String, dynamic> map) {
    // Parse the UTC timestamp from Supabase and convert to local time
    final utcTimestamp = DateTime.parse(map['created_at'] ?? DateTime.now().toUtc().toIso8601String());
    final localTimestamp = utcTimestamp.toLocal(); // Convert UTC to local timezone
    
    final deletedByRaw = map['deleted_by'];
    final deletedByList = deletedByRaw is List
        ? deletedByRaw.map((e) => e.toString()).toList()
        : <String>[];

    return AudioMessage(
      id: map['id'] ?? '',
      matchId: map['match_id'] ?? '',
      senderId: map['sender_id'] ?? '',
      audioUrl: map['audio_url'] ?? '',
      duration: map['duration'] ?? 0,
      fileSize: map['file_size'] ?? 0,
      createdAt: localTimestamp, // Now in local timezone
      isRead: map['is_read'] ?? false,
      deletedForEveryone: (map['deleted_for_everyone'] ?? false) as bool,
      deletedBy: deletedByList,
      deletedAt: map['deleted_at'] != null
          ? DateTime.tryParse(map['deleted_at'].toString())?.toLocal()
          : null,
    );
  }

  // Create a copy with updated fields
  AudioMessage copyWith({
    String? id,
    String? matchId,
    String? senderId,
    String? audioUrl,
    int? duration,
    int? fileSize,
    DateTime? createdAt,
    bool? isRead,
    String? localFilePath,
    bool? deletedForEveryone,
    List<String>? deletedBy,
    DateTime? deletedAt,
  }) {
    return AudioMessage(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      senderId: senderId ?? this.senderId,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      localFilePath: localFilePath ?? this.localFilePath,
      deletedForEveryone: deletedForEveryone ?? this.deletedForEveryone,
      deletedBy: deletedBy ?? List<String>.from(this.deletedBy),
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  // Format duration to MM:SS
  String get formattedDuration {
    final minutes = (duration / 60).floor();
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Format file size to human readable
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '${fileSize}B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  @override
  String toString() {
    return 'AudioMessage(id: $id, matchId: $matchId, senderId: $senderId, duration: ${formattedDuration}, fileSize: $formattedFileSize)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AudioMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
