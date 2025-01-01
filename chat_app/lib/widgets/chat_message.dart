import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:chat_app/objects.dart';
import 'package:intl/intl.dart';

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: message.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    color: Colors.white,
                  ),
                ),
                if (message.isLoading)
                  const SizedBox(width: 8),
                if (message.isLoading)
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
            if (!message.isLoading)
              if (!message.isUser)
                const SizedBox(height: 4),
              Row(
                mainAxisAlignment: message.isUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  if (message.content is String && (message.content as String).isNotEmpty)
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: message.isUser
                            ? Theme.of(context).primaryColor.withAlpha(50)
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.only(
                          topLeft: message.isUser ? Radius.circular(10) : Radius.circular(1),
                          topRight: message.isUser ? Radius.circular(1) : Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                        border: Border.all(
                          color: message.isUser
                              ? Theme.of(context).primaryColor.withAlpha(40)
                              : Theme.of(context).dividerColor.withAlpha(40),
                        ),
                      ),
                      child: MarkdownBody(
                        data: message.content as String,
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
          if (message.emails.isNotEmpty) ...[
            const SizedBox(height: 8),
            EmailListDropdown(emails: message.emails),
          ],
        ],
      ),
    );
  }
}

class EmailListDropdown extends StatefulWidget {
  final List<Email> emails;

  const EmailListDropdown({
    super.key,
    required this.emails,
  });

  @override
  State<EmailListDropdown> createState() => _EmailListDropdownState();
}

class _EmailListDropdownState extends State<EmailListDropdown> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor.withAlpha(40)),
          bottom: BorderSide(color: Theme.of(context).dividerColor.withAlpha(40)),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.emails.length} Email${widget.emails.length > 1 ? 's' : ''} Found',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  physics: const ClampingScrollPhysics(
                    parent: ScrollPhysics(
                      parent: BouncingScrollPhysics(
                        decelerationRate: ScrollDecelerationRate.fast,
                      ),
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    decelerationRate: ScrollDecelerationRate.normal,
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: Column(
                    children: widget.emails.asMap().entries.map((entry) => 
                      EmailListItem(
                        email: entry.value,
                        index: entry.key + 1,
                      )
                    ).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class EmailListItem extends StatelessWidget {
  final Email email;
  final int index;

  const EmailListItem({
    super.key,
    required this.email,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime emailDate = DateFormat("EEE, d MMM yyyy HH:mm:ss").parse(
      email.date.split(' +')[0],
    );
    
    final String formattedDate = 
        '${emailDate.day.toString().padLeft(2, '0')}/'
        '${emailDate.month.toString().padLeft(2, '0')}/'
        '${emailDate.year.toString().substring(2)} '
        '${emailDate.hour.toString().padLeft(2, '0')}:'
        '${emailDate.minute.toString().padLeft(2, '0')}:'
        '${emailDate.second.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              margin: const EdgeInsets.only(right: 8),
              child: Text(
                '$index.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    email.subject,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          email.fromEmail,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
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
