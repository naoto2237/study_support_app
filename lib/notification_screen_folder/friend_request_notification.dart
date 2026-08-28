import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendRequestNotification extends StatelessWidget {
  final String requestId;
  final String senderId;
  final String senderName;
  final String senderIcon;
  final String status;

  const FriendRequestNotification({
    super.key,
    required this.requestId,
    required this.senderId,
    required this.senderName,
    required this.senderIcon,
    required this.status,
  });

  // =========================================================
  // 友達申請を承認
  // =========================================================
  Future<void> _acceptFriendRequest(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    final myUid = currentUser.uid;

    try {
      // =====================================================
      // 自分の情報を取得
      // =====================================================
      final mySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .get();

      final myData = mySnapshot.data();

      final myName =
          myData?['username'] ??
              myData?['name'] ??
              'ユーザー';

      // =====================================================
      // 申請してきた相手の情報を取得
      // =====================================================
      final senderSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .get();

      final senderData = senderSnapshot.data();

      final actualSenderName =
          senderData?['username'] ??
              senderData?['name'] ??
              senderName;

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
      // 友達申請を削除
      // =====================================================
      await FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .collection('friend_requests')
          .doc(requestId)
          .delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$actualSenderNameさんと友達になりました'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('友達申請の承認に失敗しました'),
        ),
      );
    }
  }

  // =========================================================
  // 友達申請を拒否
  // =========================================================
  Future<void> _rejectFriendRequest(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('friend_requests')
          .doc(requestId)
          .delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('友達申請を拒否しました'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('友達申請の拒否に失敗しました'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'pending';

    return Container(
      color: const Color(0xFFF1F8FF),


      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),

      child: Row(
        children: [
          // =================================================
          // 相手のアイコン
          // =================================================
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF258EDB).withOpacity(0.12),

            backgroundImage: senderIcon.isNotEmpty
                ? NetworkImage(senderIcon)
                : null,

            child: senderIcon.isEmpty
                ? const Icon(
              Icons.person,
              color: Color(0xFF258EDB),
              size: 27,
            )
                : null,
          ),

          const SizedBox(width: 12),

          // =================================================
          // 名前・ボタン
          // =================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$senderNameさんから友達申請が届いています',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                if (isPending) ...[
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      // 拒否
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _rejectFriendRequest(context);
                          },
                          child: const Text('拒否'),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // 承認
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            _acceptFriendRequest(context);
                          },

                          style: FilledButton.styleFrom(
                            backgroundColor:
                            const Color(0xFF258EDB),
                          ),

                          child: const Text('承認'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}