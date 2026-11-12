// ======================================================================
// 【部品】AIチャットの会話の表示（質問の吹き出し・AIの回答・回答待ち）
//
// 主なクラス: AiChatMessageList
// 表示される場所: AIサポート画面（ai_screen.dart）と
//               履歴チャット画面（ai_history_chat_screen.dart）
// ・質問は右寄せの青い吹き出し
// ・AIの回答は背景の上に文字だけで表示（文字は選べる。下にコピーボタン）
// ・回答を待っているあいだは、点が跳ねる
// ======================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jumping_dot/jumping_dot.dart';
import 'package:study_support_app/screens/ai_support/ai_chat_message.dart';
import 'package:study_support_app/theme/app_colors.dart';

class AiChatMessageList extends StatelessWidget {
  final List<AiChatMessage> messages;
  final bool isLoading;

  const AiChatMessageList({
    super.key,
    required this.messages,
    required this.isLoading,
  });

  static const Color _blue = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final message in messages)
          message.isUser
              ? _UserBubble(text: message.text)
              : _AiAnswer(text: message.text),

        if (isLoading) const _TypingIndicator(),
      ],
    );
  }
}

// ======================================================================
// 質問（右寄せの青い吹き出し）
// ======================================================================
class _UserBubble extends StatelessWidget {
  final String text;

  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: const EdgeInsets.only(top: 4, bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: AiChatMessageList._blue,
            borderRadius: BorderRadius.only(
              // 右上の角だけ小さく丸めて、吹き出しの「とがり」を上に付ける
              topLeft: Radius.circular(18),
              topRight: Radius.circular(6),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
          ),
          // 指でなぞって選べる。青い吹き出しの上でも見えるよう、
          // 選んだ部分は半透明の白、つまみは白にする
          child: Theme(
            data: Theme.of(context).copyWith(
              textSelectionTheme: TextSelectionThemeData(
                selectionColor: Colors.white.withValues(alpha: 0.35),
                selectionHandleColor: Colors.white,
                cursorColor: Colors.white,
              ),
            ),
            child: SelectableText(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ======================================================================
// AIの回答（背景の上に文字だけで表示し、下にコピーボタン）
// ======================================================================
class _AiAnswer extends StatelessWidget {
  final String text;

  const _AiAnswer({required this.text});

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 指でなぞって、一部だけ選んでコピーもできる
          SelectableText(
            text,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 15,
              height: 1.6,
            ),
          ),

          // コピー
          Transform.translate(
            offset: const Offset(-6, 0),
            child: TextButton.icon(
              onPressed: _copy,
              style: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.white60 : Colors.black45,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.content_copy_outlined, size: 16),
              label: const Text("コピー", style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// 回答待ち（点が跳ねる）
// ======================================================================
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 14),
      child: Row(
        children: [
          JumpingDots(
            color: AiChatMessageList._blue,
            radius: 5,
            numberOfDots: 3,
            animationDuration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}
