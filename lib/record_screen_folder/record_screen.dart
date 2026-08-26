import 'package:flutter/material.dart';
import 'package:study_support_app/setting_screen.dart';

import 'record_myrecord_screen_folder/record_myrecord_screen.dart';
import 'comparision_screen_folder/comparison_screen.dart';
import 'package:study_support_app/chat_list_screen.dart';

class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? Colors.white70 : Colors.black;

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
                    ), // ※ファイル名に合わせて変更
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: IconButton(
                icon: const Icon(Icons.notifications_none), // 吹き出しアイコン
                onPressed: () {},
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
            const RecordMyRecordScreen(),
            ComparisonScreen(totalSeconds: 0),
          ],
        ),
      ),
    );
  }
}
