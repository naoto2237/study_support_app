// ======================================================================
// 【画面】ルーム（「作成」タブと「検索」タブ）
//
// 主なクラス: RoomScreen
// 開き方: Link 画面の「ルーム」
// ・作成タブ: create_tab/create_room_tab.dart
// ・検索タブ: search_tab/search_room_tab.dart
// ======================================================================

import 'package:flutter/material.dart';

import 'package:study_support_app/screens/link/room/create_tab/create_room_tab.dart';
import 'package:study_support_app/screens/link/room/search_tab/search_room_tab.dart';
import 'package:study_support_app/screens/notification/notification_screen.dart';
import 'package:study_support_app/theme/app_colors.dart';

class RoomScreen extends StatelessWidget {
  const RoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black;
    final unselectedLabelColor = isDark ? Colors.white54 : Colors.black45;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF121212)
            : AppColors.background,

        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,

          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Transform.translate(
            offset: const Offset(-19, 0),
            child: Text(
              "ルーム",
              style: TextStyle(
                color: textColor,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: IconButton(
                icon: Icon(Icons.notifications_none, color: textColor),
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
          bottom: TabBar(
            // 選んだタブの下線は、タブの幅いっぱいの長い線にする
            indicatorSize: TabBarIndicatorSize.tab,

            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: AppColors.primary, width: 3),
            ),

            labelColor: AppColors.primary,
            unselectedLabelColor: unselectedLabelColor,

            tabs: const [
              Tab(
                child: Row(
                  // アイコンと文字を、まん中に寄せて並べる
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_add_outlined, size: 20),
                    SizedBox(width: 6),
                    Text(
                      "作る",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search, size: 20),
                    SizedBox(width: 6),
                    Text(
                      "探す",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        body: const TabBarView(children: [CreateRoomTab(), SearchRoomTab()]),
      ),
    );
  }
}
