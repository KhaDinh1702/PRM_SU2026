import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../services/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../services/theme_service.dart';
import '../../../services/locale_service.dart';

// ⚙️ Cấu hình URL backend động:
// Tự động phân tích từ AuthService.apiBaseUrl để hỗ trợ cả local và production.
String get _backendBaseUrl {
  final apiBase = AuthService.apiBaseUrl;
  if (apiBase.endsWith('/api')) {
    return apiBase.substring(0, apiBase.length - 4);
  }
  return apiBase;
}

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
            '$_backendBaseUrl/api/projects/${widget.projectId}/messages?limit=50'),
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
    final url = _backendBaseUrl;
    if (url.contains('vercel.app')) {
      print('⚠️ Vercel deployment detected. Socket.IO connection disabled (falling back to HTTP polling).');
      return;
    }

    // Kết nối socket tới local backend
    // Dùng OptionBuilder (đúng cú pháp cho socket_io_client v3.x)
    socket = IO.io(
      url,
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
                '$_backendBaseUrl/api/projects/${widget.projectId}/messages'),
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
        final themeColor = AppColors.projectAccent;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: dialogBg.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusXL + 6.0),
                topRight: Radius.circular(AppSizes.radiusXL + 6.0),
              ),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSizes.paddingL, vertical: AppSizes.paddingM),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : Colors.black.withValues(alpha: 0.15),
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
                                padding: const EdgeInsets.all(AppSizes.paddingS + 2.0),
                                decoration: BoxDecoration(
                                  color: themeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppSizes.radiusS + 4.0),
                                ),
                                child: Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: themeColor,
                                    size: AppSizes.iconL),
                              ),
                              const SizedBox(width: AppSizes.paddingM),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.projectName,
                                    style: TextStyle(
                                        fontSize: AppSizes.fontXL - 2.0,
                                        fontWeight: FontWeight.bold,
                                        color: textColor),
                                  ),
                                  Text(
                                    LocaleService.tr('Nhắn tin nhóm',
                                        en: 'Team Chat'),
                                    style: TextStyle(
                                        fontSize: AppSizes.fontM - 1.0, color: subTextColor),
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
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.05),
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
                      ? Center(
                          child: CircularProgressIndicator(color: themeColor))
                      : messages.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.forum_outlined,
                                      size: 64,
                                      color: subTextColor.withValues(alpha: 0.5)),
                                  const SizedBox(height: AppSizes.paddingM),
                                  Text(
                                    LocaleService.tr('Chưa có tin nhắn nào',
                                        en: 'No messages yet'),
                                    style: TextStyle(
                                        color: subTextColor, fontSize: AppSizes.fontL),
                                  ),
                                  Text(
                                    LocaleService.tr(
                                        'Hãy bắt đầu cuộc trò chuyện!',
                                        en: 'Start the conversation!'),
                                    style: TextStyle(
                                        color: subTextColor.withValues(alpha: 0.7),
                                        fontSize: AppSizes.fontM),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(AppSizes.paddingM + 4.0),
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
                                  padding: const EdgeInsets.only(bottom: AppSizes.paddingM),
                                  child: Row(
                                    mainAxisAlignment: isMe
                                        ? MainAxisAlignment.end
                                        : MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (!isMe) ...[
                                        CircleAvatar(
                                          radius: AppSizes.avatarS / 2,
                                          backgroundColor:
                                              themeColor.withValues(alpha: 0.2),
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
                                                  style: TextStyle(
                                                      color: themeColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: AppSizes.fontM),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: AppSizes.paddingS),
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
                                                      fontSize: AppSizes.fontS + 1.0,
                                                      color: subTextColor,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: AppSizes.paddingM,
                                                      vertical: AppSizes.paddingM - 4.0),
                                              decoration: BoxDecoration(
                                                color: isMe
                                                    ? themeColor
                                                    : (isDark
                                                        ? AppColors.cardDark
                                                        : AppColors.cardLight),
                                                borderRadius: BorderRadius.only(
                                                  topLeft:
                                                      const Radius.circular(AppSizes.radiusM + 4.0),
                                                  topRight:
                                                      const Radius.circular(AppSizes.radiusM + 4.0),
                                                  bottomLeft: Radius.circular(
                                                      isMe ? AppSizes.radiusM + 4.0 : AppSizes.paddingXS),
                                                  bottomRight: Radius.circular(
                                                      isMe ? AppSizes.paddingXS : AppSizes.radiusM + 4.0),
                                                ),
                                              ),
                                              child: Text(
                                                msg['text'] ?? '',
                                                style: TextStyle(
                                                  color: isMe
                                                      ? Colors.white
                                                      : textColor,
                                                  fontSize: AppSizes.fontM + 1.0,
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
                                                        .withValues(alpha: 0.7)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isMe)
                                        const SizedBox(
                                            width: AppSizes.paddingL), // Offset for symmetry
                                    ],
                                  ),
                                );
                              },
                            ),
                ),

                // Input Area
                Container(
                  padding: EdgeInsets.fromLTRB(
                      AppSizes.paddingM + 4.0,
                      AppSizes.paddingM,
                      AppSizes.paddingM + 4.0,
                      MediaQuery.of(context).viewInsets.bottom + AppSizes.paddingM + 4.0),
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
                                ? AppColors.cardDark
                                : AppColors.cardLight,
                            borderRadius: BorderRadius.circular(AppSizes.radiusL),
                            border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.05)),
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
                                  horizontal: AppSizes.paddingM + 4.0, vertical: AppSizes.paddingM - 2.0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingS + 4.0),
                      GestureDetector(
                        onTap: isSending ? null : _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(AppSizes.paddingM - 2.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isSending
                                  ? [Colors.grey, Colors.grey]
                                  : [
                                      AppColors.projectAccent,
                                      AppColors.primary
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppSizes.radiusM + 4.0),
                            boxShadow: isSending
                                ? []
                                : [
                                    BoxShadow(
                                      color: AppColors.projectAccent
                                          .withValues(alpha: 0.3),
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
                              : Icon(Icons.send_rounded,
                                  color: Colors.white, size: AppSizes.iconM),
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
