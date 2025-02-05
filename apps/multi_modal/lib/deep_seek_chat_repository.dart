import "dart:convert";
import "dart:io";
import "package:dash_chat_2/dash_chat_2.dart" as dash_chat;
import "package:flutter/foundation.dart";
import "package:langchain/langchain.dart";
import "package:langchain_google/langchain_google.dart";
import "package:langchain_openai/langchain_openai.dart";
import "package:multi_modal/constants.dart";
import "package:multi_modal/utils/either.dart";

typedef DashChatMessage = dash_chat.ChatMessage;
typedef DashChatMedia = dash_chat.ChatMedia;

class DeepSeekChatRepository {
  const DeepSeekChatRepository();

  static const calendarToolSpec = ToolSpec(
    name: "createCalendarICS",
    description: "Creates an ICS (iCalendar) file for calendar events",
    inputJsonSchema: {
      "type": "object",
      "properties": {
        "events": {
          "type": "array",
          "description": "Array of calendar events to create",
          "items": {
            "type": "object",
            "properties": {
              "summary": {
                "type": "string",
                "description": "Title of the calendar event",
              },
              "startDate": {
                "type": "string",
                "description": "Start date in YYYY-MM-DD format",
              },
              "startTime": {
                "type": "string",
                "description": "Start time in HH:mm format (24-hour)",
              },
              "duration": {
                "type": "integer",
                "description": "Duration in minutes",
              },
              "timeZone": {
                "type": "string",
                "description":
                    'Time zone identifier (e.g., "America/Los_Angeles")',
              }
            },
            "required": [
              "summary",
              "startDate",
              "startTime",
              "duration",
              "timeZone"
            ],
          },
        },
      },
      "required": ["events"],
    },
  );

  static final chatModel = ChatOpenAI(
    baseUrl: "https://models.inference.ai.azure.com",
    headers: {
      "Authorization": "Bearer ${Platform.environment["GITHUB_TOKEN"]}",
      "Content-Type": "application/json",
    },
    defaultOptions: ChatOpenAIOptions(
      tools: [calendarToolSpec],
      toolChoice: ChatToolChoice.auto,
      model: "DeepSeek-R1",
      temperature: 0,
    ),
  );

  static final memory = ConversationBufferWindowMemory(
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

      var chatMessages = history["history"];

      if (chatMessages is! List<ChatMessage>) {
        chatMessages = <ChatMessage>[];
      }

      debugPrint("history: ${history.runtimeType}");

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
          """,
        ),
        ...chatMessages,
        ChatMessage.human(
          ChatMessageContent.multiModal([
            ChatMessageContent.text(humanMessage),
            ...mediaContents,
          ]),
        ),
      ]);

      final response = await chatModel.invoke(prompt);

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
          text: response.outputAsString,
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
      if (kDebugMode) {
        print("All Environment Variables: ${Platform.environment}");
      }
      if (kDebugMode) {
        print("GITHUB_TOKEN: ${Platform.environment["GITHUB_TOKEN"]}");
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

      final response = await chatModel.invoke(prompt);

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
          text: response.outputAsString,
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
