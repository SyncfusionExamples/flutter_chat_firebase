import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_chat/chat.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final List<ChatMessage> _messages = [];

  final DatabaseReference _messageStream =
      FirebaseDatabase.instance.ref('messages');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Syncfusion Flutter Chat with Firebase'),
        ),
        body: StreamBuilder<DatabaseEvent>(
          stream: _messageStream.onValue,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final data =
                snapshot.data?.snapshot.value as Map<dynamic, dynamic>?;
            if (data != null && data.isNotEmpty) {
              _messages.clear();
              data.forEach((key, value) {
                final message = ChatMessage(
                  text: value['text'],
                  time: DateTime.parse(value['time']),
                  author: ChatAuthor(
                    id: value['authorId'],
                    name: value['authorName'],
                  ),
                );
                _messages.add(message);
              });
              _messages.sort((a, b) => a.time.compareTo(b.time));
            }

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: SfChat(
                messages: _messages,
                outgoingUser: '00-00230-23423',
                composer: const ChatComposer(
                  decoration: InputDecoration(
                    hintText: 'Type a message',
                  ),
                ),
                placeholderBuilder: _messages.isEmpty
                    ? (context) {
                        return const CircularProgressIndicator();
                      }
                    : null,
                actionButton: ChatActionButton(
                  onPressed: (String newMessage) {
                    final chatMessage = ChatMessage(
                      text: newMessage,
                      time: DateTime.now(),
                      author: const ChatAuthor(
                        id: '00-00230-23423',
                        name: 'Sam',
                      ),
                    );

                    setState(() {
                      _messages.add(chatMessage);
                    });
                    _sendMessageToFirebase(chatMessage);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _sendMessageToFirebase(ChatMessage message) async {
    await _messageStream.push().set({
      'text': message.text,
      'time': message.time.toIso8601String(),
      'authorId': message.author.id,
      'authorName': message.author.name,
    });
  }
}
