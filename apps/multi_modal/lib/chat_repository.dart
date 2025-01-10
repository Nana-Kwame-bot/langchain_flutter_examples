import "package:dash_chat_2/dash_chat_2.dart" as dash_chat;
import "package:flutter/foundation.dart";
import "package:langchain/langchain.dart";
import "package:langchain_openai/langchain_openai.dart";
import "package:multi_modal/azure_constants.dart";
import "package:multi_modal/constants.dart";

typedef DashChatMessage = dash_chat.ChatMessage;

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

  Future<DashChatMessage> handleOnSend(DashChatMessage chatMessage) async {
    final prompt = PromptValue.chat([
      ChatMessage.system("You are a helpful assistant."),
      ChatMessage.human(
        // ChatMessageContent.text(chatMessage.text),
        ChatMessageContent.multiModal([
          ChatMessageContent.text(chatMessage.text),
          ChatMessageContent.image(
            mimeType: "image/jpeg",
            data: Constants.dash,
          ),
        ]),
      ),
    ]);

    final chain = chatModel.pipe(const StringOutputParser());

    final response = await chain.invoke(prompt);

    debugPrint("response: $response");

    return DashChatMessage(
      user: Constants.ai,
      createdAt: DateTime.now(),
      text: response,
    );
  }
}
