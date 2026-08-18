import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:study_support_app/setting_screen.dart';
import 'profile_edit_screen.dart';

class MypageScreen extends StatefulWidget {
  const MypageScreen({super.key});

  static const Color primaryBlue = Color(0xFF3D96E8);

  @override
  State<MypageScreen> createState() => _MypageScreenState();
}

class _MypageScreenState extends State<MypageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _getUserStream(),

        builder: (context, snapshot) {
          // 読み込み中
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // エラー
          if (snapshot.hasError) {
            return const Center(child: Text("ユーザー情報の取得に失敗しました"));
          }

          // ログインしていない
          if (!snapshot.hasData) {
            return const Center(child: Text("ログインしてください"));
          }

          // Firestoreにデータがない
          if (!snapshot.data!.exists) {
            return const Center(child: Text("ユーザー情報が見つかりません"));
          }

          final data = snapshot.data!.data()!;

          return SingleChildScrollView(
            child: Column(
              children: [
                ProfileHeader(data: data),

                ProfileContent(data: data),
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

// ======================================================
// 上部プロフィールヘッダー
// ======================================================

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> data;

  const ProfileHeader({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final String name = data["name"] ?? "名前未設定";
    final String icon = data["icon"] ?? "";

    return SizedBox(
      height: 350,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ------------------------------------------
          // 青い背景
          // ------------------------------------------
          Container(
            height: 335,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/haikei8.png'),
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),

          // ------------------------------------------
          // 通知・設定
          // ------------------------------------------
          Positioned(
            top: 56,
            right: 0,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 9),
                  child: IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                    ),
                    onPressed: () {},
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
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
            ),
          ),

          // ------------------------------------------
          // 白いプロフィールエリア
          // ------------------------------------------
          Positioned(
            top: 237,
            left: 0,
            right: 0,
            child: Container(
              height: 170,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
          ),

          // ------------------------------------------
          // プロフィール画像
          // ------------------------------------------
          Positioned(
            top: 186,
            left: 0,
            right: 0,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 白い外枠
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),

                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: ClipOval(
                        child: icon.isNotEmpty
                            ? Image.network(
                                icon,
                                width: 82,
                                height: 82,
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                color: const Color(
                                  0xFF3D96E8,
                                ).withOpacity(0.12),
                                child: const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Color(0xFF3D96E8),
                                ),
                              ),
                      ),
                    ),
                  ),

                  // カメラアイコン
                  Positioned(
                    right: -2,
                    bottom: 2,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: MypageScreen.primaryBlue,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: Colors.white, width: 3),
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ------------------------------------------
          // 名前
          // ------------------------------------------
          // ------------------------------------------
          // 名前・ユーザーID
          // ------------------------------------------
          Positioned(
            top: 286,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 名前
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),

                  const SizedBox(height: 3),

                  // ユーザーID
                  Text(
                    data["userId"] ?? "",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          ),
        ],
      ),
    );
  }
}

// ======================================================
// プロフィール以下
// ======================================================

class ProfileContent extends StatelessWidget {
  final Map<String, dynamic> data;

  const ProfileContent({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final String grade = data["grade"] ?? "未設定";

    final String goal = data["goal"] ?? "未設定";

    final String location = data["location"] ?? "未設定";

    final String studyStyle = data["studyStyle"] ?? "未設定";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // ------------------------------------------
          // 一言コメント
          // ------------------------------------------
          Text(
            data["comment"] ?? "",
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),

          const SizedBox(height: 18),

          // ------------------------------------------
          // プロフィール分析・編集
          // ------------------------------------------
          Row(
            children: [
              // ------------------------------------------
              // プロフィール分析
              // ------------------------------------------
              Expanded(
                child: _ActionButton(
                  icon: Icons.bar_chart_rounded,
                  text: "プロフィール分析",
                  onTap: () {},
                ),
              ),

              const SizedBox(width: 14),

              // ------------------------------------------
              // プロフィールを編集
              // ------------------------------------------
              Expanded(
                child: _ActionButton(
                  icon: Icons.edit,
                  text: "プロフィールを編集",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileEditScreen(data: data),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ------------------------------------------
          // プロフィール項目
          // ------------------------------------------
          _ProfileRow(icon: Icons.school, title: "学年・職種（任意）", value: grade),

          _ProfileRow(icon: Icons.track_changes, title: "学習目標", value: goal),

          _ProfileRow(
            icon: Icons.location_on,
            title: "住んでいる場所（任意）",
            value: location,
          ),

          _ProfileRow(icon: Icons.schedule, title: "勉強スタイル", value: studyStyle),

          const SizedBox(height: 20),

          // ------------------------------------------
          // 学習時間
          // ------------------------------------------
          const StudyTimeSection(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ======================================================
// アクションボタン
// ======================================================

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFF),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: MypageScreen.primaryBlue.withOpacity(0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: MypageScreen.primaryBlue, size: 25),

            const SizedBox(width: 8),

            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  color: MypageScreen.primaryBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 5),

            const Icon(
              Icons.chevron_right,
              color: MypageScreen.primaryBlue,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// プロフィール項目
// ======================================================

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 81,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: MypageScreen.primaryBlue.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: MypageScreen.primaryBlue, size: 24),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.chevron_right,
            color: MypageScreen.primaryBlue,
            size: 25,
          ),
        ],
      ),
    );
  }
}

// ======================================================
// 学習時間セクション
// ======================================================

class StudyTimeSection extends StatelessWidget {
  const StudyTimeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(
              Icons.access_time,
              color: MypageScreen.primaryBlue,
              size: 23,
            ),

            const SizedBox(width: 7),

            const Expanded(
              child: Text(
                "今週・今月の総学習時間 ✨",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),

            Text(
              "詳細を見る",
              style: TextStyle(
                color: MypageScreen.primaryBlue,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color: MypageScreen.primaryBlue,
              size: 22,
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _StudyTimeBox(
                title: "今週の学習時間",
                time: "12時間45分",
                target: "目標 20時間",
                percent: "62%",
                progress: 0.62,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: _StudyTimeBox(
                title: "今月の学習時間",
                time: "58時間30分",
                target: "目標 80時間",
                percent: "73%",
                progress: 0.73,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ======================================================
// 学習時間カード
// ======================================================

class _StudyTimeBox extends StatelessWidget {
  final String title;
  final String time;
  final String target;
  final String percent;
  final double progress;

  const _StudyTimeBox({
    required this.title,
    required this.time,
    required this.target,
    required this.percent,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: MypageScreen.primaryBlue,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            time,
            style: const TextStyle(
              color: MypageScreen.primaryBlue,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                MypageScreen.primaryBlue,
              ),
            ),
          ),

          const SizedBox(height: 9),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(target, style: const TextStyle(fontSize: 11)),

              Text(
                percent,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
