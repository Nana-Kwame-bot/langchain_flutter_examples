import "dart:io";

import "package:dash_chat_2/dash_chat_2.dart";
import "package:flutter/material.dart";
import "package:multi_modal/chat_repository.dart";
import "package:multi_modal/constants.dart";
import "package:image_picker/image_picker.dart";

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.chatRepository});

  final ChatRepository chatRepository;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

// ! fix renderflex

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  ChatRepository get _chatRepository => widget.chatRepository;

  List<ChatMessage> messages = [];

  Future<void> _showImageCaptionDialog(XFile image) async {
    final TextEditingController captionController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Preview & Add Caption",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Image preview with constrained height
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(image.path),
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: captionController,
                  decoration: const InputDecoration(
                    hintText: "Add a caption...",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _sendImageMessage(image, captionController.text);
                        Navigator.pop(context);
                      },
                      child: const Text("Send"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndShowImageDialog({
    ImageSource source = ImageSource.gallery,
  }) async {
    final XFile? image = await _picker.pickImage(source: source);

    if (image != null) {
      await _showImageCaptionDialog(image);
    }
  }

  Future<void> _sendImageMessage(XFile image, String caption) async {
    final ChatMessage message = ChatMessage(
      user: Constants.user,
      createdAt: DateTime.now(),
      text: caption,
      medias: [
        ChatMedia(
          url: image.path,
          fileName: image.name,
          type: MediaType.image,
        ),
      ],
    );

    setState(() {
      messages.insert(0, message);
    });

    // Handle sending to chat repository
    final response = await _chatRepository.handleOnSend(message);

    setState(() {
      messages.insert(0, response);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Multi-Modal Chatbot"),
      ),
      body: DashChat(
        inputOptions: InputOptions(
          textController: _textController,
          trailing: [
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: () {
                _pickAndShowImageDialog(source: ImageSource.camera);
              },
            ),
            IconButton(
              icon: const Icon(Icons.image),
              onPressed: () => _pickAndShowImageDialog(),
            ),
            IconButton(
              icon: const Icon(Icons.attach_file),
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
