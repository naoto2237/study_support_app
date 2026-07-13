import 'package:flutter/material.dart';

class MypageScreen extends StatelessWidget {
  const MypageScreen({super.key});

  static const Color primaryBlue = Color(0xFF3D96E8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),

      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,
        title: const Text(
          "マイページ",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 9),
            child: IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {},
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {},
            ),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const ProfileCard(),

            const SizedBox(height: 18),

            const StudyTimeCard(),
          ],
        ),
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: MypageScreen.primaryBlue.withOpacity(
                        0.12,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: MypageScreen.primaryBlue,
                      ),
                    ),

                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: MypageScreen.primaryBlue,
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 18),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "ゆうき",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 6),

                      Text(
                        "継続は力なり！一緒に頑張りましょう！",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Divider(),

            ProfileItem(icon: Icons.person, title: "学年・職種（任意）", value: "大学2年生"),

            const Divider(),

            ProfileItem(
              icon: Icons.track_changes,
              title: "学習目標",
              value: "TOEICで800点を目指す",
            ),

            const Divider(),

            ProfileItem(
              icon: Icons.location_on,
              title: "住んでいる場所（任意）",
              value: "東京都",
            ),

            const Divider(),

            ProfileItem(icon: Icons.schedule, title: "勉強スタイル", value: "夜型"),
          ],
        ),
      ),
    );
  }
}

class ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const ProfileItem({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 7),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: MypageScreen.primaryBlue.withOpacity(.12),

            child: Icon(icon, color: MypageScreen.primaryBlue),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey)),

                const SizedBox(height: 5),

                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StudyTimeCard extends StatelessWidget {
  const StudyTimeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: MypageScreen.primaryBlue.withOpacity(.12),

                  child: Icon(Icons.schedule, color: MypageScreen.primaryBlue),
                ),

                const SizedBox(width: 12),

                const Text(
                  "今週・今月の総学習時間",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 11),

            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text("今週の総学習時間", style: TextStyle(fontSize: 12)),

                      const SizedBox(height: 12),

                      Text(
                        "12時間45分",
                        style: TextStyle(
                          color: MypageScreen.primaryBlue,
                          fontSize: 20.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(height: 70, width: 1, color: Colors.grey.shade300),

                Expanded(
                  child: Column(
                    children: [
                      const Text("今月の総学習時間", style: TextStyle(fontSize: 12)),

                      const SizedBox(height: 12),

                      Text(
                        "58時間30分",
                        style: TextStyle(
                          color: MypageScreen.primaryBlue,
                          fontSize: 20.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              "※表示されている学習時間は、アプリ内での学習時間です。",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
