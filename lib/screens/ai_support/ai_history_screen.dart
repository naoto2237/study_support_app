// ======================================================================
// 【画面】AIチャットの履歴一覧
//
// 主なクラス: AiHistoryScreen
// 開き方: AIサポート画面の履歴ボタン
// ・過去の会話を一覧表示し、タップで続きを開く（ai_history_chat_screen.dart）
// ・行を長押しすると選択に切り替わり（その行が選ばれた状態）、ほかの行も選べる
// ・選んだ履歴は、右上のゴミ箱でまとめて消す（右上の「選択」からも選べる）
// ======================================================================

import 'package:flutter/material.dart';
import 'package:study_support_app/screens/ai_support/ai_history_chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_support_app/theme/app_colors.dart';

class AiHistoryScreen extends StatefulWidget {
  const AiHistoryScreen({super.key});

  @override
  State<AiHistoryScreen> createState() => _AiHistoryScreenState();
}

class _AiHistoryScreenState extends State<AiHistoryScreen> {
  static const Color _blue = AppColors.primary;
  static const Color _red = Color(0xFFE53935);

  // 選択の状態か
  bool _isSelecting = false;

  // 選んでいる履歴のID
  final Set<String> _selectedIds = {};

  // 削除中の履歴のID（データが消えるまでの間も、一覧からすぐ隠す）
  final Set<String> _hiddenIds = {};

  // =========================================================
  // 履歴を1件削除（中の会話 messages も一緒に消す）
  // =========================================================
  Future<void> _deleteHistory(DocumentReference historyRef) async {
    // =========================================
    // サブコレクション messages を取得
    // =========================================
    final messagesSnapshot = await historyRef.collection('messages').get();

    // =========================================
    // メッセージを削除
    // =========================================
    for (final messageDoc in messagesSnapshot.docs) {
      await messageDoc.reference.delete();
    }

    // =========================================
    // 履歴本体を削除
    // =========================================
    await historyRef.delete();
  }

  // =========================================================
  // 選んだ履歴をまとめて削除
  // =========================================================
  Future<void> _deleteSelected(String userId) async {
    final historyCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('ai_history');

    final ids = _selectedIds.toList();

    // 先に一覧から隠し、選択の状態も終える
    setState(() {
      _hiddenIds.addAll(ids);
      _selectedIds.clear();
      _isSelecting = false;
    });

    for (final id in ids) {
      await _deleteHistory(historyCollection.doc(id));
    }
  }

