class ChatMessage {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String message;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final CODPoint? codPoint; // For COD point messages

  ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    required this.message,
    this.type = MessageType.text,
    required this.timestamp,
    this.isRead = false,
    this.codPoint,
  });

  ChatMessage copyWith({
    String? id,
    String? chatRoomId,
    String? senderId,
    String? senderName,
    String? message,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    CODPoint? codPoint,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      codPoint: codPoint ?? this.codPoint,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'codPoint': codPoint?.toMap(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      chatRoomId: map['chatRoomId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      message: map['message'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.parse(map['timestamp']),
      isRead: map['isRead'] ?? false,
      codPoint: map['codPoint'] != null ? CODPoint.fromMap(map['codPoint']) : null,
    );
  }
}

enum MessageType {
  text,
  codPoint,
  image,
  system,
}

class ChatRoom {
  final String id;
  final String bookId;
  final String bookTitle;
  final String bookOwnerId;
  final String bookOwnerName;
  final String requesterId;
  final String requesterName;
  final List<String> participants;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CODPoint? agreedCODPoint; // Agreed meeting point

  ChatRoom({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.bookOwnerId,
    required this.bookOwnerName,
    required this.requesterId,
    required this.requesterName,
    required this.participants,
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.agreedCODPoint,
  });

  ChatRoom copyWith({
    String? id,
    String? bookId,
    String? bookTitle,
    String? bookOwnerId,
    String? bookOwnerName,
    String? requesterId,
    String? requesterName,
    List<String>? participants,
    ChatMessage? lastMessage,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    CODPoint? agreedCODPoint,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      bookOwnerId: bookOwnerId ?? this.bookOwnerId,
      bookOwnerName: bookOwnerName ?? this.bookOwnerName,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      agreedCODPoint: agreedCODPoint ?? this.agreedCODPoint,
    );
  }

  String getOtherParticipantName(String currentUserId) {
    return currentUserId == bookOwnerId ? requesterName : bookOwnerName;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'bookOwnerId': bookOwnerId,
      'bookOwnerName': bookOwnerName,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'participants': participants,
      'lastMessage': lastMessage?.toMap(),
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'agreedCODPoint': agreedCODPoint?.toMap(),
    };
  }

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'] ?? '',
      bookId: map['bookId'] ?? '',
      bookTitle: map['bookTitle'] ?? '',
      bookOwnerId: map['bookOwnerId'] ?? '',
      bookOwnerName: map['bookOwnerName'] ?? '',
      requesterId: map['requesterId'] ?? '',
      requesterName: map['requesterName'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] != null
          ? ChatMessage.fromMap(map['lastMessage'])
          : null,
      unreadCount: map['unreadCount'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      agreedCODPoint: map['agreedCODPoint'] != null
          ? CODPoint.fromMap(map['agreedCODPoint'])
          : null,
    );
  }
}

class CODPoint {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? note;
  final DateTime? meetingTime;
  final CODStatus status;

  CODPoint({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.note,
    this.meetingTime,
    this.status = CODStatus.proposed,
  });

  CODPoint copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? note,
    DateTime? meetingTime,
    CODStatus? status,
  }) {
    return CODPoint(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      note: note ?? this.note,
      meetingTime: meetingTime ?? this.meetingTime,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'note': note,
      'meetingTime': meetingTime?.toIso8601String(),
      'status': status.name,
    };
  }

  factory CODPoint.fromMap(Map<String, dynamic> map) {
    return CODPoint(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      note: map['note'],
      meetingTime: map['meetingTime'] != null
          ? DateTime.parse(map['meetingTime'])
          : null,
      status: CODStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CODStatus.proposed,
      ),
    );
  }
}

enum CODStatus {
  proposed,   // Diusulkan
  accepted,   // Diterima
  rejected,   // Ditolak
  completed,  // Selesai
}
