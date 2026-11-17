// ======================================================================
// 【部品】上の帯（AppBar）の通知ベル
//
// 主なクラス: NotificationBellButton
// 使う画面: ホーム・Link・学習記録
// ・まだ読んでいない通知があると、ベルの右上に赤い丸で数を出す（10以上は「9+」）
//   数えるもの: 返事をしていない友達申請 ＋ 読んでいない通知（友達になった など）
// ・押すと通知画面（notification_screen.dart）を開く
//   既読にするのは通知画面の中で行う（どれが新しいかを画面で見せるため）
// ・調べ方は isRead だけで絞る（2つ以上の条件で絞ると Firestore の索引が要るため）
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_support_app/screens/notification/notification_screen.dart';

class NotificationBellButton extends StatefulWidget {
  // ベルの色（青い帯の上では白）
  final Color color;

  // 赤い丸のふちの色（帯の色に合わせると、丸がベルから浮いて見える）
  final Color badgeBorderColor;

  const NotificationBellButton({
    super.key,
    this.color = Colors.white,
    required this.badgeBorderColor,
  });

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton> {
  // Stream は1回だけ作る（画面が作りなおされても、読みなおさない）
  late final Stream<int> _requestCount;
  late final Stream<int> _notificationCount;

  @override
  void initState() {
    super.initState();

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      _requestCount = Stream.value(0);
      _notificationCount = Stream.value(0);
      return;
    }

    final me = FirebaseFirestore.instance.collection('users').doc(uid);

    _requestCount = me
        .collection('friend_requests')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .where((doc) => (doc.data()['status'] ?? 'pending') == 'pending')
              .length,
        );

    _notificationCount = me
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        // 通知画面に出すもの（友達になった）だけを数える
        .map(
          (snap) => snap.docs
              .where((doc) => doc.data()['type'] == 'friend_accepted')
              .length,
        );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _requestCount,
      builder: (context, requestSnap) {
        return StreamBuilder<int>(
          stream: _notificationCount,
          builder: (context, notificationSnap) {
            final count =
                (requestSnap.data ?? 0) + (notificationSnap.data ?? 0);

            return IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                );
              },
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.notifications_none, color: widget.color),

                  if (count > 0)
                    Positioned(
                      right: -5,
                      top: -4,
                      child: _Badge(
                        count: count,
                        borderColor: widget.badgeBorderColor,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// 赤い丸と数
class _Badge extends StatelessWidget {
  final int count;
  final Color borderColor;

  const _Badge({required this.count, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    final text = count > 9 ? '9+' : '$count';

    return Container(
      constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      ),
    );
  }
}
