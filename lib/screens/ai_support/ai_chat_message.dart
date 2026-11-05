// ======================================================================
// 【データの形】AIチャットのメッセージ1件分
//
// 主なクラス: AiChatMessage
// ・AIサポート画面（ai_screen.dart）と履歴チャット画面（ai_history_chat_screen.dart）で共通
// ======================================================================

class AiChatMessage {
  final bool isUser;
  final String text;

  AiChatMessage({required this.isUser, required this.text});
}
