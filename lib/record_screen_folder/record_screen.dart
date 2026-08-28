import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'record_myrecord_screen_folder/record_myrecord_screen.dart';
import 'comparision_screen_folder/comparison_screen.dart';
import 'package:study_support_app/chat_icon_screen_folder/chat_list_screen.dart';
import 'package:study_support_app/notification_screen_folder/notification_screen.dart';
import 'package:study_support_app/chat_icon_screen_folder/chat_list_screen.dart';
import 'package:study_support_app/notification_screen_folder/notification_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecordScreen extends StatefulWidget {
  final String? userId;

  const RecordScreen({super.key, this.userId});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  // ========================================================
  // 比較画面に渡す自分の学習時間
  // ========================================================

  int totalSeconds = 0;

  @override
  void initState() {
    super.initState();

    _loadStudyTime();
  }

  // ========================================================
  // 今週の学習時間をFirestoreから取得
  // ========================================================

  Future<void> _loadStudyTime() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    // userIdが指定されていればそのUID、
    // 指定されていなければログイン中の自分のUID
    final targetUserId = widget.userId ?? currentUser?.uid;

    if (targetUserId == null || targetUserId.isEmpty) return;

    final now = DateTime.now();

    // 今日の日付だけにする
    final today = DateTime(now.year, now.month, now.day);

    // 今週の月曜日
    final monday = today.subtract(Duration(days: today.weekday - 1));

    // 今週の日曜日
    final sunday = monday.add(const Duration(days: 6));

    final startDateId =
        "${monday.year.toString().padLeft(4, '0')}-"
        "${monday.month.toString().padLeft(2, '0')}-"
        "${monday.day.toString().padLeft(2, '0')}";

    final endDateId =
        "${sunday.year.toString().padLeft(4, '0')}-"
        "${sunday.month.toString().padLeft(2, '0')}-"
        "${sunday.day.toString().padLeft(2, '0')}";

    try {
      // 今週の記録をまとめて1回で取得
      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(targetUserId)
          .collection("studyRecords")
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: startDateId)
          .where(FieldPath.documentId, isLessThanOrEqualTo: endDateId)
          .get();

      int seconds = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();

        seconds += (data["studyTime"] as num?)?.toInt() ?? 0;
      }

      if (!mounted) return;

      setState(() {
        totalSeconds = seconds;
      });
    } catch (e) {
      debugPrint("今週の学習時間の取得に失敗しました: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final unselectedLabelColor = isDark ? Colors.white54 : Colors.black45;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF121212)
            : const Color(0xFFF7F7F7),

        // ========================================================
        // AppBar
        // ========================================================
        appBar: AppBar(
          centerTitle: false,
          backgroundColor: const Color(0xFF258EDB),

          title: const Text(
            "学習記録",
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 9),
              child: IconButton(
                icon: const Icon(Icons.chat_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatListScreen(),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('friend_requests')
                    .where('status', isEqualTo: 'pending')
                    .where('isRead', isEqualTo: false)
                    .snapshots(),

                builder: (context, requestSnapshot) {
                  final hasFriendRequest =
                      requestSnapshot.hasData &&
                      requestSnapshot.data!.docs.isNotEmpty;

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .collection('notifications')
                        .where('isRead', isEqualTo: false)
                        .snapshots(),

                    builder: (context, notificationSnapshot) {
                      final hasNotification =
                          notificationSnapshot.hasData &&
                          notificationSnapshot.data!.docs.isNotEmpty;

                      final hasUnread = hasFriendRequest || hasNotification;

                      return IconButton(
                        onPressed: () async {
                          // =========================================
                          // 先に通知画面を表示
                          // =========================================
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationScreen(),
                            ),
                          );

                          // =========================================
                          // その後、未読を既読にする
                          // =========================================
                          final user = FirebaseAuth.instance.currentUser;

                          if (user != null) {
                            final firestore = FirebaseFirestore.instance;

                            // 未読の友達申請を既読にする
                            final friendRequests = await firestore
                                .collection('users')
                                .doc(user.uid)
                                .collection('friend_requests')
                                .where('isRead', isEqualTo: false)
                                .get();

                            for (final doc in friendRequests.docs) {
                              await doc.reference.update({'isRead': true});
                            }

                            // 未読の通知を既読にする
                            final notifications = await firestore
                                .collection('users')
                                .doc(user.uid)
                                .collection('notifications')
                                .where('isRead', isEqualTo: false)
                                .get();

                            for (final doc in notifications.docs) {
                              await doc.reference.update({'isRead': true});
                            }
                          }
                        },

                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.notifications_none),

                            // =========================================
                            // 赤い点
                            // =========================================
                            if (hasUnread)
                              Positioned(
                                right: -1,
                                top: -1,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],

          iconTheme: const IconThemeData(color: Colors.white),

          // ======================================================
          // タブ
          // ======================================================
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: Colors.white,
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,

                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(color: Color(0xFF258EDB), width: 3),
                ),

                labelColor: const Color(0xFF258EDB),

                unselectedLabelColor: unselectedLabelColor,

                tabs: const [
                  Tab(
                    child: Text(
                      "自分の記録",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  Tab(
                    child: Text(
                      "他の人と比較",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ========================================================
        // タブの中身
        // ========================================================
        body: TabBarView(
          children: [
            RecordMyRecordScreen(
              userId:
                  widget.userId ?? FirebaseAuth.instance.currentUser?.uid ?? '',
            ),

            // ★ ここが重要
            ComparisonScreen(totalSeconds: totalSeconds),
          ],
        ),
      ),
    );
  }
}
