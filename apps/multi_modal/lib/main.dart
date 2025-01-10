import "package:flutter/material.dart";
import "package:multi_modal/chat_page.dart";
import "package:multi_modal/chat_repository.dart";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Multi-Modal Chatbot",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChatPage(chatRepository: ChatRepository()),
      // home: Basic(),
    );
  }
}
