import 'package:flutter/material.dart';
import 'profile_edit_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../record_screen_folder/record_myrecord_screen_folder/record_myrecord_screen3.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMyPage;

  const ProfileContent({super.key, required this.data, required this.isMyPage});

  static const Color primaryBlue = Color(0xFF258EDB);

  @override
  Widget build(BuildContext context) {
    final String grade = data["grade"] ?? "未設定";
    final String goal = data["goal"] ?? "未設定";
    final String location = "未設定";
    final String studyStyle = "未設定";

    return Column(
      children: [
        // ------------------------------------------
        // プロフィール分析・編集
        // 自分のページのときだけ表示
        // ------------------------------------------
        if (isMyPage) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.bar_chart_rounded,
                    text: "プロフィール分析",
                    backgroundColor: Colors.grey.shade200,
                    onTap: () {},
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: _ActionButton(
                    icon: Icons.edit,
                    text: "プロフィール編集",
                    backgroundColor: Colors.grey.shade200,
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
          ),

          const SizedBox(height: 12.5),

          const ProfileStatsSection(),

          const SizedBox(height: 15),
        ],

        // 一言コメント
        // コメント
        if ((data["comment"] ?? "").toString().trim().isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              data["comment"],
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 18),
        ],

        // 境界線
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE5E7EB),
          ),
        ),
        const SizedBox(height: 11),

        // プロフィール見出し
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "プロフィール",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),

        const SizedBox(height: 5),

        // ------------------------------------------
        // プロフィール項目
        // ------------------------------------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              _ProfileRow(
                title: "学年・職種（任意）",
                value: grade,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileEditScreen(data: data),
                    ),
                  );
                },
              ),

              _ProfileRow(
                title: "学習目標",
                value: goal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileEditScreen(data: data),
                    ),
                  );
                },
              ),

              _ProfileRow(
                title: "自由項目①",
                value: location,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileEditScreen(data: data),
                    ),
                  );
                },
              ),

              _ProfileRow(
                title: "自由項目②",
                value: studyStyle,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileEditScreen(data: data),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ------------------------------------------
        // 学習時間
        // ------------------------------------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: RecordMyRecordScreen3(
            cardColor: Colors.white,
            textColor: Colors.black87,
            secondaryColor: Colors.black54,
          ),
        ),

        const SizedBox(height: 135),
      ],
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
  final Color backgroundColor;

  const _ActionButton({
    required this.icon,
    required this.text,
    required this.onTap,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.black87,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),

            const SizedBox(width: 7),

            Text(
              text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileStatsSection extends StatefulWidget {
  const ProfileStatsSection({super.key});

  @override
  State<ProfileStatsSection> createState() => _ProfileStatsSectionState();
}

class _ProfileStatsSectionState extends State<ProfileStatsSection> {
  int achievementDays = 0;

  @override
  void initState() {
    super.initState();
    _loadTotalAchievementDays();
  }

  Future<void> _loadTotalAchievementDays() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      // 今までのすべての学習記録を取得
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('studyRecords')
          .get();

      // goalAchieved が true の日だけ数える
      final count = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['goalAchieved'] == true;
      }).length;

      if (!mounted) return;

      setState(() {
        achievementDays = count;
      });
    } catch (e) {
      debugPrint('総合目標達成日数の取得に失敗しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 34),
      child: Row(
        children: [
          const Expanded(
            child: _ProfileStatItem(count: "0", label: "友達"),
          ),

          Container(width: 1, height: 16, color: Colors.grey.shade300),

          const Expanded(
            child: _ProfileStatItem(count: "0", label: "応援"),
          ),

          Container(width: 1, height: 16, color: Colors.grey.shade300),

          Expanded(
            child: _ProfileStatItem(
              count: achievementDays.toString(),
              label: "目標達成",
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatItem extends StatelessWidget {
  final String count;
  final String label;

  const _ProfileStatItem({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.roboto(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3D96E8),
          ),
        ),

        const SizedBox(height: 1),

        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ======================================================
// プロフィール項目
// ======================================================
class _ProfileRow extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _ProfileRow({required this.title, required this.value, this.onTap});

  static const Color primaryBlue = Color(0xFF258EDB);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
            ),

            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),

            const SizedBox(width: 5),

            const Icon(Icons.chevron_right, color: primaryBlue, size: 25),
          ],
        ),
      ),
    );
  }
}
