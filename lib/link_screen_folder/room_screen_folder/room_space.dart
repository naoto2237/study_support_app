import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class RoomSpaceScreen extends StatefulWidget {
  const RoomSpaceScreen({super.key});

  @override
  State<RoomSpaceScreen> createState() => _RoomSpaceScreenState();
}

class _RoomSpaceScreenState extends State<RoomSpaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Stack(
        children: <Widget>[
          /// 青背景
          Container(
            height: double.infinity,
            width: double.infinity,
            color: const Color(0xFF4A90E2),
          ),

          /// 上部分
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 55),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Transform.translate(
                          offset: Offset(0, -1), // ← -3〜-5で調整
                          child: Text(
                            "TOEIC800点を目指す仲間のルーム",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(left: 0),
                        child: Transform.translate(
                          offset: const Offset(22, 0), // 右へ3px
                          child: IconButton(
                            onPressed: _showExitDialog,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 43,
                              minHeight: 43,
                            ),
                            icon: const Icon(
                              Icons.logout,
                              color: Colors.white,
                              size: 23,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 0),

                      Padding(
                        padding: const EdgeInsets.only(left: 0), // ← 右へ8px移動
                        child: Transform.translate(
                          offset: const Offset(15, 0), // 右へ3px
                          child: IconButton(
                            onPressed: _showMenu,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 43,
                              minHeight: 43,
                            ),
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                              size: 23,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 9),

                _buildRoomCard(),

                const SizedBox(height: 16),

                _buildRoomMembers(),

                const SizedBox(height: 150),
              ],
            ),
          ),

          ///========================
          /// 白い部分
          ///========================
          SlidingUpPanel(
            minHeight: MediaQuery.of(context).size.height * 0.084,
            maxHeight: MediaQuery.of(context).size.height * 0.882,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
            color: Colors.white,

            panelBuilder: (ScrollController scrollController) {
              return Column(
                children: [
                  const SizedBox(height: 10),

                  //============================
                  // ドラッグバー
                  //============================
                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ← 次にTabBarが入る
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFF3D96E8),
                      indicatorWeight: 3,
                      labelColor: const Color(0xFF3D96E8),
                      unselectedLabelColor: Colors.grey,
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      tabs: const [
                        Tab(text: "チャット"),
                        Tab(text: "共有ノート"),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(), // ←追加
                      children: [
                        const Center(child: Text("チャット画面")),
                        const Center(child: Text("共有ノート画面")),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.only(
        top: 11,
        bottom: 12,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
         color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        children: [
          Column(
            children: const [
              Text(
                "00:15:32",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 37,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                "現在の学習時間",
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ],
          ),

          const SizedBox(height: 13),

          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.timer,
                    value: "00:15:32",
                    label: "タイマー",
                  ),
                ),

                _divider(),

                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.flag,
                    value: "3時間",
                    label: "今日の目標",
                  ),
                ),
                _divider(),

                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.hourglass_full,
                    value: "1時間40分",
                    label: "残り",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomMembers() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.group, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text(
                    "ルームメンバー",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const Text(
                "4人中3人が勉強中🔥",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          height: 230,

          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            children: const [
              MemberCard(name: "A", time: "00:15:32", studying: true),

              SizedBox(width: 15),

              MemberCard(name: "B", time: "01:05:18", studying: true),

              SizedBox(width: 15),

              MemberCard(name: "C", time: "01:42:18", studying: true),

              SizedBox(width: 15),

              MemberCard(name: "D", time: "休憩中", studying: false),
            ],
          ),
        ),
      ],
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("ルームを退出"),
          content: const Text("このルームから退出しますか？"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("キャンセル"),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("退出"),
            ),
          ],
        );
      },
    );
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("ルーム情報を編集"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text("通知設定"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text("ルーム情報"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class MemberCard extends StatelessWidget {
  final String name;
  final String time;
  final bool studying;

  const MemberCard({
    super.key,
    required this.name,
    required this.time,
    required this.studying,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,
      height: 220,

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(22),
      ),

      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Stack(
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 42, color: Color(0xFF3D96E8)),
                ),

                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: studying ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 6),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: studying ? const Color(0xFF2F80ED) : Colors.grey,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                studying ? "勉強中" : "休憩中",
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),

            const Spacer(),

            Text(
              time,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              studying ? "現在の学習時間" : "また一緒に頑張ろう！",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildInfoItem({
  required IconData icon,
  required String value,
  required String label,
}) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 28),

        const SizedBox(height: 5),

        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
        ),
      ],
    ),
  );
}

Widget _divider() {
  return Container(
    width: 1,
    height: 50,
    margin: const EdgeInsets.symmetric(horizontal: 14),
    color: Colors.white24,
  );
}
