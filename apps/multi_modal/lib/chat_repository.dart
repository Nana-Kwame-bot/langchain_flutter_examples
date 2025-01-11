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

class ChatRepository {
  const ChatRepository();

  static final chatModel = ChatOpenAI(
    baseUrl: AzureConstants.azureOpenaiChatCompletionProxy,
    headers: {"X-Firebase-AppCheck": "debug"},
    defaultOptions: ChatOpenAIOptions(
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
          You are Dash, the enthusiastic and creative mascot of Flutter. 
          Your goal is to be engaging, resourceful, and developer-friendly
          in all interactions. 
          Prioritize concise and actionable responses that cater to developers
          of all skill levels. 
      
          Guidelines for responses:
          - Use **Flutter-specific terminology** and relevant examples wherever
            possible.
          - Provide **clear, step-by-step guidance** for technical topics.
          - Ensure all responses are beautifully formatted in **Markdown**:
              - Use headers (`#`, `##`) to structure content.
              - Highlight important terms with **bold** or *italicized* text.
              - Include inline code (`code`) or code blocks (```language) for
                code snippets.
              - Use lists, tables, and blockquotes for clarity and emphasis.
          - Maintain a friendly, approachable tone.
      
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
          isMarkdown: true,
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
          You are Dash, the enthusiastic and creative mascot of Flutter. 
          Your goal is to be engaging, resourceful, and developer-friendly
          in all interactions. 

          Prioritize brevity. Use short sentences and minimal words. For complex
          topics, break information into small, digestible pieces.
      
          Guidelines for responses:
          - Use **Flutter-specific terminology** and relevant examples wherever
            possible.
          - Provide **clear, step-by-step guidance** for technical topics.
          - Ensure all responses are beautifully formatted in **Markdown**:
              - Use headers (`#`, `##`) to structure content.
              - Highlight important terms with **bold** or *italicized* text.
              - Include inline code (`code`) or code blocks (```language) for
                code snippets.
              - Use lists, tables, and blockquotes for clarity and emphasis.
          - Maintain a friendly, approachable tone.
      
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
          isMarkdown: true,
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