  // =========================================================
  // 削除の確認（「削除する」を押したときだけ true）
  // =========================================================
  Future<bool> _confirmDelete(int count) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    final result = await showDialog<bool>(
      context: context,

      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,

        title: Text(
          count == 1 ? "履歴を削除" : "$count件の履歴を削除",
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        content: Text(
          "削除すると元に戻せません。",
          style: TextStyle(color: textColor, height: 1.5),
        ),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },

            style: TextButton.styleFrom(foregroundColor: _blue),

            child: const Text("キャンセル"),
          ),

          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },

            style: FilledButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
            ),

            child: const Text("削除する"),
          ),
        ],
      ),
    );

    return result == true;
  }

  void _startSelecting([String? firstId]) {
    setState(() {
      _isSelecting = true;
      if (firstId != null) _selectedIds.add(firstId);
    });
  }

  void _stopSelecting() {
    setState(() {
      _isSelecting = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelected(String id) {
    setState(() {
      if (!_selectedIds.remove(id)) {
        _selectedIds.add(id);
      }
    });
  }

  // =========================================================
  // 日時の表示（今日：17:01、昨日：昨日、それ以前：11/3、去年以前：2025/11/3）
  // =========================================================
  String _formatDate(dynamic value) {
    if (value is! Timestamp) return '';

    final date = value.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;

    if (diff == 0) {
      final h = date.hour.toString().padLeft(2, '0');
      final m = date.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    if (diff == 1) return '昨日';
    if (date.year == now.year) return '${date.month}/${date.day}';
    return '${date.year}/${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    // =========================================================
    // 現在ログインしているユーザー
    // =========================================================
    final user = FirebaseAuth.instance.currentUser;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF121212) : AppColors.background;

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final textColor = isDark ? Colors.white70 : Colors.black87;

    final subTextColor = isDark ? Colors.white54 : Colors.black45;

    final borderColor = isDark ? Colors.grey.shade800 : AppColors.border;

    final dividerColor = isDark ? Colors.grey.shade800 : AppColors.divider;

    // =========================================================
    // ログインしていない場合
    // =========================================================
    if (user == null) {
      return Scaffold(
        backgroundColor: bgColor,

        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,

          title: Text(
            "履歴",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 19,
              color: textColor,
            ),
          ),
        ),

        body: Center(
          child: Text("ログインしてください", style: TextStyle(color: textColor)),
        ),
      );
    }

    // =========================================================
    // 履歴画面（選択中は、戻る操作で選択をやめる）
    // =========================================================
    return PopScope(
      canPop: !_isSelecting,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSelecting) _stopSelecting();
      },
      child: Scaffold(
        backgroundColor: bgColor,

        appBar: _isSelecting
            ? _buildSelectingAppBar(
                userId: user.uid,
                cardColor: cardColor,
                textColor: textColor,
              )
            : _buildNormalAppBar(cardColor: cardColor, textColor: textColor),

        // =========================================================
        // 自分のAI履歴を取得
        // =========================================================
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('ai_history')
              .orderBy('updatedAt', descending: true)
              .snapshots(),

          builder: (context, snapshot) {
            // エラー
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "履歴を読み込めませんでした",
                  style: TextStyle(color: textColor),
                ),
              );
            }

            // 読み込み中
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs
                .where((doc) => !_hiddenIds.contains(doc.id))
                .toList();

            // 履歴なし
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? _blue.withValues(alpha: 0.18)
                            : AppColors.primarySoft,
                      ),
                      child: const Icon(
                        Icons.forum_outlined,
                        color: _blue,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "まだ会話の履歴はありません",
                      style: TextStyle(fontSize: 15, color: textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "AIに質問すると、ここに残ります",
                      style: TextStyle(fontSize: 12.5, color: subTextColor),
                    ),
                  ],
                ),
              );
            }

            // =====================================================
            // 履歴一覧（1つのカードにまとめ、行の間を線で区切る）
            // =====================================================
            return ListView(
              padding: const EdgeInsets.fromLTRB(17, 14, 17, 24),

              children: [
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                  ),

                  // 枠線は中身の上に描く（中の行の色で、角の枠線が隠れないように）
                  foregroundDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),

                  clipBehavior: Clip.antiAlias,

                  child: Column(
                    children: [
                      for (var index = 0; index < docs.length; index++) ...[
                        _buildHistoryRow(
                          doc: docs[index],
                          userId: user.uid,
                          isDark: isDark,
                          cardColor: cardColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        ),

                        if (index < docs.length - 1)
                          Container(
                            height: 1,
                            margin: const EdgeInsets.only(left: 64),
                            color: dividerColor,
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // =========================================================
  // ふだんの上部（戻る・「履歴」・「選択」）
  // =========================================================
  PreferredSizeWidget _buildNormalAppBar({
    required Color cardColor,
    required Color textColor,
  }) {
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: textColor),

        onPressed: () {
          FocusScope.of(context).unfocus();

          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),

      titleSpacing: 0,

      title: Text(
        "履歴",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 19,
          color: textColor,
        ),
      ),

      backgroundColor: cardColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,

      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            onPressed: () => _startSelecting(),
            style: TextButton.styleFrom(foregroundColor: _blue),
            child: const Text(
              "選択",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // 選択中の上部（×・「◯件選択中」・ゴミ箱）
  // =========================================================
  PreferredSizeWidget _buildSelectingAppBar({
    required String userId,
    required Color cardColor,
    required Color textColor,
  }) {
    final count = _selectedIds.length;

    return AppBar(
      leading: IconButton(
        tooltip: "選択をやめる",
        icon: Icon(Icons.close, color: textColor),
        onPressed: _stopSelecting,
      ),

      titleSpacing: 0,

      title: Text(
        count == 0 ? "削除する履歴を選択" : "$count件選択中",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: textColor,
        ),
      ),

      backgroundColor: cardColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,

      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 7),
          child: IconButton(
            tooltip: "選んだ履歴を削除",
            onPressed: count == 0
                ? null
                : () async {
                    if (await _confirmDelete(count)) {
                      await _deleteSelected(userId);
                    }
                  },
            icon: Icon(
              Icons.delete_outline,
              color: count == 0 ? textColor.withValues(alpha: 0.3) : _red,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // 履歴の1行
  // ・ふだん：押すと会話を開く／長押しで選択に切り替わる
  // ・選択中：押すと選ぶ・外す
  // =========================================================
  Widget _buildHistoryRow({
    required QueryDocumentSnapshot doc,
    required String userId,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    final date = _formatDate(data['updatedAt']);
    final isSelected = _selectedIds.contains(doc.id);

    return Material(
      color: isSelected
          ? (isDark ? _blue.withValues(alpha: 0.18) : AppColors.primarySoft)
          : cardColor,
      child: InkWell(
        onTap: () {
          if (_isSelecting) {
            _toggleSelected(doc.id);
            return;
          }

          Navigator.push(
            context,

            MaterialPageRoute(
              builder: (_) => AiHistoryChatScreen(
                chatId: doc.id,

                // ★ どのユーザーの履歴か渡す
                userId: userId,
              ),
            ),
          );
        },
        onLongPress: _isSelecting ? null : () => _startSelecting(doc.id),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: Row(
              children: [
                // 選択中は丸いチェック、ふだんは会話のアイコン
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: _isSelecting
                      ? Container(
                          key: const ValueKey('check'),
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? _blue : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? _blue
                                    : (isDark
                                          ? Colors.white38
                                          : Colors.black26),
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        )
                      : Container(
                          key: const ValueKey('icon'),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? _blue.withValues(alpha: 0.18)
                                : AppColors.primarySoft,
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            color: _blue,
                            size: 18,
                          ),
                        ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Text(
                    data['title'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),

                if (date.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    date,
                    style: TextStyle(fontSize: 12, color: subTextColor),
                  ),
                ],

                if (!_isSelecting) ...[
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: isDark ? Colors.white38 : Colors.black26,
                  ),
                ] else
                  const SizedBox(width: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
