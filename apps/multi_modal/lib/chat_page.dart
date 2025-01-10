import "package:dash_chat_2/dash_chat_2.dart";
import "package:flutter/material.dart";
import "package:multi_modal/chat_repository.dart";
import "package:multi_modal/constants.dart";

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.chatRepository});

  final ChatRepository chatRepository;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  ChatRepository get _chatRepository => widget.chatRepository;

  List<ChatMessage> messages = [];

  @override
  void initState() {
    super.initState();
    debugPrint("ChatPage initialized");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Multi-Modal Chatbot"),
      ),
      body: DashChat(
        currentUser: Constants.user,
        onSend: (message) async {
          setState(() {
            messages.insert(0, message);
          });

          final response = await _chatRepository.handleOnSend(message);

          setState(() {
            messages.insert(0, response);
          });
        },
        messages: messages,
      ),
    );
  }
}
