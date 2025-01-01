class Email {
  final String messageId;
  final String fromEmail;
  final String subject;
  final String date;

  Email({
    required this.messageId,
    required this.fromEmail,
    required this.subject,
    required this.date,
  });
}

enum ChatRole {
  user,
  model,
  functionCall,
  functionResponse,
}

class ChatMessage {
  final Object content;
  final ChatRole role;
  final bool isLoading;
  final List<Email> emails;

  bool get isUser => role == ChatRole.user;
  bool get isInternal => !(role == ChatRole.user || role == ChatRole.model);

  ChatMessage({
    required this.content,
    required this.role,
    this.isLoading = false,
    this.emails = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'role': role.name,
    };
  }
}
