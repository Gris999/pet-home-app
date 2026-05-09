import 'package:flutter/material.dart';

import '../pages/chatbot_page.dart';

class ChatFab extends StatelessWidget {
  const ChatFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: const Color.fromARGB(255, 232, 130, 5),

      elevation: 6,

      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ChatbotPage(),
          ),
        );
      },

      child: const Icon(
        Icons.smart_toy_rounded,
        color: Colors.white,
        size: 30,
      ),
    );
  }
}