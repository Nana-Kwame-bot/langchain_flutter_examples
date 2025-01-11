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
      title: "Chat with Dash",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          primary: Color(0XFF02569B),
          secondary: Color(0XFF13B9FD),
          seedColor: Color(0XFF02569B),
          surface: Color(0XFFF5F5F5),
          tertiary: Color(0XFFFFB300),
          error: Color(0XFFD32F2F),
        ),
        useMaterial3: true,
      ),
      home: const ChatPage(chatRepository: ChatRepository()),
      // home: Basic(),
    );
  }
}
