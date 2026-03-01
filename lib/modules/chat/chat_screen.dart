import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/providers/chat_provider.dart';
import '../../app/data/models/chat_model.dart';
import 'cod_point_picker.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;

  const ChatScreen({super.key, required this.chatRoomId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.markAsRead(widget.chatRoomId);
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage(ChatProvider chatProvider) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    chatProvider.sendMessage(widget.chatRoomId, text);
    _messageController.clear();
    
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _openCODPointPicker() async {
    final result = await Navigator.push<CODPoint>(
      context,
      MaterialPageRoute(
        builder: (context) => CODPointPicker(chatRoomId: widget.chatRoomId),
      ),
    );

    if (result != null && mounted) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.sendCODPoint(widget.chatRoomId, result);
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final room = chatProvider.getChatRoom(widget.chatRoomId);
        if (room == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chat')),
            body: const Center(child: Text('Chat tidak ditemukan')),
          );
        }

        final messages = chatProvider.getMessages(widget.chatRoomId);
        final otherName = room.getOtherParticipantName(chatProvider.currentUserId);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 1,
            titleSpacing: 0,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    otherName[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '📚 ${room.bookTitle}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (room.agreedCODPoint != null)
                IconButton(
                  icon: const Icon(Icons.location_on, color: Colors.green),
                  onPressed: () => _showCODPointInfo(room.agreedCODPoint!),
                  tooltip: 'Lihat titik COD',
                ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'cod') {
                    _openCODPointPicker();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'cod',
                    child: Row(
                      children: [
                        Icon(Icons.add_location_alt, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Tentukan Titik COD'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // COD Point Banner (if agreed)
              if (room.agreedCODPoint != null)
                _buildCODPointBanner(room.agreedCODPoint!),

              // Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildMessageBubble(message, chatProvider);
                  },
                ),
              ),

              // Input
              _buildInputArea(chatProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCODPointBanner(CODPoint codPoint) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.green[50],
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Titik COD Disepakati',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '📍 ${codPoint.name}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                if (codPoint.meetingTime != null)
                  Text(
                    '🕐 ${_formatDateTime(codPoint.meetingTime!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showCODPointInfo(codPoint),
            child: const Text('Lihat'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ChatProvider chatProvider) {
    final isMe = message.senderId == chatProvider.currentUserId;
    final isSystem = message.type == MessageType.system;
    final isCODPoint = message.type == MessageType.codPoint;

    if (isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.message,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    if (isCODPoint && message.codPoint != null) {
      return _buildCODPointMessage(message, isMe, chatProvider);
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(
                  message.senderName,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Text(
                message.message,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Text(
                _formatTime(message.timestamp),
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCODPointMessage(ChatMessage message, bool isMe, ChatProvider chatProvider) {
    final codPoint = message.codPoint!;
    final isAccepted = codPoint.status == CODStatus.accepted;
    final isRejected = codPoint.status == CODStatus.rejected;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: isAccepted ? Colors.green : Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isMe ? 'Anda mengusulkan titik COD' : '${message.senderName} mengusulkan titik COD',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Text(
                  codPoint.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  codPoint.address,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (codPoint.meetingTime != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '🕐 ${_formatDateTime(codPoint.meetingTime!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
                if (codPoint.note != null && codPoint.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '📝 ${codPoint.note}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
                const SizedBox(height: 12),
                if (!isMe && !isAccepted && !isRejected)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => chatProvider.rejectCODPoint(widget.chatRoomId, codPoint),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('Tolak'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => chatProvider.acceptCODPoint(widget.chatRoomId, codPoint),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('Setuju'),
                      ),
                    ],
                  )
                else if (isAccepted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text('Disetujui', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                  )
                else if (isRejected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cancel, color: Colors.red, size: 16),
                        SizedBox(width: 4),
                        Text('Ditolak', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(ChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_location_alt, color: Colors.blue),
              onPressed: _openCODPointPicker,
              tooltip: 'Tentukan Titik COD',
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Ketik pesan...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(chatProvider),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: () => _sendMessage(chatProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCODPointInfo(CODPoint codPoint) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Titik COD',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              codPoint.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(child: Text(codPoint.address)),
              ],
            ),
            if (codPoint.meetingTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(_formatDateTime(codPoint.meetingTime!)),
                ],
              ),
            ],
            if (codPoint.note != null && codPoint.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(codPoint.note!)),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Open in maps app
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Buka di Google Maps akan datang!')),
                  );
                },
                icon: const Icon(Icons.map),
                label: const Text('Buka di Maps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}, ${_formatTime(dateTime)}';
  }
}
