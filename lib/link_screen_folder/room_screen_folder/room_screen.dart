import 'package:flutter/material.dart';

import 'room_makeTab_folder/room_make.dart';
import 'room_searchTab_folder/room_search.dart';
import 'package:study_support_app/setting_screen.dart';
import 'package:study_support_app/notification_screen.dart';

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
            : const Color(0xFFF7F7F7),

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
            IconButton(
              icon: Icon(Icons.notifications_none, color: textColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                );
                // 通知画面へ
              },
            ),
            IconButton(
              icon: Icon(Icons.settings_outlined, color: textColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            indicatorSize: TabBarIndicatorSize.tab,

            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: Color(0xFF258EDB), width: 3),
            ),

            labelColor: const Color(0xFF258EDB),
            unselectedLabelColor: unselectedLabelColor,

            tabs: const [
              Tab(
                child: Row(
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
