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
      backgroundColor: bgColor,

      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: cardColor,

        title: Text(
          "マイページ",
          style: TextStyle(
            color: textColor,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 9),
            child: IconButton(
              icon: Icon(
                Icons.notifications_none,
                color: textColor,
              ),
              onPressed: () {},
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: textColor,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
              },
            ),
          ),
        ],

        iconTheme: IconThemeData(
          color: textColor,
        ),
      ),

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _getUserStream(),

        builder: (context, snapshot) {
          // 読み込み中
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // エラー
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "ユーザー情報の取得に失敗しました",
                style: TextStyle(color: textColor),
              ),
            );
          }

          // ログインしていない
          if (!snapshot.hasData) {
            return Center(
              child: Text(
                "ログインしてください",
                style: TextStyle(color: textColor),
              ),
            );
          }

          // Firestoreにデータが存在しない
          if (!snapshot.data!.exists) {
            return Center(
              child: Text(
                "ユーザー情報が見つかりません",
                style: TextStyle(color: textColor),
              ),
            );
          }

          // Firestoreのデータ
          final data = snapshot.data!.data()!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ProfileCard(data: data, isDark: isDark, cardColor: cardColor, textColor: textColor),
                const SizedBox(height: 18),
                StudyTimeCard(isDark: isDark, cardColor: cardColor, textColor: textColor),
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
    required this.isDark,
    required this.cardColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final String name = data["name"] ?? "名前未設定";
    final String grade = data["grade"] ?? "未設定";
    final String goal = data["goal"] ?? "未設定";
    final String location = data["location"] ?? "未設定";
    final String studyStyle = data["studyStyle"] ?? "未設定";
    final String icon = data["icon"] ?? "";

    final dividerColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Card(
      color: cardColor,
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
            // アイコン・名前
            Row(
              children: [
                Stack(
                  children: [
                    icon.isNotEmpty
                        ? CircleAvatar(
                      radius: 45,
                      backgroundImage: NetworkImage(icon),
                    )
                        : CircleAvatar(
                      radius: 45,
                      backgroundColor: MypageScreen.primaryBlue.withValues(alpha: 0.12),
                      child: const Icon(
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
                          color: cardColor,
                          shape: BoxShape.circle,
                        ),
                        child: const CircleAvatar(
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
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
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
            Divider(color: dividerColor),

            ProfileItem(
              icon: Icons.person,
              title: "学年・職種（任意）",
              value: grade,
              textColor: textColor,
              dividerColor: dividerColor,
            ),

            ProfileItem(
              icon: Icons.track_changes,
              title: "学習目標",
              value: goal,
              textColor: textColor,
              dividerColor: dividerColor,
            ),

            ProfileItem(
              icon: Icons.location_on,
              title: "住んでいる場所（任意）",
              value: location,
              textColor: textColor,
              dividerColor: dividerColor,
            ),

            ProfileItem(
              icon: Icons.schedule,
              title: "勉強スタイル",
              value: studyStyle,
              textColor: textColor,
              isLast: true,
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 7,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: MypageScreen.primaryBlue.withValues(alpha: 0.12),
                child: Icon(
                  icon,
                  color: MypageScreen.primaryBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(
                      title,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      value,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast && dividerColor != null) Divider(color: dividerColor),
      ],
    );
  }
}


// ==============================
// 学習時間
// ==============================

class StudyTimeCard extends StatelessWidget {
  final bool isDark;
  final Color cardColor;
  final Color textColor;

  const StudyTimeCard({
    super.key,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cardColor,
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
                  backgroundColor: MypageScreen.primaryBlue.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.schedule,
                    color: MypageScreen.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "今週・今月の総学習時間",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
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
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
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

                Container(
                  height: 70,
                  width: 1,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                ),

                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        "今月の総学習時間",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
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