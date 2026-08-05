import 'package:flutter/material.dart';

import 'room_makeTab_folder/room_make.dart';
import 'room_searchTab_folder/room_search.dart';
import 'package:study_support_app/setting_screen.dart';

class RoomScreen extends StatelessWidget {
  const RoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),

        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,

          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Transform.translate(
            offset: const Offset(-19, 0),
            child: const Text(
              "ルーム",
              style: TextStyle(
                color: Colors.black,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {
                // 通知画面へ
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
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
            indicatorColor: const Color(0xFF2196F3),
            indicatorWeight: 3,
            labelColor: const Color(0xFF2196F3),
            unselectedLabelColor: Color(0xFF9E9E9E),

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
