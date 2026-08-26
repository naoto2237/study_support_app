import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("ログインしてください"),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          "通知",
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

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection("notifications")
            .where(
          "toUserId",
          isEqualTo: user.uid,
        )
            .orderBy(
          "createdAt",
          descending: true,
        )
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "通知の取得に失敗しました",
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
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
                    "通知はありません",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: docs.length,

            separatorBuilder: (_, __) {
              return Divider(
                height: 1,
                color: Colors.grey.shade200,
              );
            },

            itemBuilder: (context, index) {
              final doc = docs[index];

              final data = doc.data();

              final type =
                  data["type"] ?? "";

              final title =
                  data["title"] ?? "通知";

              final message =
                  data["message"] ?? "";

              final read =
                  data["read"] ?? false;

              final fromUserId =
                  data["fromUserId"] ?? "";

              final requestId =
                  data["requestId"] ?? "";

              return _NotificationTile(
                title: title,
                message: message,
                type: type,
                read: read,
                fromUserId: fromUserId,
                requestId: requestId,
                notificationId: doc.id,
              );
            },

          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String message;
  final String type;
  final bool read;
  final String fromUserId;
  final String requestId;
  final String notificationId;

  const _NotificationTile({
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    required this.fromUserId,
    required this.requestId,
    required this.notificationId,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        // 通知を既読にする
        await FirebaseFirestore.instance
            .collection("notifications")
            .doc(notificationId)
            .update({
          "read": true,
        });

        // フレンド申請の場合
        if (type == "friend_request" &&
            requestId.isNotEmpty) {
          _showFriendRequestDialog(context);
        }
      },

      child: Container(
        color: read
            ? Colors.white
            : const Color(0xFFF1F8FF),

        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),

        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            Container(
              width: 48,
              height: 48,

              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF258EDB)
                    .withOpacity(0.10),
              ),

              child: Icon(
                type == "friend_request"
                    ? Icons.person_add
                    : Icons.notifications,
                color: const Color(0xFF258EDB),
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    "タップして確認",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            if (!read)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF258EDB),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // フレンド申請ダイアログ
  // ==========================================================

  void _showFriendRequestDialog(
      BuildContext context) {

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "フレンド申請",
          ),

          content: const Text(
            "このユーザーからフレンド申請が届いています。",
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "閉じる",
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                await _acceptFriendRequest(
                  context,
                );
              },
              child: const Text(
                "承認する",
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // フレンド申請を承認
  // ==========================================================

  Future<void> _acceptFriendRequest(
      BuildContext context) async {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final myUid = user.uid;

    try {
      await FirebaseFirestore.instance
          .runTransaction(
            (transaction) async {

          // ------------------------------------------
          // フレンド申請
          // ------------------------------------------

          final requestRef =
          FirebaseFirestore.instance
              .collection("friendRequests")
              .doc(requestId);

          final requestSnapshot =
          await transaction.get(requestRef);

          if (!requestSnapshot.exists) {
            throw Exception(
              "申請が存在しません",
            );
          }

          final requestData =
          requestSnapshot.data();

          if (requestData == null) {
            throw Exception(
              "申請データがありません",
            );
          }

          if (requestData["status"] != "pending") {
            throw Exception(
              "この申請はすでに処理されています",
            );
          }

          // ------------------------------------------
          // フレンド
          // ------------------------------------------

          final friendRef =
          FirebaseFirestore.instance
              .collection("friends")
              .doc();

          // ------------------------------------------
          // 申請をacceptedに変更
          // ------------------------------------------

          transaction.update(
            requestRef,
            {
              "status": "accepted",
              "acceptedAt":
              FieldValue.serverTimestamp(),
            },
          );

          // ------------------------------------------
          // フレンド登録
          // ------------------------------------------

          transaction.set(
            friendRef,
            {
              "user1": fromUserId,
              "user2": myUid,
              "createdAt":
              FieldValue.serverTimestamp(),
            },
          );
        },
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "フレンドになりました！",
          ),
        ),
      );

    } catch (e) {
      debugPrint(
        "フレンド承認エラー: $e",
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "フレンド申請の承認に失敗しました",
          ),
        ),
      );
    }
  }
}
