import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:study_support_app/setting_screen.dart';
import 'profile_edit_screen.dart';
import 'package:study_support_app/chat_list_screen.dart';

class MypageScreen extends StatefulWidget {
  const MypageScreen({super.key});

  static const Color primaryBlue = Color(0xFF3D96E8);

  @override
  State<MypageScreen> createState() => _MypageScreenState();
}

class _MypageScreenState extends State<MypageScreen> {
  final ScrollController _scrollController = ScrollController();

  double _scrollOffset = 0;

  // FirebaseのStreamはinitStateで1回だけ作成する。
  // スクロールによるsetStateで再作成されないようにする。
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      _userStream = FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .snapshots();
    } else {
      _userStream = const Stream.empty();
    }

    _scrollController.addListener(() {
      if (!mounted) return;

      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("ユーザー情報の取得に失敗しました"));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("ログインしてください"));
          }

          if (!snapshot.data!.exists) {
            return const Center(child: Text("ユーザー情報が見つかりません"));
          }

          final data = snapshot.data!.data()!;

          return Stack(
            children: [
              // ======================================================
              // ① 背景画像
              //    ここはスクロールの外に置くので動かない
              // ======================================================
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 335,
                child: Image.asset(
                  'assets/images/haikei8.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),

              // ======================================================
              // ③ 白い部分＋プロフィール内容
              //    ここだけスクロールする
              // ======================================================
              SingleChildScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    // 背景画像を見せるための上部スペース
                    const SizedBox(height: 236),

                    // --------------------------------------------------
                    // 白いプロフィールエリア
                    // --------------------------------------------------
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        children: [
                          ProfileHeader(
                            data: data,
                            scrollOffset: _scrollOffset,
                          ),
                          ProfileContent(data: data),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ======================================================
              // ④ スクロール時のAppBar
              //    IgnorePointerでスクロール操作を邪魔しない
              // ======================================================
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildScrollAppBar(data),
              ),
            ],
          );
        },
      ),
    );
  }

  // ======================================================
  // スクロール時のAppBar
  // ======================================================
  Widget _buildScrollAppBar(Map<String, dynamic> data) {
    final String name = data["name"] ?? "名前未設定";

    final bool showAppBar = _scrollOffset >= 222;

    final double iconProgress = ((_scrollOffset - 150) / 72).clamp(0.0, 1.0);

    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: showAppBar ? Colors.white : Colors.transparent,

      title: showAppBar
          ? Text(
              name,
              style: const TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            )
          : null,

      actions: [

        Padding(
          padding: const EdgeInsets.only(right: 7),
          child: IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: Color.lerp(Colors.white, Colors.black87, iconProgress),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ======================================================
// 上部プロフィールヘッダー
// ======================================================

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> data;
  final double scrollOffset;

  const ProfileHeader({
    super.key,
    required this.data,
    required this.scrollOffset,
  });

  @override
  Widget build(BuildContext context) {
    final String name = data["name"] ?? "名前未設定";
    final String icon = data["icon"] ?? "";

    // ------------------------------------------
    // スクロールに合わせてアイコンを小さくする
    // ------------------------------------------
    final double iconProgress = (scrollOffset / 562).clamp(0.0, 1.0);

    final double iconSize = 15.5 + (95 - 15.5) * (1 - iconProgress);

    return SizedBox(
      height: 145,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ------------------------------------------
          // アイコン・名前・ユーザーID
          // ------------------------------------------
          Positioned(
            top: -47.5,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ------------------------------------------
                // プロフィールアイコン
                // ------------------------------------------
                Transform.translate(
                  offset: const Offset(0, 0),
                  child: SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // ------------------------------------------
                        // アイコン本体
                        // ------------------------------------------
                        Container(
                          width: iconSize,
                          height: iconSize,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(iconSize > 20 ? 3 : 0),
                            child: ClipOval(
                              child: icon.isNotEmpty
                                  ? Image.network(
                                      icon,
                                      width: iconSize,
                                      height: iconSize,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: const Color(
                                        0xFF3D96E8,
                                      ).withOpacity(0.12),
                                      child: Icon(
                                        Icons.person,
                                        size: iconSize * 0.65,
                                        color: const Color(0xFF3D96E8),
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        /*
                        // ------------------------------------------
                        // カメラアイコン
                        // ------------------------------------------
                        if (iconSize > 25)
                          Positioned(
                            right: -2,
                            bottom: 2,
                            child: Container(
                              width: 38 * (iconSize / 94),
                              height: 38 * (iconSize / 94),
                              decoration: const BoxDecoration(
                                color: MypageScreen.primaryBlue,
                                shape: BoxShape.circle,
                                border: Border.fromBorderSide(
                                  BorderSide(color: Colors.white, width: 3),
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 19 * (iconSize / 94),
                              ),
                            ),
                          ),*/
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ------------------------------------------
          // 名前・ユーザーID
          // ------------------------------------------
          Positioned(
            top: 51.5,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    data["userId"] ?? "",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
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

          const SizedBox(height: 200),
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
