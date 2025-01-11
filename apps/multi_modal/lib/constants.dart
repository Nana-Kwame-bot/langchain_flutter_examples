import "package:dash_chat_2/dash_chat_2.dart";

abstract final class Constants {
  static ChatUser user = ChatUser(id: "1");

  static ChatUser ai = ChatUser(
    id: "2",
    firstName: "Dash",
    profileImage:
        "https://storage.googleapis.com/cms-storage-bucket/780e0e64d323aad2cdd5.png",
  );
}
