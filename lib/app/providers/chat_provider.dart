import 'package:flutter/material.dart';
import '../data/models/chat_model.dart';

class ChatProvider extends ChangeNotifier {
  // Current user info (simulasi - nanti diganti Firebase Auth)
  String _currentUserId = 'current_user';
  String _currentUserName = 'Anda';

  String get currentUserId => _currentUserId;
  String get currentUserName => _currentUserName;

  List<ChatRoom> _chatRooms = [];
  Map<String, List<ChatMessage>> _messages = {};
  bool _isLoading = false;

  List<ChatRoom> get chatRooms => _chatRooms;
  bool get isLoading => _isLoading;

  // Get messages for a specific chat room
  List<ChatMessage> getMessages(String chatRoomId) {
    return _messages[chatRoomId] ?? [];
  }

  // Get chat room by ID
  ChatRoom? getChatRoom(String chatRoomId) {
    try {
      return _chatRooms.firstWhere((room) => room.id == chatRoomId);
    } catch (e) {
      return null;
    }
  }

  // Get or create chat room for a book
  ChatRoom getOrCreateChatRoom({
    required String bookId,
    required String bookTitle,
    required String bookOwnerId,
    required String bookOwnerName,
  }) {
    // Check if chat room already exists
    try {
      return _chatRooms.firstWhere(
        (room) => room.bookId == bookId && room.requesterId == _currentUserId,
      );
    } catch (e) {
      // Create new chat room
      final newRoom = ChatRoom(
        id: 'room_${DateTime.now().millisecondsSinceEpoch}',
        bookId: bookId,
        bookTitle: bookTitle,
        bookOwnerId: bookOwnerId,
        bookOwnerName: bookOwnerName,
        requesterId: _currentUserId,
        requesterName: _currentUserName,
        participants: [bookOwnerId, _currentUserId],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _chatRooms.insert(0, newRoom);
      _messages[newRoom.id] = [];
      
      // Add system message
      _addSystemMessage(newRoom.id, 'Chat dimulai untuk buku "$bookTitle"');
      
      notifyListeners();
      return newRoom;
    }
  }

  // Send text message
  void sendMessage(String chatRoomId, String text) {
    if (text.trim().isEmpty) return;

    final message = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      chatRoomId: chatRoomId,
      senderId: _currentUserId,
      senderName: _currentUserName,
      message: text.trim(),
      type: MessageType.text,
      timestamp: DateTime.now(),
    );

    _addMessage(chatRoomId, message);
    
    // Simulate reply after 1 second
    _simulateReply(chatRoomId);
  }

  // Send COD Point message
  void sendCODPoint(String chatRoomId, CODPoint codPoint) {
    final message = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      chatRoomId: chatRoomId,
      senderId: _currentUserId,
      senderName: _currentUserName,
      message: '📍 Mengusulkan titik COD: ${codPoint.name}',
      type: MessageType.codPoint,
      timestamp: DateTime.now(),
      codPoint: codPoint,
    );

