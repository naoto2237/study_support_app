import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'record_myrecord_screen_folder/record_myrecord_screen.dart';
import 'comparision_screen_folder/comparison_screen.dart';
import 'package:study_support_app/chat_list_screen.dart';
import 'package:study_support_app/notification_screen.dart';

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

    // 今週の月曜日
    final monday = now.subtract(Duration(days: now.weekday - 1));

    int seconds = 0;

    for (int i = 0; i < 7; i++) {
      final date = monday.add(Duration(days: i));

      final dateId =
          "${date.year.toString().padLeft(4, '0')}-"
          "${date.month.toString().padLeft(2, '0')}-"
          "${date.day.toString().padLeft(2, '0')}";

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(targetUserId)
          .collection("studyRecords")
          .doc(dateId)
          .get();

      if (doc.exists) {
        final data = doc.data();

        seconds += (data?["studyTime"] as num?)?.toInt() ?? 0;
      }
    }

    if (!mounted) return;

    setState(() {
      totalSeconds = seconds;
    });
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
              child: IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
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
