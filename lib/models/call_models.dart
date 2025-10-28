// import 'package:json_annotation/json_annotation.dart';

// part 'call_models.g.dart';

class CallPayload {
  String? userId;
  String? name;
  String? username;
  String? imageUrl;
  String? fcmToken;
  CallType? callType;
  CallAction? callAction;
  String? notificationId;
  String? webrtcRoomId;
  String? matchId;
  bool? isBffMatch;

  CallPayload({
    this.userId,
    this.name,
    this.username,
    this.imageUrl,
    this.fcmToken,
    this.callType,
    this.callAction,
    this.notificationId,
    this.webrtcRoomId,
    this.matchId,
    this.isBffMatch,
  });

  factory CallPayload.fromJson(Map<String, dynamic> json) => CallPayload(
    userId: json['userId'],
    name: json['name'],
    username: json['username'],
    imageUrl: json['imageUrl'],
    fcmToken: json['fcmToken'],
    callType: json['callType'] != null ? CallType.values.firstWhere(
      (e) => e.name == json['callType'],
      orElse: () => CallType.audio,
    ) : null,
    callAction: json['callAction'] != null ? CallAction.values.firstWhere(
      (e) => e.name == json['callAction'],
      orElse: () => CallAction.create,
    ) : null,
    notificationId: json['notificationId'],
    webrtcRoomId: json['webrtcRoomId'],
    matchId: json['matchId'],
    isBffMatch: json['isBffMatch'],
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'username': username,
    'imageUrl': imageUrl,
    'fcmToken': fcmToken,
    'callType': callType?.name,
    'callAction': callAction?.name,
    'notificationId': notificationId,
    'webrtcRoomId': webrtcRoomId,
    'matchId': matchId,
    'isBffMatch': isBffMatch,
    'callId': notificationId, // Add callId for CallKit extra data
  };
}

enum CallType { audio, video }

enum CallAction { create, join, end }

enum CallState { 
  initial, 
  connecting, 
  connected, 
  disconnected, 
  failed 
}

class CallSession {
  final String id;
  final String matchId;
  final String callerId;
  final String receiverId;
  final CallType type;
  final CallState state;
  final DateTime createdAt;
  final DateTime? endedAt;
  final bool isBffMatch;
  final String startedAt;
  final CallType callType;

  CallSession({
    required this.id,
    required this.matchId,
    required this.callerId,
    required this.receiverId,
    required this.type,
    required this.state,
    required this.createdAt,
    this.endedAt,
    this.isBffMatch = false,
    required this.startedAt,
    required this.callType,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'match_id': matchId,
    'caller_id': callerId,
    'receiver_id': receiverId,
    'type': type.name,
    'state': state.name,
    'created_at': createdAt.toIso8601String(),
    'ended_at': endedAt?.toIso8601String(),
    'is_bff_match': isBffMatch,
    'started_at': startedAt,
    'call_type': callType.name,
  };

  factory CallSession.fromJson(Map<String, dynamic> json) => CallSession(
    id: json['id'] ?? '',
    matchId: json['match_id'] ?? '',
    callerId: json['caller_id'] ?? '',
    receiverId: json['receiver_id'] ?? '',
    type: CallType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => CallType.audio,
    ),
    state: CallState.values.firstWhere(
      (e) => e.name == json['state'],
      orElse: () => CallState.initial,
    ),
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
    isBffMatch: json['is_bff_match'] ?? false,
    startedAt: json['started_at'] ?? DateTime.now().toIso8601String(),
    callType: CallType.values.firstWhere(
      (e) => e.name == json['call_type'],
      orElse: () => CallType.audio,
    ),
  );
}