    _addMessage(chatRoomId, message);
  }

  // Accept COD Point
  void acceptCODPoint(String chatRoomId, CODPoint codPoint) {
    final updatedCOD = codPoint.copyWith(status: CODStatus.accepted);
    
    // Update chat room with agreed COD point
    final roomIndex = _chatRooms.indexWhere((r) => r.id == chatRoomId);
    if (roomIndex != -1) {
      _chatRooms[roomIndex] = _chatRooms[roomIndex].copyWith(
        agreedCODPoint: updatedCOD,
        updatedAt: DateTime.now(),
      );
    }

    _addSystemMessage(chatRoomId, '✅ Titik COD "${codPoint.name}" telah disetujui!');
    notifyListeners();
  }

  // Reject COD Point
  void rejectCODPoint(String chatRoomId, CODPoint codPoint) {
    _addSystemMessage(chatRoomId, '❌ Titik COD "${codPoint.name}" ditolak.');
    notifyListeners();
  }

  void _addMessage(String chatRoomId, ChatMessage message) {
    if (_messages[chatRoomId] == null) {
      _messages[chatRoomId] = [];
    }
    _messages[chatRoomId]!.add(message);

    // Update last message in chat room
    final roomIndex = _chatRooms.indexWhere((r) => r.id == chatRoomId);
    if (roomIndex != -1) {
      _chatRooms[roomIndex] = _chatRooms[roomIndex].copyWith(
        lastMessage: message,
        updatedAt: DateTime.now(),
      );
      
      // Move to top
      final room = _chatRooms.removeAt(roomIndex);
      _chatRooms.insert(0, room);
    }

    notifyListeners();
  }

  void _addSystemMessage(String chatRoomId, String text) {
    final message = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      chatRoomId: chatRoomId,
      senderId: 'system',
      senderName: 'System',
      message: text,
      type: MessageType.system,
      timestamp: DateTime.now(),
    );
    _addMessage(chatRoomId, message);
  }

  // Simulate reply (for demo purposes)
  void _simulateReply(String chatRoomId) {
    Future.delayed(const Duration(seconds: 2), () {
      final room = getChatRoom(chatRoomId);
      if (room == null) return;

      final replies = [
        'Halo! Buku masih tersedia kok 😊',
        'Boleh, kapan mau ketemu?',
        'Oke, bisa COD di daerah mana?',
        'Kondisi bukunya masih bagus ya',
        'Baik, nanti saya kabari lagi',
      ];
      
      final randomReply = replies[DateTime.now().second % replies.length];
      
      final replyMessage = ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        chatRoomId: chatRoomId,
        senderId: room.bookOwnerId,
        senderName: room.bookOwnerName,
        message: randomReply,
        type: MessageType.text,
        timestamp: DateTime.now(),
      );

      _addMessage(chatRoomId, replyMessage);
    });
  }

  // Mark messages as read
  void markAsRead(String chatRoomId) {
    final messages = _messages[chatRoomId];
    if (messages == null) return;

    for (int i = 0; i < messages.length; i++) {
      if (!messages[i].isRead && messages[i].senderId != _currentUserId) {
        messages[i] = messages[i].copyWith(isRead: true);
      }
    }

    final roomIndex = _chatRooms.indexWhere((r) => r.id == chatRoomId);
    if (roomIndex != -1) {
      _chatRooms[roomIndex] = _chatRooms[roomIndex].copyWith(unreadCount: 0);
    }

    notifyListeners();
  }

  // Get total unread count
  int get totalUnreadCount {
    return _chatRooms.fold(0, (sum, room) => sum + room.unreadCount);
  }

  // Delete chat room
  void deleteChatRoom(String chatRoomId) {
    _chatRooms.removeWhere((r) => r.id == chatRoomId);
    _messages.remove(chatRoomId);
    notifyListeners();
  }

  // Set current user (untuk simulasi)
  void setCurrentUser(String userId, String userName) {
    _currentUserId = userId;
    _currentUserName = userName;
    notifyListeners();
  }

  // Add dummy chat rooms for testing
  void addDummyChatRooms() {
    if (_chatRooms.isNotEmpty) return;

    final dummyRoom = ChatRoom(
      id: 'room_demo_1',
      bookId: '1',
      bookTitle: 'Laskar Pelangi',
      bookOwnerId: 'user1',
      bookOwnerName: 'Ahmad',
      requesterId: _currentUserId,
      requesterName: _currentUserName,
      participants: ['user1', _currentUserId],
      lastMessage: ChatMessage(
        id: 'msg_demo_1',
        chatRoomId: 'room_demo_1',
        senderId: 'user1',
        senderName: 'Ahmad',
        message: 'Halo! Bukunya masih tersedia ya',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      unreadCount: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    );

    _chatRooms.add(dummyRoom);
    _messages[dummyRoom.id] = [
      ChatMessage(
        id: 'msg_sys_1',
        chatRoomId: dummyRoom.id,
        senderId: 'system',
        senderName: 'System',
        message: 'Chat dimulai untuk buku "Laskar Pelangi"',
        type: MessageType.system,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ChatMessage(
        id: 'msg_1',
        chatRoomId: dummyRoom.id,
        senderId: _currentUserId,
        senderName: _currentUserName,
        message: 'Halo, apakah buku Laskar Pelangi masih tersedia?',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      ChatMessage(
        id: 'msg_2',
        chatRoomId: dummyRoom.id,
        senderId: 'user1',
        senderName: 'Ahmad',
        message: 'Halo! Bukunya masih tersedia ya',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];

    notifyListeners();
  }
}
