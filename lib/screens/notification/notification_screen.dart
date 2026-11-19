// ======================================================================
// 【画面】通知
//
// 主なクラス: NotificationScreen / _NotificationRow（通知1件分）
// 開き方: ホーム・Link・学習記録の上の通知ベル（notification_bell.dart）
// ・出す通知:
//     友達申請（friend_requests）… 下に「拒否」「承認」ボタン
//     友達になりました（notifications の type: friend_accepted）
//     （応援の通知は送らない。前に届いた type: cheer の通知も出さない）
// ・新しい通知（この画面を開いたときに、まだ読んでいなかったもの）は
//   右に青い点を出す（カードはいつも白）。開いたら既読にする（ベルの赤い数が消える）
// ・相手の名前・アイコンは、相手の今のプロフィールから出す
// ・行を押すと、相手のページを開く
// ======================================================================

import 'package:flutter/material.dart';
import 'package:study_support_app/screens/link/user_profile_screen.dart';
import 'package:study_support_app/theme/app_palette.dart';
import 'package:study_support_app/theme/empty_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_support_app/screens/notification/friend_request_notification.dart';
import 'package:study_support_app/theme/app_colors.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  // Stream は1回だけ作る
  Stream<QuerySnapshot<Map<String, dynamic>>>? _requests;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _notifications;

  // この画面を開いたときに、まだ読んでいなかった通知（"kind/id" の形）
  final Set<String> _newKeys = {};

  @override
  void initState() {
    super.initState();

    final uid = _uid;

    if (uid == null) return;

    final me = FirebaseFirestore.instance.collection('users').doc(uid);

    _requests = me
        .collection('friend_requests')
        .orderBy('createdAt', descending: true)
        .snapshots();

    _notifications = me
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();

    _markAllRead(me);
  }

  // まだ読んでいない通知を覚えてから、まとめて既読にする
  Future<void> _markAllRead(DocumentReference<Map<String, dynamic>> me) async {
    try {
      final unreadRequests = await me
          .collection('friend_requests')
          .where('isRead', isEqualTo: false)
          .get();

      final unreadNotifications = await me
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      if (mounted) {
        setState(() {
          for (final doc in unreadRequests.docs) {
            _newKeys.add('friend_request/${doc.id}');
          }
          for (final doc in unreadNotifications.docs) {
            _newKeys.add('notification/${doc.id}');
          }
        });
      }

      final docs = [...unreadRequests.docs, ...unreadNotifications.docs];

      if (docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('通知を既読にできませんでした: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Scaffold(
      backgroundColor: p.page,

      appBar: AppBar(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: p.text),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Transform.translate(
          offset: const Offset(-19, 0),
          child: Text(
            '通知',
            style: TextStyle(
              color: p.text,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      body: _uid == null
          ? const EmptyMessage(icon: Icons.login_rounded, text: 'ログインしてください')
          : _buildList(),
    );
  }

  Widget _buildList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _requests,
      builder: (context, requestSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _notifications,
          builder: (context, notificationSnapshot) {
            if (requestSnapshot.hasError || notificationSnapshot.hasError) {
              return const EmptyMessage(
                icon: Icons.error_outline_rounded,
                text: '通知を読み込めませんでした',
              );
            }

            // 読み込み中
            if (!requestSnapshot.hasData || !notificationSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final items = <_NotificationItem>[];

            // 友達申請（返事をしていないものだけ）
            for (final doc in requestSnapshot.data!.docs) {
              final data = doc.data();

              if ((data['status'] ?? 'pending') != 'pending') continue;

              items.add(
                _NotificationItem(
                  kind: _Kind.friendRequest,
                  id: doc.id,
                  userId: (data['senderId'] ?? doc.id).toString(),
                  savedName: (data['senderName'] ?? 'ユーザー').toString(),
                  savedIcon: (data['senderIcon'] ?? '').toString(),
                  createdAt: data['createdAt'],
                  isNew: _newKeys.contains('friend_request/${doc.id}'),
                ),
              );
            }

            // そのほかの通知（友達になった）
            for (final doc in notificationSnapshot.data!.docs) {
              final data = doc.data();

              final kind = switch (data['type']) {
                'friend_accepted' => _Kind.friendAccepted,
                _ => null,
              };

              if (kind == null) continue;

              items.add(
                _NotificationItem(
                  kind: kind,
                  id: doc.id,
                  userId: (data['userId'] ?? '').toString(),
                  savedName: (data['userName'] ?? 'ユーザー').toString(),
                  savedIcon: (data['userIcon'] ?? '').toString(),
                  createdAt: data['createdAt'],
                  isNew: _newKeys.contains('notification/${doc.id}'),
                ),
              );
            }

            // 通知なし
            if (items.isEmpty) {
              return const EmptyMessage(
                icon: Icons.notifications_none_rounded,
                text: '通知はありません',
                subText: '友達申請が届くと、ここに表示されます',
              );
            }

            // 新しい順（書きこんだ直後で時刻がまだないものは、いちばん上）
            items.sort((a, b) => b.time.compareTo(a.time));

            final p = context.pal;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  // 枠線は中身より上に描く
                  // （中の白い面が枠線に重なって、角の枠線が消えて見えないように）
                  foregroundDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: p.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (int i = 0; i < items.length; i++)
                        _NotificationRow(
                          item: items[i],
                          showDivider: i < items.length - 1,
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ======================================================
// 通知1件分のデータ
// ======================================================

enum _Kind { friendRequest, friendAccepted }

class _NotificationItem {
  final _Kind kind;
  final String id;
  final String userId;
  final String savedName;
  final String savedIcon;
  final dynamic createdAt;
  final bool isNew;

  const _NotificationItem({
    required this.kind,
    required this.id,
    required this.userId,
    required this.savedName,
    required this.savedIcon,
    required this.createdAt,
    required this.isNew,
  });

  DateTime get time {
    final t = createdAt;
    return t is Timestamp ? t.toDate() : DateTime.now();
  }
}

// ======================================================
// 通知1件分の行
// 左に相手のアイコン、まん中に文と時刻、右に新しい印（青い点）
// 友達申請のときは、文の下に「拒否」「承認」ボタン
// ======================================================

class _NotificationRow extends StatelessWidget {
  final _NotificationItem item;
  final bool showDivider;

  const _NotificationRow({required this.item, required this.showDivider});

  // 「たった今」「5分前」「3時間前」「2日前」「11月3日」
  static String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);

    if (diff.inMinutes < 1) return 'たった今';
    if (diff.inHours < 1) return '${diff.inMinutes}分前';
    if (diff.inDays < 1) return '${diff.inHours}時間前';
    if (diff.inDays < 7) return '${diff.inDays}日前';

    return '${time.month}月${time.day}日';
  }

  // 文の後ろの部分（名前のあと）
  String get _message {
    switch (item.kind) {
      case _Kind.friendRequest:
        return 'さんから友達申請が届きました';
      case _Kind.friendAccepted:
        return 'さんと友達になりました';
    }
  }

  IconData get _kindIcon {
    switch (item.kind) {
      case _Kind.friendRequest:
        return Icons.person_add_alt_1_rounded;
      case _Kind.friendAccepted:
        return Icons.people_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      // 相手の今の名前・アイコン（読めないときは、通知に保存した名前）
      stream: item.userId.isEmpty
          ? null
          : FirebaseFirestore.instance
                .collection('users')
                .doc(item.userId)
                .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        final String name =
            (data?['name'] ?? data?['username'] ?? item.savedName).toString();
        final String icon = (data?['icon'] ?? item.savedIcon).toString();

        return Material(
          color: p.card,
          child: InkWell(
            onTap: item.userId.isEmpty
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfileScreen(userId: item.userId),
                      ),
                    );
                  },
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: showDivider
                  ? BoxDecoration(
                      border: Border(bottom: BorderSide(color: p.divider)),
                    )
                  : null,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 相手のアイコンと、通知の種類の小さい印
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // 白い縁（暗い画面ではカードの色）
                        // （うすい青の面の上でも、アイコンの形がわかるようにする）
                        Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: p.card,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.primarySoft,
                            backgroundImage: icon.isNotEmpty
                                ? NetworkImage(icon)
                                : null,
                            child: icon.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 25,
                                    color: AppColors.primary,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          right: -3,
                          bottom: -3,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: item.kind == _Kind.friendAccepted
                                  ? AppColors.green
                                  : AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: p.card, width: 2),
                            ),
                            child: Icon(
                              _kindIcon,
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // 文・時刻・ボタン
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(text: _message),
                            ],
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: p.text,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          _timeAgo(item.time),
                          style: TextStyle(fontSize: 12, color: p.muted),
                        ),

                        if (item.kind == _Kind.friendRequest) ...[
                          const SizedBox(height: 10),
                          FriendRequestNotification(
                            requestId: item.id,
                            senderId: item.userId,
                            senderName: name,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 新しい通知の印
                  if (item.isNew)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 6),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
