import 'package:flutter/material.dart';

import 'room_makeTab_folder/room_make.dart';
import 'room_searchTab_folder/room_search.dart';

class RoomScreen extends StatelessWidget {
  const RoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),

        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,

          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),

          title: const Text(
            "ルーム",
            style: TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          actions: [
            IconButton(
              icon: const Icon(
                Icons.notifications_none,
                color: Colors.black,
              ),
              onPressed: () {},
            ),
          ],

          bottom: TabBar(
            indicatorColor: const Color(0xFF3D96E8),
            indicatorWeight: 3,
            labelColor: const Color(0xFF3D96E8),
            unselectedLabelColor: Colors.grey,

            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group_add_outlined,
                      size: 20,
                    ),
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
                    Icon(
                      Icons.search,
                      size: 20,
                    ),
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

        body: const TabBarView(
          children: [
            CreateRoomTab(),
            SearchRoomTab(),
          ],
        ),
      ),
    );
  }
}