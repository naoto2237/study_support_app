// ======================================================================
// 【データの形】AIチャットのメッセージ1件分
//
// 主なクラス: AiChatMessage
// ・AIサポート画面（ai_screen.dart）と履歴チャット画面（ai_history_chat_screen.dart）で共通
// ======================================================================

class AiChatMessage {
  final bool isUser;
  final String text;

  // うまくいかなかったことを知らせる文（「AIにつながりませんでした」など）。
  // AIの答えではないので、会話の続きとして AI には送らない
  final bool isError;

  AiChatMessage({
    required this.isUser,
    required this.text,
    this.isError = false,
  });
}
