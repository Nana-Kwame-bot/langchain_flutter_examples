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
    baseUrl: AzureConstants.azureOpenaiChatCompletionProxy,
    headers: {"X-Firebase-AppCheck": "debug"},
    defaultOptions: const ChatOpenAIOptions(
      model: "gpt-4o",
      temperature: 0,
    ),
  );

  static final memory = ConversationSummaryMemory(
    llm: chatModel,
    aiPrefix: Constants.ai.firstName ?? AIChatMessage.defaultPrefix,
    humanPrefix: Constants.user.firstName ?? HumanChatMessage.defaultPrefix,
  );

  Future<Either<String, DashChatMessage>> sendImageMessage(
    DashChatMessage chatMessage,
  ) async {
    final medias = chatMessage.medias ?? <DashChatMedia>[];

    final mediaContents = <ChatMessageContent>[];

    try {
      if (medias.isNotEmpty) {
        for (final DashChatMedia(:url, :customProperties) in medias) {
          final isExternal = Uri.tryParse(url)?.hasScheme ?? false;
          final data =
              isExternal ? url : base64Encode(File(url).readAsBytesSync());
          mediaContents.add(
            ChatMessageContent.image(
              mimeType: customProperties?["mimeType"] ?? "image/jpeg",
              data: data,
            ),
          );
        }
      }

      final history = await memory.loadMemoryVariables();

      debugPrint("history: $history");

      var humanMessage = chatMessage.text;

      final prompt = PromptValue.chat([
        ChatMessage.system(
          """
          You are Dash, the helpful and creative mascot of Flutter. 
          Be enthusiastic, engaging, and resourceful. 
          Prioritize concise, developer-friendly responses. 
          Use Flutter-specific terminology and examples where relevant. 
          For technical topics, offer clear, step-by-step guidance.

          This is the history of the conversation so far:
          $history
          """,
        ),
        ChatMessage.human(
          ChatMessageContent.multiModal([
            ChatMessageContent.text(humanMessage),
            ...mediaContents,
          ]),
        ),
      ]);

      final chain = chatModel.pipe(const StringOutputParser());

      final response = await chain.invoke(prompt);

      debugPrint("response: $response");

      await memory.saveContext(
        inputValues: {"input": humanMessage},
        outputValues: {"output": response},
      );

      return Right(
        DashChatMessage(
          user: Constants.ai,
          createdAt: DateTime.now(),
          text: response,
        ),
      );
    } on Exception catch (error, stackTrace) {
      debugPrint("sendImageMessage error: $error, stackTrace: $stackTrace");

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
      final history = await memory.loadMemoryVariables();

      debugPrint("history: $history");

      var humanMessage = chatMessage.text;

      final prompt = PromptValue.chat([
        ChatMessage.system(
          """
          You are Dash, the helpful and creative mascot of Flutter. 
          Be enthusiastic, engaging, and resourceful. 
          Prioritize concise, developer-friendly responses. 
          Use Flutter-specific terminology and examples where relevant. 
          For technical topics, offer clear, step-by-step guidance.

          This is the history of the conversation so far:
          $history
          """,
        ),
        ChatMessage.human(
          ChatMessageContent.text(humanMessage),
        ),
      ]);

      final chain = chatModel.pipe(const StringOutputParser());

      final response = await chain.invoke(prompt);

      debugPrint("response: $response");

      await memory.saveContext(
        inputValues: {"input": humanMessage},
        outputValues: {"output": response},
      );

      return Right(
        DashChatMessage(
          user: Constants.ai,
          createdAt: DateTime.now(),
          text: response,
        ),
      );
    } on Exception catch (error, stackTrace) {
      debugPrint("sendTextMessage error: $error, stackTrace: $stackTrace");

      if (error is OpenAIClientException) {
        return Left(error.message);
      }

      return Left("Something went wrong. Try again Later.");
    }
  }
}
