import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../services/locale_service.dart';

// ⚙️ Cấu hình URL backend:
// - Khi chạy local trên Android Emulator: 'http://10.0.2.2:5000'
// - Khi chạy local trên thiết bị thật: 'http://<IP_MÁY_TÍNH>:5000' (ví dụ: 'http://192.168.1.5:5000')
// - Khi deploy production: 'https://prm-tan.vercel.app' (chỉ HTTP, KHÔNG có Socket.IO)
const String _kBackendBaseUrl = 'https://prm-tan.vercel.app';

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
  bool isSending = false;
  bool _isPollingMessages = false;
  String currentUserId = '';
  Timer? _pollTimer;
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
        // authController lưu user với field "id" (không phải "_id")
        currentUserId = (userData['id'] ?? userData['_id'] ?? '').toString();
        print('✅ currentUserId: $currentUserId');
      }

      await _fetchMessages();
      _connectSocket();
      _startMessagePolling();
    } catch (e) {
      print('Error initializing chat: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _startMessagePolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (socket != null && socket!.connected) {
        // Socket is connected, no need to poll via HTTP.
        return;
      }
      _fetchMessages(silent: true);
    });
  }

  Future<void> _fetchMessages({bool silent = false}) async {
    if (_isPollingMessages) return;
    _isPollingMessages = true;

    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse(
            '$_kBackendBaseUrl/api/projects/${widget.projectId}/messages?limit=50'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final freshMessages = jsonDecode(response.body) as List<dynamic>;
        if (!mounted) return;

        if (silent) {
          _mergeMessages(freshMessages);
        } else {
          setState(() {
            messages = freshMessages;
            isLoading = false;
          });
          _scrollToBottom();
        }
      } else {
        print(
            '❌ Fetch messages failed: ${response.statusCode} ${response.body}');
        if (mounted && !silent) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error fetching messages: $e');
      if (mounted && !silent) {
        setState(() {
          isLoading = false;
        });
      }
    } finally {
      _isPollingMessages = false;
    }
  }

  void _mergeMessages(List<dynamic> freshMessages) {
    if (!mounted || freshMessages.isEmpty) return;

    final existingIds = messages
        .map((message) => message['_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    var changed = false;
    for (final message in freshMessages) {
      final id = message['_id']?.toString() ?? '';
      if (id.isEmpty || existingIds.contains(id)) continue;
      messages.add(message);
      existingIds.add(id);
      changed = true;
    }

    if (!changed) return;

    messages.sort((a, b) {
      final aDate = DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return aDate.compareTo(bDate);
    });

    setState(() {});
    _scrollToBottom();
  }

  void _connectSocket() {
    // Kết nối socket tới local backend
    // Dùng OptionBuilder (đúng cú pháp cho socket_io_client v3.x)
    socket = IO.io(
      _kBackendBaseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .build(),
    );

    socket!.connect();

    socket!.onConnect((_) {
      print('✅ Connected to socket server');
      socket!.emit('joinProject', widget.projectId);
    });

    socket!.onConnectError((err) {
      print('❌ Socket connection error: $err');
    });

    socket!.on('receiveMessage', (data) {
      _mergeMessages([data]);
    });

    socket!.onDisconnect((_) => print('🔌 Disconnected from socket server'));
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || isSending) return;

    setState(() => isSending = true);
    _messageController.clear();

    try {
      final token = await AuthService.getToken();
      final response = await http
          .post(
            Uri.parse(
                '$_kBackendBaseUrl/api/projects/${widget.projectId}/messages'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final newMessage = jsonDecode(response.body);
        _mergeMessages([newMessage]);
      } else {
        print('❌ Send message failed: ${response.statusCode} ${response.body}');
        // Khôi phục text nếu gửi thất bại
        _messageController.text = text;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không gửi được tin nhắn. Thử lại!'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error sending message: $e');
      _messageController.text = text;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi kết nối. Kiểm tra mạng!'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSending = false);
    }
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
    _pollTimer?.cancel();
    socket?.disconnect();
    socket?.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
          [ThemeService.isDarkMode, LocaleService.languageCode]),
      builder: (context, child) {
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                            color: isDark
                                ? Colors.white.withOpacity(0.15)
                                : Colors.black.withOpacity(0.15),
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
                                child: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: themeColor,
                                    size: 24),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.projectName,
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textColor),
                                  ),
                                  Text(
                                    LocaleService.tr('Nhắn tin nhóm',
                                        en: 'Team Chat'),
                                    style: TextStyle(
                                        fontSize: 13, color: subTextColor),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon:
                                Icon(Icons.close_rounded, color: subTextColor),
                            style: IconButton.styleFrom(
                              backgroundColor: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.05),
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
                      ? const Center(
                          child: CircularProgressIndicator(color: themeColor))
                      : messages.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.forum_outlined,
                                      size: 64,
                                      color: subTextColor.withOpacity(0.5)),
                                  const SizedBox(height: 16),
                                  Text(
                                    LocaleService.tr('Chưa có tin nhắn nào',
                                        en: 'No messages yet'),
                                    style: TextStyle(
                                        color: subTextColor, fontSize: 16),
                                  ),
                                  Text(
                                    LocaleService.tr(
                                        'Hãy bắt đầu cuộc trò chuyện!',
                                        en: 'Start the conversation!'),
                                    style: TextStyle(
                                        color: subTextColor.withOpacity(0.7),
                                        fontSize: 14),
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
                                // So sánh bằng toString() để tránh lỗi ObjectId vs string
                                final isMe =
                                    sender['_id']?.toString() == currentUserId;

                                String timeString = '';
                                if (msg['createdAt'] != null) {
                                  final dt = DateTime.parse(msg['createdAt'])
                                      .toLocal();
                                  timeString = DateFormat('HH:mm').format(dt);
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Row(
                                    mainAxisAlignment: isMe
                                        ? MainAxisAlignment.end
                                        : MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (!isMe) ...[
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor:
                                              themeColor.withOpacity(0.2),
                                          backgroundImage: sender['profile']
                                                      ?['avatarUrl'] !=
                                                  null
                                              ? NetworkImage(sender['profile']
                                                  ['avatarUrl'])
                                              : null,
                                          child: sender['profile']
                                                      ?['avatarUrl'] ==
                                                  null
                                              ? Text(
                                                  (sender['name'] ??
                                                          sender['email'])[0]
                                                      .toUpperCase(),
                                                  style: const TextStyle(
                                                      color: themeColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Flexible(
                                        child: Column(
                                          crossAxisAlignment: isMe
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                          children: [
                                            if (!isMe)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 4, bottom: 4),
                                                child: Text(
                                                  sender['username']
                                                              ?.toString()
                                                              .isNotEmpty ==
                                                          true
                                                      ? '@${sender['username']}'
                                                      : (sender['name']
                                                                  ?.toString()
                                                                  .isNotEmpty ==
                                                              true
                                                          ? sender['name']
                                                          : sender['email']
                                                              .split('@')[0]),
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: subTextColor,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 12),
                                              decoration: BoxDecoration(
                                                color: isMe
                                                    ? themeColor
                                                    : (isDark
                                                        ? const Color(
                                                            0xFF1E293B)
                                                        : const Color(
                                                            0xFFF1F5F9)),
                                                borderRadius: BorderRadius.only(
                                                  topLeft:
                                                      const Radius.circular(20),
                                                  topRight:
                                                      const Radius.circular(20),
                                                  bottomLeft: Radius.circular(
                                                      isMe ? 20 : 4),
                                                  bottomRight: Radius.circular(
                                                      isMe ? 4 : 20),
                                                ),
                                              ),
                                              child: Text(
                                                msg['text'] ?? '',
                                                style: TextStyle(
                                                  color: isMe
                                                      ? Colors.white
                                                      : textColor,
                                                  fontSize: 15,
                                                  height: 1.3,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 4, right: 4, left: 4),
                                              child: Text(
                                                timeString,
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: subTextColor
                                                        .withOpacity(0.7)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isMe)
                                        const SizedBox(
                                            width: 24), // Offset for symmetry
                                    ],
                                  ),
                                );
                              },
                            ),
                ),

                // Input Area
                Container(
                  padding: EdgeInsets.fromLTRB(20, 16, 20,
                      MediaQuery.of(context).viewInsets.bottom + 20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    border: Border(top: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.black.withOpacity(0.05)),
                          ),
                          child: TextField(
                            controller: _messageController,
                            style: TextStyle(color: textColor),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                            decoration: InputDecoration(
                              hintText: LocaleService.tr('Nhập tin nhắn...',
                                  en: 'Type a message...'),
                              hintStyle: TextStyle(color: subTextColor),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: isSending ? null : _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isSending
                                  ? [Colors.grey, Colors.grey]
                                  : const [
                                      Color(0xFF06B6D4),
                                      Color(0xFF3B82F6)
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isSending
                                ? []
                                : [
                                    BoxShadow(
                                      color: const Color(0xFF06B6D4)
                                          .withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                          ),
                          child: isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded,
                                  color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
