import "package:dash_chat_2/dash_chat_2.dart";
import "package:flutter/material.dart";
import "package:multi_modal/extensions/build_context_extension.dart";
import "package:multi_modal/chat_repository.dart";
import "package:multi_modal/constants.dart";
import "package:image_picker/image_picker.dart";
import "package:multi_modal/extensions/chat_message_extension.dart";

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.chatRepository});

  final ChatRepository chatRepository;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ImagePicker _picker = ImagePicker();
  ChatRepository get _chatRepository => widget.chatRepository;

  List<ChatMessage> messages = [];
  List<ChatUser> typingUsers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Chat with Dash"),
      ),
      body: DashChat(
        typingUsers: typingUsers,
        inputOptions: InputOptions(
          inputDisabled: typingUsers.isNotEmpty,
          sendOnEnter: true,
          trailing: [
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: typingUsers.isEmpty
                  ? () => _pickAndShowImageDialog(source: ImageSource.camera)
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.image),
              onPressed:
                  typingUsers.isEmpty ? () => _pickAndShowImageDialog() : null,
            ),
          ],
        ),
        currentUser: Constants.user,
        onSend: _handleOnSendPressed,
        messages: messages,
        messageOptions: MessageOptions(
          showOtherUsersAvatar: true,
        ),
      ),
    );
  }

  Future<void> _pickAndShowImageDialog({
    ImageSource source = ImageSource.gallery,
  }) async {
    final XFile? image = await _picker.pickImage(source: source);

    if (image != null) {
      if (!mounted) return;

      final result = await context.showImageCaptionDialog(image);

      result.fold<void>(
        (error) => context.showErrorMessage(error),
        (right) async {
          final (:image, :caption) = right;

          await _sendImageMessage(image: image, caption: caption);
        },
      );
    }
  }

  Future<void> _sendImageMessage({
    required XFile image,
    required String caption,
  }) async {
    final XFile(:mimeType, :name, :path) = image;

    final userMessage = ChatMessage(
      user: Constants.user,
      createdAt: DateTime.now(),
      text: caption,
      medias: [
        ChatMedia(
          url: path,
          fileName: name,
          type: MediaType.image,
          customProperties: {
            "mimeType": mimeType,
          },
        ),
      ],
    );

    _addUserMessage(userMessage);

    final response = await _chatRepository.sendImageMessage(userMessage);

    setState(() {
      typingUsers.remove(Constants.ai);
    });

    response.fold<void>(
      (error) => _handleSendError(error: error, userMessage: userMessage),
      (chatMessage) => _handleSendSuccess(
        userMessage: userMessage,
        aiMessage: chatMessage,
      ),
    );
  }

  void _handleOnSendPressed(ChatMessage textMessage) async {
    final userMessage = textMessage.copyWith(
      user: Constants.user,
      createdAt: DateTime.now(),
    );

    _addUserMessage(userMessage);

    final response = await _chatRepository.sendTextMessage(userMessage);

    setState(() {
      typingUsers.remove(Constants.ai);
    });

    response.fold<void>(
      (error) => _handleSendError(error: error, userMessage: userMessage),
      (chatMessage) => _handleSendSuccess(
        userMessage: userMessage,
        aiMessage: chatMessage,
      ),
    );
  }

  void _addUserMessage(ChatMessage message) {
    setState(() {
      typingUsers.add(Constants.ai);
      messages.insert(0, message);
    });
  }

  void _handleSendError({
    required String error,
    required ChatMessage userMessage,
  }) {
    context.showErrorMessage(error);
  }

  void _handleSendSuccess({
    required ChatMessage userMessage,
    required ChatMessage aiMessage,
  }) {
    setState(() {
      messages = [
        aiMessage,
        ...messages.map((m) {
          if (m.user.id == userMessage.user.id &&
              m.createdAt == userMessage.createdAt) {
            return m;
          }
          return m;
        }),
      ];
    });
  }
}
