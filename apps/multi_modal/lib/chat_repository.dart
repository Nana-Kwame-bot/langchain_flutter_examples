import "dart:convert";
import "dart:io";
import "package:dash_chat_2/dash_chat_2.dart" as dash_chat;
import "package:flutter/foundation.dart";
import "package:langchain/langchain.dart";
import "package:langchain_openai/langchain_openai.dart";
import "package:multi_modal/azure_constants.dart";
import "package:multi_modal/constants.dart";
import "package:multi_modal/utils/either.dart";

typedef DashChatMessage = dash_chat.ChatMessage;
typedef DashChatMedia = dash_chat.ChatMedia;
typedef DashMediaType = dash_chat.MediaType;

class ChatRepository {
  const ChatRepository();

  static final chatModel = ChatOpenAI(
    // apiKey: Platform.environment["OPENAI_API_KEY"],
    baseUrl: AzureConstants.azureOpenaiChatCompletionProxy,
    headers: {"X-Firebase-AppCheck": "debug"},
    defaultOptions: const ChatOpenAIOptions(
      model: "gpt-4o",
      temperature: 0,
    ),
  );

  Future<Either<String, DashChatMessage>> sendImageMessage(
    DashChatMessage chatMessage,
  ) async {
    final medias = chatMessage.medias ?? <DashChatMedia>[];

    final mediaContents = <ChatMessageContent>[];

    try {
      if (medias.isNotEmpty) {
        for (final DashChatMedia(:url) in medias) {
          final isExternal = Uri.tryParse(url)?.hasScheme ?? false;
          final data =
              isExternal ? url : base64Encode(File(url).readAsBytesSync());
          mediaContents.add(
            ChatMessageContent.image(
              mimeType: "image/jpeg",
              data: data,
            ),
          );
        }
      }

      final prompt = PromptValue.chat([
        ChatMessage.system("You are a helpful assistant."),
        ChatMessage.human(
          ChatMessageContent.multiModal([
            ChatMessageContent.text(chatMessage.text),
            ...mediaContents,
          ]),
        ),
      ]);

      final chain = chatModel.pipe(const StringOutputParser());

      final response = await chain.invoke(prompt);

      debugPrint("response: $response");

      return Right(
        DashChatMessage(
          user: Constants.ai,
          createdAt: DateTime.now(),
          text: response,
        ),
      );
    } on Exception catch (error, stackTrace) {
      debugPrint("handleOnSend error: $error, stackTrace: $stackTrace");

      if (error is OpenAIClientException) {
        return Left(error.message);
      }

      return Left("Something went wrong. Try again Later.");
    }
  }

  Future<Either<String, DashChatMessage>> sendTextMessage(
    DashChatMessage chatMessage,
  ) async {
    try {
      final prompt = PromptValue.chat([
        ChatMessage.system("You are a helpful assistant."),
        ChatMessage.human(
          ChatMessageContent.text(chatMessage.text),
        ),
      ]);

      final chain = chatModel.pipe(const StringOutputParser());

      final response = await chain.invoke(prompt);

      debugPrint("response: $response");

      return Right(
        DashChatMessage(
          user: Constants.ai,
          createdAt: DateTime.now(),
          text: response,
        ),
      );
    } on Exception catch (error, stackTrace) {
      debugPrint("handleOnSend error: $error, stackTrace: $stackTrace");

      if (error is OpenAIClientException) {
        return Left(error.message);
      }

      return Left("Something went wrong. Try again Later.");
    }
  }
}
