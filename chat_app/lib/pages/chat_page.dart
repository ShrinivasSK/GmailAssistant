import 'package:flutter/material.dart';
import 'package:chat_app/services/auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chat_app/widgets/chat_message.dart';
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = <ChatMessage>[];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          message: _messageController.text,
          isUser: true,
        ),
      );
      // Add temporary thinking state
      _messages.add(
        const ChatMessage(
          message: '',
          isUser: false,
          isLoading: true,  // New parameter
        ),
      );
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate AI response after delay
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _messages.removeLast();  // Remove thinking indicator
        _messages.add(
          ChatMessage(
            message: "The emails are primarily promotional offers and newsletters.\nThere are several promotional emails from companies like Paytm, ICICI Prudential Life Insurance, and Baroda BNP Paribas Mutual Fund.\nThere are also newsletters from Medium containing articles related to AI and technology.\nAdditionally, there are several connection requests from LinkedIn.\n\n**Promotional Emails:**\n\n* **Financial Offers:** These emails include loan offers from Paytm, information on customer experience recognition from ICICI Prudential Life Insurance, and information on mutual fund performance from Baroda BNP Paribas Mutual Fund.\nThere's also an email about accessing insurance policies through Bima Central.\n\n* **Newsletters:** The emails from Medium's Daily Digest are newsletters featuring various articles on AI, data science, and technology.\n\n**LinkedIn Connections:**\n\nSeveral emails are LinkedIn connection requests from different individuals.\nThere is also a notification email indicating increased activity on the user's LinkedIn profile.",
            isUser: false,
          ),
        );
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _signOut() async {
    try {
      await AuthService().signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/signin');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to sign out')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SvgPicture.asset(
              'assets/logo.svg',
              height: 48,
            ),
            const SizedBox(width: 8),
            Text(
              'Gmail Assistant',
              style: TextStyle(
                fontSize: 20,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _signOut,
            style: TextButton.styleFrom(
              side: BorderSide(
                color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.5),
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: Text(
              'Sign out',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Theme.of(context).primaryColor.withAlpha(128),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Welcome to the Gmail Assistant!',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'How can I help you today?',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _messages[index];
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 96, // Approximately 4 lines (24px per line)
                      ),
                      child: SingleChildScrollView(
                        child: TextField(
                          controller: _messageController,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            hintText: 'Type your question...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 2),
                          ),
                          style: TextStyle(
                            fontSize: 14,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
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
