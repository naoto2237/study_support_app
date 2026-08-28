import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'friend_request_notification.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // ログインしていない場合
    if (user == null) {
      return const Scaffold(body: Center(child: Text('ログインしてください')));
    }

    return Scaffold(
      backgroundColor: Color(0xFFF7F7F7),

      appBar: AppBar(
        title: Transform.translate(
          offset: const Offset(-19, 0),
          child: const Text(
            '通知',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        backgroundColor: Colors.white,

        // 左上の戻る矢印を黒にする
        iconTheme: const IconThemeData(
          color: Colors.black87,
        ),
      ),

      // =====================================================
      // 友達申請 + 承認通知を取得
      // =====================================================
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('friend_requests')
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, requestSnapshot) {
          if (requestSnapshot.hasError) {
            return const Center(child: Text('通知の取得に失敗しました'));
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('notifications')
                .orderBy('createdAt', descending: true)
                .snapshots(),

            builder: (context, notificationSnapshot) {
              // 読み込み中
              if (requestSnapshot.connectionState == ConnectionState.waiting ||
                  notificationSnapshot.connectionState ==
                      ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (notificationSnapshot.hasError) {
                return const Center(child: Text('通知の取得に失敗しました'));
              }

              final requestDocs = requestSnapshot.data?.docs ?? [];

              final notificationDocs = notificationSnapshot.data?.docs ?? [];

              // =============================================
              // 通知なし
              // =============================================
              if (requestDocs.isEmpty && notificationDocs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 60,
                        color: Colors.grey,
                      ),

                      SizedBox(height: 12),

                      Text(
                        '通知はありません',
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ],
                  ),
                );
              }

              // =============================================
              // 友達申請と通知を1つのリストにまとめる
              // =============================================
              final allItems = <Map<String, dynamic>>[];

              // 友達申請
              for (final doc in requestDocs) {
                allItems.add({
                  'kind': 'friend_request',
                  'id': doc.id,
                  ...doc.data(),
                });
              }

              // 承認通知
              for (final doc in notificationDocs) {
                allItems.add({
                  'kind': 'notification',
                  'id': doc.id,
                  ...doc.data(),
                });
              }

              // =============================================
              // 新しい通知順に並び替える
              // =============================================
              allItems.sort((a, b) {
                final aTime = a['createdAt'];
                final bTime = b['createdAt'];

                if (aTime is Timestamp && bTime is Timestamp) {
                  return bTime.compareTo(aTime);
                }

                return 0;
              });

              return ListView.separated(
                itemCount: allItems.length,

                separatorBuilder: (_, __) {
                  return Divider(height: 1, color: Colors.grey.shade200);
                },

                itemBuilder: (context, index) {
                  final item = allItems[index];

                  // ここで kind を取得
                  final kind = item['kind'];

                  // =========================================
                  // 友達申請
                  // =========================================
                  if (kind == 'friend_request') {
                    return FriendRequestNotification(
                      requestId: item['id'] ?? '',
                      senderId: item['senderId'] ?? '',
                      senderName: item['senderName'] ?? 'ユーザー',
                      senderIcon: item['senderIcon'] ?? '',
                      status: item['status'] ?? 'pending',
                    );
                  }

                  // =========================================
                  // 友達申請が承認された通知
                  // =========================================
                  if (item['type'] == 'friend_accepted') {
                    return _FriendAcceptedTile(
                      userId: item['userId'] ?? '',
                      userName: item['userName'] ?? 'ユーザー',
                      userIcon: item['userIcon'] ?? '',
                      message: item['message'] ?? '',
                    );
                  }

                  return const SizedBox.shrink();
                },
              );
            },
          );
        },
      ),
    );
  }
}

// =========================================================
// 友達申請が承認された通知
// =========================================================

class _FriendAcceptedTile extends StatelessWidget {
  final String userId;
  final String userName;
  final String userIcon;
  final String message;

  const _FriendAcceptedTile({
    required this.userId,
    required this.userName,
    required this.userIcon,
    required this.message,
  });

  // =========================================================
  // プロフィールアイコン
  // =========================================================
  Widget _buildProfileIcon() {
    if (userIcon.isNotEmpty) {
      return CircleAvatar(radius: 24, backgroundImage: NetworkImage(userIcon));
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFF258EDB).withOpacity(0.12),
      child: const Icon(Icons.person, size: 27, color: Color(0xFF258EDB)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFF1F8FF),

      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          // 相手のアイコン
          _buildProfileIcon(),

          const SizedBox(width: 13),

          // 通知内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  '友達になりました',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 4),

                Text(
                  message.isNotEmpty ? message : '$userNameさんが友達申請を承認しました',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
