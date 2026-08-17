import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:study_support_app/setting_screen.dart';

class MypageScreen extends StatefulWidget {
  const MypageScreen({super.key});

  static const Color primaryBlue = Color(0xFF3D96E8);

  @override
  State<MypageScreen> createState() => _MypageScreenState();
}

class _MypageScreenState extends State<MypageScreen> {

  @override
  Widget build(BuildContext context) {
    // ダークモードかどうかを判定
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF7F7F7);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,

        title: const Text(
          "マイページ",
          style: TextStyle(
            color: Colors.black,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [

          Padding(
            padding: const EdgeInsets.only(left: 9),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_none,
              ),
              onPressed: () {},
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: IconButton(
              icon: const Icon(
                Icons.settings_outlined,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const SettingsPage(),
                  ),
                );
              },
            ),
          ),
        ],

        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _getUserStream(),

        builder: (context, snapshot) {

          // 読み込み中
          if (snapshot.connectionState ==
          ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // エラー
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "ユーザー情報の取得に失敗しました",
              ),
            );
          }

          // ログインしていない
          if (!snapshot.hasData) {
            return const Center(
              child: Text(
                "ログインしてください",
              ),
            );
          }

          // Firestoreにデータが存在しない
          if (!snapshot.data!.exists) {
            return const Center(
              child: Text(
                "ユーザー情報が見つかりません",
              ),
            );
          }

          // Firestoreのデータ
          final data = snapshot.data!.data()!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),

            child: Column(
              children: [

                ProfileCard(
                  data: data,
                ),

                const SizedBox(height: 18),

                const StudyTimeCard(),
              ],
            ),
          );
        },
      ),
    );
  }


  // 現在ログインしているユーザーのFirestoreデータを取得
  Stream<DocumentSnapshot<Map<String, dynamic>>> _getUserStream() {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {

      // ログインしていない場合
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .snapshots();
  }
}


// ==============================
// プロフィールカード
// ==============================

class ProfileCard extends StatelessWidget {

  final Map<String, dynamic> data;
  final bool isDark;
  final Color cardColor;
  final Color textColor;

  const ProfileCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {

    // Firestoreから取得
    final String name =
    data["name"] ?? "名前未設定";

    final String grade =
    data["grade"] ?? "未設定";

    final String goal =
    data["goal"] ?? "未設定";

    final String location =
    data["location"] ?? "未設定";

    final String studyStyle =
    data["studyStyle"] ?? "未設定";

    final String icon =
    data["icon"] ?? "";

    return Card(
      color: Colors.white,
      elevation: 2,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),

      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),

        child: Column(
          children: [

 // ==========================
 // アイコン・名前
 // ==========================

            Row(
              children: [

                Stack(
                  children: [

                    // アイコン
                    icon.isNotEmpty
                    ? CircleAvatar(
                      radius: 45,
                      backgroundImage:
                      NetworkImage(icon),
                    )
                    : CircleAvatar(
                      radius: 45,
                      backgroundColor:
                      MypageScreen.primaryBlue
                          .withOpacity(0.12),

                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color:
                        MypageScreen.primaryBlue,
                      ),
                    ),

                    // カメラアイコン
                    Positioned(
                      right: 0,
                      bottom: 0,

                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),

                        child: const CircleAvatar(
                          radius: 15,
                          backgroundColor:
                          MypageScreen.primaryBlue,

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

                // 名前
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      Text(
                        name,

                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        "継続は力なり！一緒に頑張りましょう！",

                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Divider(),

            // 学年・職種
            ProfileItem(
              icon: Icons.person,
              title: "学年・職種（任意）",
              value: grade,
            ),

            const Divider(),

            // 学習目標
            ProfileItem(
              icon: Icons.track_changes,
              title: "学習目標",
              value: goal,
            ),

            const Divider(),

            // 住んでいる場所
            ProfileItem(
              icon: Icons.location_on,
              title: "住んでいる場所（任意）",
              value: location,
            ),

            const Divider(),

            // 勉強スタイル
            ProfileItem(
              icon: Icons.schedule,
              title: "勉強スタイル",
              value: studyStyle,
            ),
          ],
        ),
      ),
    );
  }
}


// ==============================
// プロフィール項目
// ==============================

class ProfileItem extends StatelessWidget {

  final IconData icon;
  final String title;
  final String value;
  final Color textColor;
  final Color? dividerColor;
  final bool isLast;

  const ProfileItem({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.textColor,
    this.dividerColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: 7,
      ),

      child: Row(
        children: [

          CircleAvatar(
            radius: 20,

            backgroundColor:
            MypageScreen.primaryBlue
                .withOpacity(.12),

            child: Icon(
              icon,
              color: MypageScreen.primaryBlue,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Text(
                  title,

                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),

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


// ==============================
// 学習時間
// ==============================

class StudyTimeCard extends StatelessWidget {

  const StudyTimeCard({super.key});

  @override
  Widget build(BuildContext context) {

    return Card(
      color: Colors.white,
      elevation: 2,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),

      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 13,
        ),

        child: Column(
          children: [

            Row(
              children: [

                CircleAvatar(
                  radius: 20,

                  backgroundColor:
                  MypageScreen.primaryBlue
                      .withOpacity(.12),

                  child: const Icon(
                    Icons.schedule,
                    color:
                    MypageScreen.primaryBlue,
                  ),
                ),

                const SizedBox(width: 12),

                const Text(
                  "今週・今月の総学習時間",

                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 11),

            Row(
              children: [

                Expanded(
                  child: Column(
                    children: [

                      const Text(
                        "今週の総学習時間",
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        "12時間45分",

                        style: TextStyle(
                          color:
                          MypageScreen.primaryBlue,
                          fontSize: 20.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  height: 70,
                  width: 1,
                  color: Colors.grey.shade300,
                ),

                Expanded(
                  child: Column(
                    children: [

                      const Text(
                        "今月の総学習時間",
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        "58時間30分",

                        style: TextStyle(
                          color:
                          MypageScreen.primaryBlue,
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

              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

