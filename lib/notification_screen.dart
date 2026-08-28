import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // ログインしていない場合
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('ログインしてください'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          '通知',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF258EDB),
        iconTheme: const IconThemeData(
          color: Colors.white,
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
            return const Center(
              child: Text('通知の取得に失敗しました'),
            );
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
              if (requestSnapshot.connectionState ==
                  ConnectionState.waiting ||
                  notificationSnapshot.connectionState ==
                      ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (notificationSnapshot.hasError) {
                return const Center(
                  child: Text('通知の取得に失敗しました'),
                );
              }

              final requestDocs =
                  requestSnapshot.data?.docs ?? [];

              final notificationDocs =
                  notificationSnapshot.data?.docs ?? [];

              // =============================================
              // 通知なし
              // =============================================
              if (requestDocs.isEmpty &&
                  notificationDocs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 60,
                        color: Colors.grey,
                      ),

                      SizedBox(height: 12),

                      Text(
                        '通知はありません',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
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

                if (aTime is Timestamp &&
                    bTime is Timestamp) {
                  return bTime.compareTo(aTime);
                }

                return 0;
              });

              return ListView.separated(
                itemCount: allItems.length,

                separatorBuilder: (_, __) {
                  return Divider(
                    height: 1,
                    color: Colors.grey.shade200,
                  );
                },

                itemBuilder: (context, index) {
                  final item = allItems[index];

                  // =========================================
                  // 友達申請
                  // =========================================
                  if (item['kind'] == 'friend_request') {
                    return _FriendRequestTile(
                      requestId: item['id'] ?? '',
                      senderId: item['senderId'] ?? '',
                      senderName:
                      item['senderName'] ?? 'ユーザー',
                      senderIcon:
                      item['senderIcon'] ?? '',
                      status:
                      item['status'] ?? 'pending',
                    );
                  }

                  // =========================================
                  // 友達申請が承認された通知
                  // =========================================
                  if (item['type'] == 'friend_accepted') {
                    return _FriendAcceptedTile(
                      userId: item['userId'] ?? '',
                      userName:
                      item['userName'] ?? 'ユーザー',
                      userIcon:
                      item['userIcon'] ?? '',
                      message:
                      item['message'] ?? '',
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
// 友達申請通知
// =========================================================

// =========================================================
// 友達申請通知
// =========================================================

class _FriendRequestTile extends StatelessWidget {
  final String requestId;
  final String senderId;
  final String senderName;
  final String senderIcon;
  final String status;

  const _FriendRequestTile({
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

      final myName = myData?['username'] ?? myData?['name'] ?? 'ユーザー';

      final myIcon = myData?['icon'] ?? '';

      // =====================================================
      // 友達として登録
      // =====================================================
      // =====================================================
// 相手の情報を取得
// =====================================================
      final senderSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .get();

      final senderData = senderSnapshot.data();

      final senderName =
          senderData?['username'] ??
              senderData?['name'] ??
              'ユーザー';

// =====================================================
// 自分の friends に相手を登録
//
// users
//   └── 自分UID
//        └── friends
//             └── 相手UID
// =====================================================
      await FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .collection('friends')
          .doc(senderId)
          .set({
        'userId': senderId,
        'username': senderName,
        'createdAt': FieldValue.serverTimestamp(),
      });

// =====================================================
// 相手の friends に自分を登録
//
// users
//   └── 相手UID
//        └── friends
//             └── 自分UID
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
      // 申請した相手に「承認されました」通知を送る
      //
      // users
      //   └── 申請した人UID
      //       └── notifications
      // =====================================================
      await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .collection('notifications')
          .add({
            'type': 'friend_accepted',

            'userId': myUid,

            'userName': myName,

            'userIcon': myIcon,

            'message': '$myNameさんが友達申請を承認しました',

            'createdAt': FieldValue.serverTimestamp(),
          });

      // =====================================================
      // 自分に届いていた友達申請を削除
      // → 通知画面から自動で消える
      // =====================================================
      await FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .collection('friend_requests')
          .doc(requestId)
          .delete();

      if (!context.mounted) return;

      // =====================================================
      // 承認した側に小さく表示
      // =====================================================
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$senderNameさんと友達になりました！'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('友達申請承認エラー: $e');

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('友達申請の承認に失敗しました')));
    }
  }

  // =========================================================
  // 友達申請を拒否
  // =========================================================
  Future<void> _rejectFriendRequest(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    try {
      // =====================================================
      // 申請を削除
      // → 通知画面から消える
      // =====================================================
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('friend_requests')
          .doc(requestId)
          .delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$senderNameさんの友達申請を拒否しました')));
    } catch (e) {
      debugPrint('友達申請拒否エラー: $e');

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('友達申請の拒否に失敗しました')));
    }
  }

  // =========================================================
  // プロフィールアイコン
  // =========================================================
  Widget _buildProfileIcon() {
    // アイコンが設定されている場合
    if (senderIcon.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(senderIcon),
      );
    }

    // アイコンがない場合
    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFF258EDB).withOpacity(0.12),

      child: const Icon(
        Icons.person,
        size: 24 * 0.65,
        color: Color(0xFF258EDB),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'pending';

    return Container(
      color: isPending ? const Color(0xFFF1F8FF) : Colors.white,

      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          // =================================================
          // 相手のアイコン
          // =================================================
          _buildProfileIcon(),

          const SizedBox(width: 13),

          // =================================================
          // 通知内容
          // =================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  '友達申請',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 4),

                Text(
                  '$senderNameさんから友達申請が届きました',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),

          // =================================================
          // 右端の承認・拒否ボタン
          // =================================================
          if (isPending)
            Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                SizedBox(
                  width: 76,
                  height: 34,

                  child: FilledButton(
                    onPressed: () {
                      _acceptFriendRequest(context);
                    },

                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF258EDB),
                      padding: EdgeInsets.zero,
                    ),

                    child: const Text('承認', style: TextStyle(fontSize: 12)),
                  ),
                ),

                const SizedBox(height: 6),

                SizedBox(
                  width: 76,
                  height: 34,

                  child: OutlinedButton(
                    onPressed: () {
                      _rejectFriendRequest(context);
                    },

                    style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),

                    child: const Text('拒否', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
        ],
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
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(userIcon),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor:
      const Color(0xFF258EDB).withOpacity(0.12),
      child: const Icon(
        Icons.person,
        size: 16,
        color: Color(0xFF258EDB),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,

      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          // 相手のアイコン
          _buildProfileIcon(),

          const SizedBox(width: 13),

          // 通知内容
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                const Text(
                  '友達になりました',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  message.isNotEmpty
                      ? message
                      : '$userNameさんが友達申請を承認しました',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}