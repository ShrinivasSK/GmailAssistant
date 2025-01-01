import 'package:chat_app/pages/chat_page.dart';
import 'package:chat_app/pages/google_auth.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/services/auth.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gmail Assistant',
      theme: ThemeData(
        colorScheme: ColorScheme(
          primary: Colors.deepPurple,
          onPrimary: Colors.white,
          brightness: Brightness.light,
          secondary: Colors.green,
          onSecondary: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
        ),
      ),
      home: FutureBuilder<bool>(
        future: AuthService().isSignedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return snapshot.data == true ? ChatPage() : GoogleAuthPage();
        },
      ),
      routes: {
        '/home': (context) => ChatPage(),
        '/signin': (context) => GoogleAuthPage(),
      },
    );
  }
}

// import 'package:dash_chat_2/dash_chat_2.dart';
// import 'package:flutter/material.dart';

// class ChatPage extends StatefulWidget {
//   const ChatPage({super.key});

//   @override
//   State<ChatPage> createState() => _ChatPageState();
// }

// class _ChatPageState extends State<ChatPage> {
//   final _currentUser = ChatUser(id: '1', firstName: 'User');
//   final _assistantUser = ChatUser(id: '2', firstName: 'Gmail', lastName: 'Assistant');
//   final _messages = <ChatMessage>[];
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Chat'),
//       ),
//       body: DashChat(currentUser: _currentUser, onSend: (ChatMessage m) {
//         getChatResponse(m);
//       }, messages: _messages,
//      )
//     );
//   }

//   Future<void> getChatResponse(ChatMessage message) async {
//       setState(() {
//         _messages.insert(0, message);
//         _messages.insert(0, ChatMessage(user: _assistantUser, createdAt: DateTime.now(), text: 'Hello, how can I help you today?'));
//       });
//     }
// }
