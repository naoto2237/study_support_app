import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendRequestScreen {
  // =========================================================
  // 友達申請の確認画面を表示
  // =========================================================
  static Future<void> show(
    BuildContext context, {
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return;
    }

    // =========================================================
    // 自分自身には申請できない
    // =========================================================
    if (currentUser.uid == userId) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('自分自身には友達申請できません')));
      return;
    }

    final userName = data['username'] ?? data['name'] ?? 'このユーザー';

    bool isSending = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),

              title: const Text('友達申請', textAlign: TextAlign.center),

              content: Text(
                '$userNameさんに\n友達申請を送りますか？',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),

              actionsAlignment: MainAxisAlignment.center,

              actions: [
                // =================================================
                // キャンセル
                // =================================================
                TextButton(
                  onPressed: isSending
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('キャンセル'),
                ),

                // =================================================
                // 申請を送る
                // =================================================
                FilledButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          setDialogState(() {
                            isSending = true;
                          });

                          try {
                            // =====================================
                            // 申請する人のプロフィール情報を取得
                            // =====================================
                            final currentUserData = await FirebaseFirestore
                                .instance
                                .collection('users')
                                .doc(currentUser.uid)
                                .get();

                            final senderData = currentUserData.data();

                            // =====================================
                            // 相手の friend_requests に保存
                            //
                            // users
                            //   └── 相手UID
                            //        └── friend_requests
                            //             └── 自分UID
                            // =====================================
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .collection('friend_requests')
                                .doc(currentUser.uid)
                                .set({
                                  // 申請した人の情報
                                  'senderId': currentUser.uid,

                                  'senderName':
                                      senderData?['username'] ??
                                      senderData?['name'] ??
                                      'ユーザー',

                                  // ★ 申請した人のアイコン
                                  'senderIcon': senderData?['icon'] ?? '',

                                  // 申請を受ける人
                                  'receiverId': userId,

                                  // 申請状態
                                  'status': 'pending',
                                  'isRead': false,
                                  // 申請日時
                                  'createdAt': FieldValue.serverTimestamp(),
                                });

                            if (!dialogContext.mounted) return;

                            Navigator.pop(dialogContext);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('友達申請を送信しました')),
                            );
                          } catch (e) {
                            setDialogState(() {
                              isSending = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('友達申請の送信に失敗しました')),
                            );
                          }
                        },

                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF258EDB),
                  ),

                  child: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('申請を送る'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
