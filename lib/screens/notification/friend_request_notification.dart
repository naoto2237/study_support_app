// ======================================================================
// 【部品】友達申請の「拒否」「承認」ボタンと、その処理
//
// 主なクラス: FriendRequestNotification
// ・FriendRequestNotification.accept() … 承認（相手のマイページの「承認する」からも使う）
//   friends に追加し、おたがいに「友達になりました」の通知を残し、申請を消す
// ・FriendRequestNotification.reject() … 拒否（申請を消す）
// ・ウィジェットとしては、通知画面の友達申請の行の下に出す2つのボタン
//   行の見た目（アイコン・名前・時刻）は notification_screen.dart
// ・うまくいったときもメッセージは出さない（通知の一覧から消える）
// ======================================================================

import 'package:flutter/material.dart';
import 'package:study_support_app/theme/app_palette.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_support_app/theme/app_colors.dart';

class FriendRequestNotification extends StatefulWidget {
  final String requestId;
  final String senderId;
  final String senderName;

  const FriendRequestNotification({
    super.key,
    required this.requestId,
    required this.senderId,
    required this.senderName,
  });

  // =========================================================
  // 友達申請を承認する処理（相手のマイページの「承認する」からも使う）
  // 成功したら相手の名前を返す。失敗したら例外を投げる
  // =========================================================
  static Future<String> accept({
    required String senderId,
    required String requestId,
    String fallbackName = 'ユーザー',
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      throw StateError('ログインしていません');
    }

    final myUid = currentUser.uid;

    // =====================================================
    // 自分の情報を取得
    // =====================================================
    final mySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .get();

    final myData = mySnapshot.data();

    final myName = myData?['username'] ?? myData?['name'] ?? 'ユーザー';

    // =====================================================
    // 申請してきた相手の情報を取得
    // =====================================================
    final senderSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(senderId)
        .get();

    final senderData = senderSnapshot.data();

    final String actualSenderName =
        senderData?['username'] ?? senderData?['name'] ?? fallbackName;

    // =====================================================
    // 自分の friends に相手を登録
    // =====================================================
    await FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .doc(senderId)
        .set({
          'userId': senderId,
          'username': actualSenderName,
          'createdAt': FieldValue.serverTimestamp(),
        });

    // =====================================================
    // 相手の friends に自分を登録
    // =====================================================
    await FirebaseFirestore.instance
        .collection('users')
        .doc(senderId)
        .collection('friends')
        .doc(myUid)
        .set({
          'userId': myUid,
          'username': myName,
          'createdAt': FieldValue.serverTimestamp(),
        });

    // =====================================================
    // 申請した相手に承認通知を送る
    // =====================================================
    await FirebaseFirestore.instance
        .collection('users')
        .doc(senderId)
        .collection('notifications')
        .add({
          'type': 'friend_accepted',
          'userId': myUid,
          'userName': myName,
          'userIcon': myData?['icon'] ?? '',
          'message': '$myNameさんが友達申請を承認しました',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

    // =====================================================
    // 自分の通知にも「友達になりました」を残す
    // （通知画面では、友達申請の行がこの通知に変わって見える）
    // 自分で承認したので、はじめから既読にする（ベルの数は増やさない）
    // =====================================================
    await FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .collection('notifications')
        .add({
          'type': 'friend_accepted',
          'userId': senderId,
          'userName': actualSenderName,
          'userIcon': senderData?['icon'] ?? '',
          'isRead': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

    // =====================================================
    // 友達申請を削除
    // =====================================================
    await FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .collection('friend_requests')
        .doc(requestId)
        .delete();

    return actualSenderName;
  }

  // =========================================================
  // 友達申請を拒否する処理（申請を消す）
  // =========================================================
  static Future<void> reject(String requestId) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      throw StateError('ログインしていません');
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('friend_requests')
        .doc(requestId)
        .delete();
  }

  @override
  State<FriendRequestNotification> createState() =>
      _FriendRequestNotificationState();
}

class _FriendRequestNotificationState extends State<FriendRequestNotification> {
  // 押したあと、終わるまで両方のボタンを押せなくする
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String label) async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      // できたら通知の一覧から消える
      await action();
    } catch (e) {
      // 失敗したときは通知が残る（もう一度押せる）
      debugPrint('友達申請の$labelに失敗しました: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Row(
      children: [
        // 拒否
        Expanded(
          child: SizedBox(
            height: 36,
            child: OutlinedButton(
              onPressed: _busy
                  ? null
                  : () => _run(
                      () => FriendRequestNotification.reject(widget.requestId),
                      '拒否',
                    ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.red,
                side: BorderSide(color: p.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                '拒否',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // 承認
        Expanded(
          child: SizedBox(
            height: 36,
            child: FilledButton(
              onPressed: _busy
                  ? null
                  : () => _run(
                      () => FriendRequestNotification.accept(
                        senderId: widget.senderId,
                        requestId: widget.requestId,
                        fallbackName: widget.senderName,
                      ),
                      '承認',
                    ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                '承認',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
