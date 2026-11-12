// ======================================================================
// 【画面】通知
//
// 主なクラス: NotificationScreen / _FriendAcceptedTile（友達になった通知）
// 開き方: ホーム・Link・学習記録などの上部の通知アイコン
// ・友達申請（friend_request_notification.dart）などを一覧表示
// ======================================================================

import 'package:flutter/material.dart';
import 'package:study_support_app/theme/app_palette.dart';
import 'package:study_support_app/theme/empty_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_support_app/screens/notification/friend_request_notification.dart';
import 'package:study_support_app/theme/app_colors.dart';

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
      backgroundColor: context.pal.page,

      appBar: AppBar(
        title: Transform.translate(
          offset: const Offset(-19, 0),
          child: Text(
            '通知',
            style: TextStyle(
              color: context.pal.text,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        backgroundColor: context.pal.card,

        // 左上の戻る矢印を黒にする
        iconTheme: IconThemeData(color: context.pal.text),
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
                return const EmptyMessage(
                  icon: Icons.notifications_none_rounded,
                  text: '通知はありません',
                  subText: '友達申請やお知らせが届くと、ここに表示されます',
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

                separatorBuilder: (_, _) {
                  return Divider(height: 1, color: context.pal.field);
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
      backgroundColor: AppColors.primarySoft,
      child: const Icon(Icons.person, size: 27, color: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.pal.primarySoft,

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
                  style: TextStyle(fontSize: 13, color: context.pal.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
