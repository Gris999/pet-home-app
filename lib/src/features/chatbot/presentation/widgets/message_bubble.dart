import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.text,
    required this.isBot,
    this.isLocation = false,
    this.onSpeak,
    this.isSpeaking = false,
  });

  final String text;
  final bool isBot;
  final bool isLocation;
  final VoidCallback? onSpeak;
  final bool isSpeaking;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isBot
        ? const Color(0xFFEADCF5)
        : (isLocation ? const Color(0xFFD8F3DC) : Colors.white);

    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 310),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isBot ? 4 : 18),
            bottomRight: Radius.circular(isBot ? 18 : 4),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            if (isLocation)
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.place_outlined, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Ubicacion compartida',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.35,
                    ),
                  ),
                ),
                if (isBot && onSpeak != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: onSpeak,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        isSpeaking
                            ? Icons.stop_circle_outlined
                            : Icons.volume_up_outlined,
                        size: 22,
                        color: const Color(0xFF6A11CB),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (isBot && isSpeaking)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Reproduciendo...',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6A11CB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
