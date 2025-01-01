import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chat_app/objects.dart';

class ChatApi {
  final String _baseURL = 'https://gmail-assistant-chi.vercel.app';

  Future<List<ChatMessage>> sendMessage({ 
    required List<ChatMessage> messages,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseURL/chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'messages': messages.where((m) => !m.isLoading).map((message) => message.toJson()).toList(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get chat response: ${response.body}');
    }

    final res = jsonDecode(response.body);
    final responseMessages = <ChatMessage>[];

    for (var message in res['messages']) {
      if (message['role'] == ChatRole.model.name) {
        final emails = <Email>[];
        for (var email in (res['emails'] as List<dynamic>?) ?? []) {
          emails.add(Email(
            messageId: email['message_id'],
            fromEmail: email['from_email'],
            date: email['date'],
            subject: email['subject'],
          ));
        }
        responseMessages.add(ChatMessage(
          content: message['content'],
          role: ChatRole.model,
          emails: emails,
        ));
      } else {
        responseMessages.add(ChatMessage(
          content: message['content'],
          role: ChatRole.values.firstWhere((e) => e.name == message['role']),
        ));
      }
    }

    return responseMessages;
  }
}