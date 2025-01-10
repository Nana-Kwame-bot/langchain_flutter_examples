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
  final TextEditingController _textController = TextEditingController();
  ChatRepository get _chatRepository => widget.chatRepository;

  List<ChatMessage> messages = [];

  @override
  void initState() {
    super.initState();
    debugPrint("ChatPage initialized");
  }

  // final ImagePicker _picker = ImagePicker();

  // Future<void> sendImage() async {
  //   final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
  //   if (image != null) {
  //     final ChatMessage message = ChatMessage(
  //       user: Constants.user,
  //       createdAt: DateTime.now(),
  //       text: _textController.text,
  //       medias: [
  //         ChatMedia(
  //           url: image.path,
  //           fileName: image.name,
  //           type: MediaType.image,
  //         ),
  //       ],
  //     );
  //     setState(() {
  //       messages.insert(0, message);
  //       _textController.clear();
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Multi-Modal Chatbot"),
      ),
      body: DashChat(
        inputOptions: InputOptions(
          // ! probably not going to be using this controller for anything
          // if we go ahead and create a dialog or something for the image and
          // text to show up together.
          textController: _textController,
          trailing: [
            IconButton(
              icon: Icon(Icons.camera_alt),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.image),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.attach_file),
              onPressed: () {},
            ),
          ],
        ),
        currentUser: Constants.user,
        onSend: _handleOnSend,
        messages: messages,
      ),
    );
  }

  void _handleOnSend(message) async {
    setState(() {
      messages.insert(0, message);
    });

    final response = await _chatRepository.handleOnSend(message);

    setState(() {
      messages.insert(0, response);
    });
  }
}
