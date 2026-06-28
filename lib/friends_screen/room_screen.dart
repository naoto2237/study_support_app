import 'package:flutter/material.dart';

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
            indicatorColor: Colors.blue,
            indicatorWeight: 3,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,

            tabs: [

              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [

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
                  children: const [

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


class CreateRoomTab extends StatelessWidget {
  const CreateRoomTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [

        // ルーム作成カード
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // TODO: ルーム作成画面へ
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [

                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.group_add,
                    color: Colors.white,
                    size: 38,
                  ),
                ),

                const SizedBox(width: 18),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        "ルームを作る",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 8),

                      Text(
                        "同じ目標を持つ仲間を集めよう",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),

                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                ),

              ],
            ),
          ),
        ),

        const SizedBox(height: 30),

        const Text(
          "マイルーム",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        const RoomCard(
          title: "基本情報技術者試験",
          members: "23人",
          isPublic: true,
        ),

        const SizedBox(height: 15),

        const RoomCard(
          title: "TOEIC 800点",
          members: "14人",
          isPublic: false,
        ),

        const SizedBox(height: 15),

        const RoomCard(
          title: "応用情報技術者",
          members: "31人",
          isPublic: true,
        ),
      ],
    );
  }
}

class RoomCard extends StatelessWidget {
  final String title;
  final String members;
  final bool isPublic;

  const RoomCard({
    super.key,
    required this.title,
    required this.members,
    required this.isPublic,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),

        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.blue.shade100,
          child: const Icon(
            Icons.groups,
            color: Colors.blue,
          ),
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [

              Icon(
                isPublic ? Icons.public : Icons.lock,
                size: 16,
                color: Colors.grey,
              ),

              const SizedBox(width: 5),

              Text(
                isPublic ? "公開" : "非公開",
              ),

              const SizedBox(width: 15),

              const Icon(
                Icons.people,
                size: 16,
                color: Colors.grey,
              ),

              const SizedBox(width: 5),

              Text(members),

            ],
          ),
        ),

        trailing: const Icon(Icons.arrow_forward_ios),

        onTap: () {},
      ),
    );
  }
}
class SearchRoomTab extends StatelessWidget {
  const SearchRoomTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [

        // 検索バー
        TextField(
          decoration: InputDecoration(
            hintText: "ルーム名・資格名で検索",
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 絞り込みボタン
        SizedBox(
          height: 45,
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO 絞り込み画面
            },
            icon: const Icon(Icons.filter_list),
            label: const Text("絞り込み"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),

        const SizedBox(height: 30),

        const Text(
          "公開ルーム",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        const PublicRoomCard(
          title: "基本情報技術者",
          members: "35人",
        ),

        const SizedBox(height: 15),

        const PublicRoomCard(
          title: "TOEIC 800点",
          members: "20人",
        ),

        const SizedBox(height: 15),

        const PublicRoomCard(
          title: "簿記2級",
          members: "18人",
        ),

        const SizedBox(height: 15),

        const PublicRoomCard(
          title: "応用情報技術者",
          members: "41人",
        ),
      ],
    );
  }
}
class PublicRoomCard extends StatelessWidget {
  final String title;
  final String members;

  const PublicRoomCard({
    super.key,
    required this.title,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [

            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.green.shade100,
              child: const Icon(
                Icons.groups,
                color: Colors.green,
              ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [

                      const Icon(
                        Icons.people,
                        size: 16,
                        color: Colors.grey,
                      ),

                      const SizedBox(width: 5),

                      Text(members),

                    ],
                  ),

                ],
              ),
            ),

            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("参加"),
            ),

          ],
        ),
      ),
    );
  }
}