import 'package:flutter/material.dart';
import 'package:chat_app/services/auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chat_app/widgets/chat_message.dart';
import 'package:chat_app/objects.dart';
import 'package:chat_app/services/chat_api.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = <ChatMessage>[
    // ChatMessage(
    //   content: 'Can you summarise my promotional emails?',
    //   role: ChatRole.user,
    // ),
    // ChatMessage(
    //   content: 'Yes, you received several emails in the last 3 days.  The emails are from various senders including Splitwise, LinkedIn, Github, and others.  The subjects of the emails range from account balances and invitations to software alerts and newsletters.  There is also an email about a mutual fund transaction.\n',
    //   role: ChatRole.model,
    //   emails: [
    //     Email(
    //       messageId: '123',
    //       fromEmail: 'test@example.com',
    //       date: 'Wed, 1 Jan 2025 13:55:56 +0000 (UTC)',
    //       subject: 'Test email 1',
    //     ),
    //     Email(
    //       messageId: '123',
    //       fromEmail: 'test@example.com',
    //       date: 'Wed, 1 Jan 2025 13:55:56 +0000 (UTC)',
    //       subject: 'Test email 1',
    //     ),
    //     Email(
    //       messageId: '123',
    //       fromEmail: 'test@example.com',
    //       date: 'Wed, 1 Jan 2025 13:55:56 +0000 (UTC)',
    //       subject: 'Test email 1',
    //     ),
    //     Email(
    //       messageId: '123',
    //       fromEmail: 'test@example.com',
    //       date: 'Wed, 1 Jan 2025 13:55:56 +0000 (UTC)',
    //       subject: 'Test email 1',
    //     ),
    //     Email(
    //       messageId: '123',
    //       fromEmail: 'test@example.com',
    //       date: 'Wed, 1 Jan 2025 13:55:56 +0000 (UTC)',
    //       subject: 'Test email 2',
    //     ),
    //   ],
    // ),
  ];
  final ChatApi _chatApi = ChatApi();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text;
    _messageController.clear();

    setState(() {
      _messages.add(
        ChatMessage(
          content: userMessage,
          role: ChatRole.user,
        ),
      );
      _messages.add(
        ChatMessage(
          content: '',
          role: ChatRole.model,
          isLoading: true,
        ),
      );
    });

    _scrollToBottom();

    try {
      final credentials = await AuthService().getCredentials();
      final response = await _chatApi.sendMessage(
        messages: _messages,
        token: credentials['accessToken'] ?? '',
      );
      
      setState(() {
        _messages.removeLast();
        _messages.addAll(response);
      });
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add(
          ChatMessage(
            content: 'Sorry, an error occurred while processing your request.',
            role: ChatRole.model,
          ),
        );
      });
    }
    
    _scrollToBottom();
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

  void _startNewChat() {
    setState(() {
      _messages.clear();
    });
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
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _startNewChat,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: _signOut,
            style: TextButton.styleFrom(
              side: BorderSide(
                color: Theme.of(context).colorScheme.inversePrimary.withAlpha(128),
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
                        if (!_messages[index].isInternal) {
                          return ChatMessageWidget(message: _messages[index]);
                        }
                        return const SizedBox.shrink();
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

