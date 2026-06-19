import 'package:flutter/material.dart';
import '../project_shared.dart';

/// Tab chat: hiển thị empty state và nút mở chat.
class ChatTab extends StatelessWidget {
  final VoidCallback onOpenChat;

  const ChatTab({super.key, required this.onOpenChat});

  @override
  Widget build(BuildContext context) {
    return ProjectEmptyState(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'No messages yet',
      text: 'Start discussing this project with your team.',
      cta: 'Open chat',
      ctaIcon: Icons.chat_bubble_rounded,
      onPressed: onOpenChat,
    );
  }
}
