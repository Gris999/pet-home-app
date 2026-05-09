class ChatMessage {
  ChatMessage({
    required this.text,
    required this.isBot,
    this.isLocation = false,
  });

  final String text;
  final bool isBot;
  final bool isLocation;
}
