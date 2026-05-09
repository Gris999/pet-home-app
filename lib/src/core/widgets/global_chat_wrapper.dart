import 'package:flutter/material.dart';

import '../../features/chatbot/presentation/widgets/chat_fab.dart';

class GlobalChatWrapper extends StatelessWidget {
  final Widget child;

  const GlobalChatWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,

        const Positioned(
          bottom: 20,
          right: 20,
          child: ChatFab(),
        ),
      ],
    );
  }
}