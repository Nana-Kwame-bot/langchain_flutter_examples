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

  final _textInputFocusNode = FocusNode();

  @override
  void dispose() {
    super.dispose();
    _textInputFocusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Multi-Modal Chatbot"),
      ),
      body: DashChat(
        typingUsers: typingUsers,
        inputOptions: InputOptions(
          focusNode: _textInputFocusNode,
          sendOnEnter: true,
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

    _textInputFocusNode.unfocus();

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
    final userMessage = ChatMessage(
      user: Constants.user,
      createdAt: DateTime.now(),
      text: caption,
      medias: [
        ChatMedia(
          url: image.path,
          fileName: image.name,
          type: DashMediaType.image,
        ),
      ],
    );

    _addUserMessage(userMessage);

    setState(() {
      typingUsers.add(Constants.ai);
    });

    final response = await _chatRepository.sendImageMessage(userMessage);

    response.fold<void>(
      (error) => _handleSendError(error: error, userMessage: userMessage),
      (chatMessage) => _handleSendSuccess(
        userMessage: userMessage,
        aiMessage: chatMessage,
      ),
    );

    setState(() {
      typingUsers.remove(Constants.ai);
    });
  }

  void _handleOnSendPressed(ChatMessage textMessage) async {
    final userMessage = textMessage.copyWith(
      user: Constants.user,
      createdAt: DateTime.now(),
    );

    _addUserMessage(userMessage);

    setState(() {
      typingUsers.add(Constants.ai);
    });

    final response = await _chatRepository.sendTextMessage(userMessage);

    response.fold<void>(
      (error) => _handleSendError(error: error, userMessage: userMessage),
      (chatMessage) => _handleSendSuccess(
        userMessage: userMessage,
        aiMessage: chatMessage,
      ),
    );

    setState(() {
      typingUsers.remove(Constants.ai);
    });
  }

  void _addUserMessage(ChatMessage message) {
    setState(() {
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
