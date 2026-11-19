// ======================================================================
// 【ダイアログ】友達申請を送る確認
//
// 主なクラス:
//   FriendRequestDialog（FriendRequestDialog.show(...) で表示）
//   FriendActionDialog（相手のアイコン・名前と、2つのボタンの確認ダイアログ）
// 開き方: 他の人のマイページの友達申請ボタン
// ・friend_requests に保存する
// ・ボタンの切りかえ（友達・申請中・承認する）は mypage_profile_section.dart の _FriendButton
//   「申請中」「承認する」を押したときの確認も FriendActionDialog を使う
// ・うまくいったときはメッセージを出さずに閉じる（ボタンの表示が変わる）
//   失敗したときは、ダイアログの中に赤い文字で出す
// ======================================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/theme/app_palette.dart';

class FriendRequestDialog {
  // =========================================================
  // 友達申請の確認画面を表示
  // =========================================================
  static Future<void> show(
    BuildContext context, {
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    // 自分自身には申請できない（自分のページにはボタンが出ないので、ふつうは来ない）
    if (currentUser == null || currentUser.uid == userId) return;

    await FriendActionDialog.show(
      context,
      data: data,
      title: '友達申請',
      message: '友達申請を送りますか？',
      okText: '申請を送る',
      errorText: '友達申請を送れませんでした',
      onOk: () => _send(currentUser.uid, userId),
    );
  }

  // =========================================================
  // 相手の friend_requests に保存
  //
  // users
  //   └── 相手UID
  //        └── friend_requests
  //             └── 自分UID
  // =========================================================
  static Future<void> _send(String myUid, String userId) async {
    // 申請する人のプロフィール情報を取得
    final currentUserData = await FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .get();

    final senderData = currentUserData.data();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friend_requests')
        .doc(myUid)
        .set({
          // 申請した人の情報
          'senderId': myUid,
          'senderName':
              senderData?['username'] ?? senderData?['name'] ?? 'ユーザー',
          'senderIcon': senderData?['icon'] ?? '',

          // 申請を受ける人
          'receiverId': userId,

          // 申請状態
          'status': 'pending',
          'isRead': false,

          // 申請日時
          'createdAt': FieldValue.serverTimestamp(),
        });
  }
}

// ======================================================
// 友達まわりの確認ダイアログ
// 上に相手のアイコン・名前・ID、その下に質問、いちばん下に2つのボタン
// ======================================================

class FriendActionDialog extends StatefulWidget {
  final Map<String, dynamic> data;
  final String title;
  final String message;
  final String okText;
  final String errorText;

  // やめる・取り消すなど「なくなる」操作のとき、見出しとボタンを赤にする
  final bool danger;
  final Future<void> Function() onOk;

  const FriendActionDialog({
    super.key,
    required this.data,
    required this.title,
    required this.message,
    required this.okText,
    required this.errorText,
    this.danger = false,
    required this.onOk,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> data,
    required String title,
    required String message,
    required String okText,
    required String errorText,
    bool danger = false,
    required Future<void> Function() onOk,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => FriendActionDialog(
        data: data,
        title: title,
        message: message,
        okText: okText,
        errorText: errorText,
        danger: danger,
        onOk: onOk,
      ),
    );
  }

  @override
  State<FriendActionDialog> createState() => _FriendActionDialogState();
}

class _FriendActionDialogState extends State<FriendActionDialog> {
  bool _sending = false;
  bool _failed = false;

  Future<void> _ok() async {
    setState(() {
      _sending = true;
      _failed = false;
    });

    try {
      await widget.onOk();

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _sending = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    final String name =
        (widget.data['name'] ?? widget.data['username'] ?? 'このユーザー').toString();
    final String id = (widget.data['userId'] ?? '').toString();
    final String icon = (widget.data['icon'] ?? '').toString();

    return Dialog(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 見出し
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: widget.danger ? AppColors.red : p.text,
              ),
            ),

            const SizedBox(height: 18),

            // 相手のアイコン
            CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.primarySoft,
              backgroundImage: icon.isNotEmpty ? NetworkImage(icon) : null,
              child: icon.isEmpty
                  ? const Icon(Icons.person, size: 38, color: AppColors.primary)
                  : null,
            ),

            const SizedBox(height: 10),

            // 相手の名前とID
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: p.text,
              ),
            ),
            if (id.isNotEmpty) ...[
              const SizedBox(height: 1),
              Text(id, style: TextStyle(fontSize: 13, color: p.secondary)),
            ],

            const SizedBox(height: 16),

            // 質問
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, height: 1.5, color: p.text),
            ),

            // 失敗したとき
            if (_failed) ...[
              const SizedBox(height: 8),
              Text(
                widget.errorText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.redAccent),
              ),
            ],

            const SizedBox(height: 20),

            // ボタン
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: _sending ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: p.secondary,
                        side: BorderSide(color: p.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'キャンセル',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: FilledButton(
                      onPressed: _sending ? null : _ok,
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.danger
                            ? AppColors.red
                            : AppColors.primary,
                        disabledBackgroundColor:
                            (widget.danger ? AppColors.red : AppColors.primary)
                                .withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.okText,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
