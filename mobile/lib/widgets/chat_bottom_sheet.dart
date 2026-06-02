import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../services/locale_service.dart';

class ChatBottomSheet extends StatefulWidget {
  final String projectId;
  final String projectName;

  const ChatBottomSheet({
    Key? key,
    required this.projectId,
    required this.projectName,
  }) : super(key: key);

  @override
  _ChatBottomSheetState createState() => _ChatBottomSheetState();
}

class _ChatBottomSheetState extends State<ChatBottomSheet> {
  IO.Socket? socket;
  List<dynamic> messages = [];
  bool isLoading = true;
  String currentUserId = '';
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    try {
      final userData = await AuthService.getUserInfo();
      if (userData != null) {
        currentUserId = userData['_id'];
      }
      
      await _fetchMessages();
      _connectSocket();
    } catch (e) {
      print('Error initializing chat: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchMessages() async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('https://prm-tan.vercel.app/api/projects/${widget.projectId}/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          messages = jsonDecode(response.body);
          isLoading = false;
        });
        _scrollToBottom();
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching messages: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _connectSocket() {
    // Connect to the backend socket
    socket = IO.io('https://prm-tan.vercel.app', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket!.connect();

    socket!.onConnect((_) {
      print('Connected to socket server');
      socket!.emit('joinProject', widget.projectId);
    });

    socket!.on('receiveMessage', (data) {
      if (mounted) {
        setState(() {
          messages.add(data);
        });
        _scrollToBottom();
      }
    });

    socket!.onDisconnect((_) => print('Disconnected from socket server'));
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || socket == null) return;

    socket!.emit('sendMessage', {
      'projectId': widget.projectId,
      'senderId': currentUserId,
      'text': text,
    });

    _messageController.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    socket?.disconnect();
    socket?.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    const themeColor = Color(0xFF06B6D4);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: dialogBg.withOpacity(0.95),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(36),
            topRight: Radius.circular(36),
          ),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: themeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.chat_bubble_outline_rounded, color: themeColor, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.projectName,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                              ),
                              Text(
                                LocaleService.tr('Nhắn tin nhóm', en: 'Team Chat'),
                                style: TextStyle(fontSize: 13, color: subTextColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: subTextColor),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Messages List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: themeColor))
                  : messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.forum_outlined, size: 64, color: subTextColor.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text(
                                LocaleService.tr('Chưa có tin nhắn nào', en: 'No messages yet'),
                                style: TextStyle(color: subTextColor, fontSize: 16),
                              ),
                              Text(
                                LocaleService.tr('Hãy bắt đầu cuộc trò chuyện!', en: 'Start the conversation!'),
                                style: TextStyle(color: subTextColor.withOpacity(0.7), fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(20),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final sender = msg['sender'];
                            final isMe = sender['_id'] == currentUserId;
                            
                            String timeString = '';
                            if (msg['createdAt'] != null) {
                              final dt = DateTime.parse(msg['createdAt']).toLocal();
                              timeString = DateFormat('HH:mm').format(dt);
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Row(
                                mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (!isMe) ...[
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: themeColor.withOpacity(0.2),
                                      backgroundImage: sender['profile']?['avatarUrl'] != null 
                                          ? NetworkImage(sender['profile']['avatarUrl']) 
                                          : null,
                                      child: sender['profile']?['avatarUrl'] == null 
                                          ? Text(
                                              (sender['name'] ?? sender['email'])[0].toUpperCase(),
                                              style: const TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 14),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        if (!isMe)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 4, bottom: 4),
                                            child: Text(
                                              sender['name'] ?? sender['email'].split('@')[0],
                                              style: TextStyle(fontSize: 12, color: subTextColor, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: isMe ? themeColor : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                            borderRadius: BorderRadius.only(
                                              topLeft: const Radius.circular(20),
                                              topRight: const Radius.circular(20),
                                              bottomLeft: Radius.circular(isMe ? 20 : 4),
                                              bottomRight: Radius.circular(isMe ? 4 : 20),
                                            ),
                                          ),
                                          child: Text(
                                            msg['text'] ?? '',
                                            style: TextStyle(
                                              color: isMe ? Colors.white : textColor,
                                              fontSize: 15,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4, right: 4, left: 4),
                                          child: Text(
                                            timeString,
                                            style: TextStyle(fontSize: 10, color: subTextColor.withOpacity(0.7)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isMe) const SizedBox(width: 24), // Offset for symmetry
                                ],
                              ),
                            );
                          },
                        ),
            ),

            // Input Area
            Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(color: textColor),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: LocaleService.tr('Nhập tin nhắn...', en: 'Type a message...'),
                          hintStyle: TextStyle(color: subTextColor),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF06B6D4).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
