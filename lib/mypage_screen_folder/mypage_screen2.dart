import 'package:flutter/material.dart';
import 'profile_edit_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../record_screen_folder/record_myrecord_screen_folder/record_myrecord_screen3.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'friend_request_screen.dart';

class MypageScreen2 extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMyPage;
  final String userId;

  const MypageScreen2({
    super.key,
    required this.data,
    required this.isMyPage,
    required this.userId,
  });

  static const Color primaryBlue = Color(0xFF258EDB);

  void _openEditScreen(BuildContext context) {
    if (!isMyPage) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileEditScreen(data: data)),
    );
  }

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
        // 自分のページだけ表示
        // ------------------------------------------
        // ------------------------------------------
        // プロフィールアクション
        // 自分・相手で表示を切り替える
        // ------------------------------------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: isMyPage
                      ? Icons.bar_chart_rounded
                      : Icons.person_add_alt_1,
                  text: isMyPage ? "プロフィール分析" : "友達申請",
                  backgroundColor: Colors.grey.shade200,
                  onTap: () {
                    if (isMyPage) {
                      // プロフィール分析
                    } else {
                      FriendRequestScreen.show(
                        context,
                        userId: userId,
                        data: data,
                      );
                    }
                  },
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: _ActionButton(
                  icon: isMyPage ? Icons.edit : Icons.chat_outlined,
                  text: isMyPage ? "プロフィール編集" : "メッセージ",
                  backgroundColor: Colors.grey.shade200,
                  onTap: () {
                    if (isMyPage) {
                      _openEditScreen(context);
                    } else {
                      // チャット画面へ移動
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12.5),

        // ------------------------------------------
        // プロフィール統計
        // 自分・相手の両方に表示
        // ------------------------------------------
        ProfileStatsSection(userId: userId),

        const SizedBox(height: 15),

        // ------------------------------------------
        // 一言コメント【共通】
        // ------------------------------------------
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

        // ------------------------------------------
        // 境界線【共通】
        // ------------------------------------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE5E7EB),
          ),
        ),

        const SizedBox(height: 11),

        // ------------------------------------------
        // プロフィール見出し【共通】
        // ------------------------------------------
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
        // プロフィール項目【共通】
        // 自分のときだけタップして編集可能
        // ------------------------------------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              _ProfileRow(
                title: "学年・職種（任意）",
                value: grade,
                onTap: isMyPage ? () => _openEditScreen(context) : null,
              ),

              _ProfileRow(
                title: "学習目標",
                value: goal,
                onTap: isMyPage ? () => _openEditScreen(context) : null,
              ),

              _ProfileRow(
                title: "自由項目①",
                value: location,
                onTap: isMyPage ? () => _openEditScreen(context) : null,
              ),

              _ProfileRow(
                title: "自由項目②",
                value: studyStyle,
                onTap: isMyPage ? () => _openEditScreen(context) : null,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ------------------------------------------
        // 学習時間【共通】
        // ------------------------------------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: RecordMyRecordScreen3(
            cardColor: Colors.white,
            textColor: Colors.black87,
            secondaryColor: Colors.black54,
            userId: userId,
          ),
        ),

        SizedBox(height: isMyPage ? 140 : 200),
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
  final String userId;

  const ProfileStatsSection({super.key, required this.userId});

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
          .doc(widget.userId)
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
                style: const TextStyle(fontSize: 15, color: primaryBlue),
              ),
            ),

            Text(value, style: const TextStyle(fontSize: 15)),

            const SizedBox(width: 5),

            const Icon(Icons.chevron_right, color: primaryBlue, size: 25),
          ],
        ),
      ),
    );
  }
}
