// ======================================================================
// 【画面】新しいルームの作成
//
// 主なクラス: RoomMakingScreen
// 開き方: 「作成」タブ（create_room_tab.dart）
// ・ルームの情報を入力して rooms / members に保存し、ルームの中へ進む
// ・旧ファイル名: room_making.dart
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:study_support_app/screens/link/room/space/room_space_screen.dart';
import 'package:study_support_app/theme/app_colors.dart';

class RoomMakingScreen extends StatefulWidget {
  const RoomMakingScreen({super.key});

  @override
  State<RoomMakingScreen> createState() => _RoomMakingScreenState();
}

class _RoomMakingScreenState extends State<RoomMakingScreen> {
  // =========================================================
  // 0 = 全体公開
  // 1 = 非公開
  // =========================================================

  int _selectedVisibility = 0;

  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _descriptionController = TextEditingController();

  bool _isCreating = false;

  @override
  void initState() {
    super.initState();

    // 作成ボタンの押せる・押せないを、タイトルの入力に合わせて変える
    _titleController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // =========================================================
  // ルーム作成
  // =========================================================

  Future<void> _createRoom() async {
    // -------------------------------------------------------
    // タイトルチェック
    // -------------------------------------------------------

    final title = _titleController.text.trim();

    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("ルームタイトルを入力してください")));

      return;
    }

    try {
      setState(() {
        _isCreating = true;
      });

      // -----------------------------------------------------
      // ログインユーザー取得
      // -----------------------------------------------------

      User? user = FirebaseAuth.instance.currentUser;

      // ログインしていない場合は匿名ログイン
      if (user == null) {
        final credential = await FirebaseAuth.instance.signInAnonymously();

        user = credential.user;
      }

      if (user == null) {
        throw Exception("ユーザー情報を取得できませんでした");
      }

      // -----------------------------------------------------
      // roomsに追加
      // -----------------------------------------------------

      final roomRef = await FirebaseFirestore.instance.collection("rooms").add({
        "title": title,

        "description": description,

        // 0 = 公開
        // 1 = 非公開
        "isPublic": _selectedVisibility == 0,

        // ルームを作ったユーザー
        "ownerId": user.uid,

        // 作成日時
        "createdAt": FieldValue.serverTimestamp(),
      });

      // -----------------------------------------------------
      // 作成者をmembersに追加
      // -----------------------------------------------------

      await roomRef.collection("members").doc(user.uid).set({
        "joinedAt": FieldValue.serverTimestamp(),
      });

      // -----------------------------------------------------
      // 画面遷移
      // -----------------------------------------------------

      if (!context.mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RoomSpaceScreen(roomTitle: title, roomId: roomRef.id),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("ルームの作成に失敗しました\n$e")));
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  static const Color _blue = AppColors.primary;

  // 公開設定の1枚分のカード（押すと選ぶ。選んだカードは青い枠とチェック）
  Widget _buildVisibilityOption({
    required int value,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
  }) {
    final selected = _selectedVisibility == value;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          setState(() {
            _selectedVisibility = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? _blue : borderColor,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? (isDark
                            ? _blue.withValues(alpha: 0.2)
                            : AppColors.primarySoft)
                      : (isDark ? Colors.white10 : const Color(0xFFF2F3F5)),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: selected ? _blue : subtitleColor,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12.5, color: subtitleColor),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 選んでいるかどうかの丸
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? _blue : Colors.transparent,
                  border: Border.all(
                    color: selected ? _blue : borderColor,
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF121212) : AppColors.background;

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final textColor = isDark ? Colors.white70 : Colors.black87;

    final subtitleColor = isDark ? Colors.white60 : Colors.black45;

    final borderColor = isDark ? Colors.grey.shade800 : AppColors.border;

    final canCreate = _titleController.text.trim().isNotEmpty && !_isCreating;

    // 見出し（各入力欄の上）
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );

    // 白い角丸の入力欄（タイトルと説明で共通）
    InputDecoration fieldDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 14, height: 1.5, color: subtitleColor),
      filled: true,
      fillColor: cardColor,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _blue, width: 1.5),
      ),
    );

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },

      child: Scaffold(
        backgroundColor: bgColor,

        appBar: AppBar(
          backgroundColor: cardColor,
          foregroundColor: textColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          titleSpacing: 0,

          title: Text(
            "ルームを作る",

            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),

        body: SafeArea(
          child: Column(
            children: [
              // ==========================================
              // 入力欄（スクロールできる）
              // ==========================================
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(17, 14, 17, 16),

                  children: [
                    // ==========================================
                    // タイトル
                    // ==========================================
                    label("ルームのタイトル"),

                    TextField(
                      controller: _titleController,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      cursorColor: _blue,
                      textInputAction: TextInputAction.next,
                      decoration: fieldDecoration("例）TOEIC800点を目指す仲間のルーム"),
                    ),

                    const SizedBox(height: 20),

                    // ==========================================
                    // 説明
                    // ==========================================
                    label("ルームの説明（なくても作れます）"),

                    TextField(
                      controller: _descriptionController,
                      minLines: 4,
                      maxLines: 8,
                      keyboardType: TextInputType.multiline,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        height: 1.5,
                      ),
                      cursorColor: _blue,
                      decoration: fieldDecoration("このルームの目的や活動内容を書いてください"),
                    ),

                    const SizedBox(height: 24),

                    // ==========================================
                    // 公開設定（2枚のカードから選ぶ）
                    // ==========================================
                    label("公開設定"),

                    _buildVisibilityOption(
                      value: 0,
                      icon: Icons.public_rounded,
                      title: "全体公開",
                      subtitle: "すべてのユーザーが参加できます",
                      isDark: isDark,
                      cardColor: cardColor,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      borderColor: borderColor,
                    ),

                    const SizedBox(height: 10),

                    _buildVisibilityOption(
                      value: 1,
                      icon: Icons.lock_outline_rounded,
                      title: "非公開",
                      subtitle: "作成者と招待された人だけ参加できます",
                      isDark: isDark,
                      cardColor: cardColor,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      borderColor: borderColor,
                    ),
                  ],
                ),
              ),

              // ==========================================
              // 作成ボタン（下に固定。タイトルが空のときは押せない）
              // ==========================================
              Container(
                padding: const EdgeInsets.fromLTRB(17, 10, 17, 12),
                decoration: BoxDecoration(
                  color: cardColor,
                  border: Border(top: BorderSide(color: borderColor)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,

                  child: ElevatedButton(
                    onPressed: canCreate ? _createRoom : null,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _isCreating
                          ? _blue
                          : (isDark
                                ? Colors.grey.shade800
                                : const Color(0xFFE3E7EC)),
                      disabledForegroundColor: isDark
                          ? Colors.white38
                          : Colors.black38,
                      elevation: 0,
                      // 両端が丸いボタン
                      shape: const StadiumBorder(),
                    ),

                    child: _isCreating
                        ? const SizedBox(
                            width: 22,
                            height: 22,

                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            "ルームを作成する",

                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
