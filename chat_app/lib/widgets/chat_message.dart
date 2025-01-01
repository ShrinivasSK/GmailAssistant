import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatMessage extends StatelessWidget {
  final String message;
  final bool isUser;
  final bool isLoading;

  const ChatMessage({
    super.key,
    required this.message,
    required this.isUser,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    color: Colors.white,
                  ),
                ),
                if (isLoading)
                  const SizedBox(width: 8),
                if (isLoading)
                TweenAnimationBuilder(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Thinking...'),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            if (!isLoading)
              if (!isUser)
                const SizedBox(height: 4),
              Row(
                mainAxisAlignment: isUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  if (message.isNotEmpty)
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Theme.of(context).primaryColor.withAlpha(50)
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.only(
                          topLeft: isUser ? Radius.circular(10) : Radius.circular(1),
                          topRight: isUser ? Radius.circular(1) : Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                        border: Border.all(
                          color: isUser
                              ? Theme.of(context).primaryColor.withAlpha(40)
                              : Theme.of(context).dividerColor.withAlpha(40),
                        ),
                      ),
                      child: MarkdownBody(
                        data: message,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            fontFamily: 'FiraCode',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
        ],
      ),
    );
  }
}
