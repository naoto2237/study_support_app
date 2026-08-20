import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({
    super.key,
    required this.userId,
  });

  static const Color primaryBlue = Color(0xFF3D96E8);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ScrollController _scrollController = ScrollController();

  double _scrollOffset = 0;

  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream;

  @override
  void initState() {
    super.initState();

    // 選択したユーザーの情報を取得
    _userStream = FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .snapshots();

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
          // 読み込み中
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // エラー
          if (snapshot.hasError) {
            return const Center(
              child: Text("ユーザー情報の取得に失敗しました"),
            );
          }

          // データなし
          if (!snapshot.hasData) {
            return const Center(
              child: Text("ユーザー情報が見つかりません"),
            );
          }

          // ユーザーが存在しない
          if (!snapshot.data!.exists) {
            return const Center(
              child: Text("このユーザーは存在しません"),
            );
          }

          final data = snapshot.data!.data()!;

          return Stack(
            children: [

              // ======================================================
              // 背景画像
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
              // プロフィール本体
              // ======================================================
              SingleChildScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),

                child: Column(
                  children: [

                    // 背景画像を見せるためのスペース
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

                          // プロフィールヘッダー
                          OtherProfileHeader(
                            data: data,
                            scrollOffset: _scrollOffset,
                          ),

                          // プロフィール内容
                          OtherProfileContent(
                            data: data,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ======================================================
              // 上部AppBar
              // ======================================================
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildAppBar(data),
              ),
            ],
          );
        },
      ),
    );
  }

  // ======================================================
  // AppBar
  // ======================================================

  Widget _buildAppBar(Map<String, dynamic> data) {
    final String name = data["name"] ?? "名前未設定";

    final bool showAppBar = _scrollOffset >= 222;

    final double iconProgress =
    ((_scrollOffset - 150) / 72).clamp(0.0, 1.0);

    return AppBar(
      automaticallyImplyLeading: false,

      centerTitle: true,

      elevation: 0,

      scrolledUnderElevation: 0,

      backgroundColor:
      showAppBar ? Colors.white : Colors.transparent,

      // 左側に戻るボタン
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: Color.lerp(
            Colors.white,
            Colors.black87,
            iconProgress,
          ),
        ),

        onPressed: () {
          Navigator.pop(context);
        },
      ),

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
    );
  }
}


// ======================================================
// 他ユーザーのプロフィールヘッダー
// ======================================================

class OtherProfileHeader extends StatelessWidget {
  final Map<String, dynamic> data;
  final double scrollOffset;

  const OtherProfileHeader({
    super.key,
    required this.data,
    required this.scrollOffset,
  });

  @override
  Widget build(BuildContext context) {
    final String name =
        data["name"] ?? "名前未設定";

    final String icon =
        data["icon"] ?? "";

    // スクロールに合わせてアイコンを小さくする
    final double iconProgress =
    (scrollOffset / 562).clamp(0.0, 1.0);

    final double iconSize =
        15.5 + (95 - 15.5) * (1 - iconProgress);

    return SizedBox(
      height: 145,

      child: Stack(
        clipBehavior: Clip.none,

        children: [

          // ======================================================
          // アイコン
          // ======================================================

          Positioned(
            top: -47.5,
            left: 0,
            right: 0,

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [

                SizedBox(
                  width: iconSize,
                  height: iconSize,

                  child: Container(
                    width: iconSize,
                    height: iconSize,

                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),

                    child: Padding(
                      padding: EdgeInsets.all(
                        iconSize > 20 ? 3 : 0,
                      ),

                      child: ClipOval(
                        child: icon.isNotEmpty
                            ? Image.network(
                          icon,
                          width: iconSize,
                          height: iconSize,
                          fit: BoxFit.cover,

                          errorBuilder:
                              (context, error, stackTrace) {
                            return Container(
                              color: const Color(
                                0xFF3D96E8,
                              ).withOpacity(0.12),

                              child: Icon(
                                Icons.person,
                                size: iconSize * 0.65,
                                color: const Color(
                                  0xFF3D96E8,
                                ),
                              ),
                            );
                          },
                        )

                            : Container(
                          color: const Color(
                            0xFF3D96E8,
                          ).withOpacity(0.12),

                          child: Icon(
                            Icons.person,
                            size: iconSize * 0.65,
                            color: const Color(
                              0xFF3D96E8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // 名前・ユーザーID
          // ======================================================

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
// 他ユーザーのプロフィール内容
// ======================================================

class OtherProfileContent extends StatelessWidget {
  final Map<String, dynamic> data;

  const OtherProfileContent({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {

    final String grade =
        data["grade"] ?? "未設定";

    final String goal =
        data["goal"] ?? "未設定";

    final String location =
        data["location"] ?? "未設定";

    final String studyStyle =
        data["studyStyle"] ?? "未設定";

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
      ),

      child: Column(
        children: [

          // ======================================================
          // 一言コメント
          // ======================================================

          Text(
            data["comment"] ?? "",

            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),

            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 18),

          // ======================================================
          // プロフィール分析
          // ======================================================

          SizedBox(
            width: double.infinity,

            child: _OtherActionButton(
              icon: Icons.bar_chart_rounded,
              text: "プロフィール分析",

              onTap: () {
                // 後でプロフィール分析機能を追加
              },
            ),
          ),

          const SizedBox(height: 18),

          // ======================================================
          // プロフィール情報
          // ======================================================

          _OtherProfileRow(
            icon: Icons.school,
            title: "学年・職種（任意）",
            value: grade,
          ),

          _OtherProfileRow(
            icon: Icons.track_changes,
            title: "学習目標",
            value: goal,
          ),

          _OtherProfileRow(
            icon: Icons.location_on,
            title: "住んでいる場所（任意）",
            value: location,
          ),

          _OtherProfileRow(
            icon: Icons.schedule,
            title: "勉強スタイル",
            value: studyStyle,
          ),

          const SizedBox(height: 20),

          // ======================================================
          // 学習時間
          // ======================================================

          const OtherStudyTimeSection(),

          const SizedBox(height: 200),
        ],
      ),
    );
  }
}


// ======================================================
// プロフィール分析ボタン
// ======================================================

class _OtherActionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _OtherActionButton({
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
            color: ProfileScreen.primaryBlue
                .withOpacity(0.25),

            width: 1.5,
          ),
        ),

        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [

            const Icon(
              Icons.bar_chart_rounded,
              color: ProfileScreen.primaryBlue,
              size: 25,
            ),

            const SizedBox(width: 8),

            Flexible(
              child: Text(
                text,

                style: const TextStyle(
                  color: ProfileScreen.primaryBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),

                overflow:
                TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 5),

            const Icon(
              Icons.chevron_right,
              color: ProfileScreen.primaryBlue,
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

class _OtherProfileRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _OtherProfileRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 81,

      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),

      child: Row(
        children: [

          Container(
            width: 46,
            height: 46,

            decoration: BoxDecoration(
              shape: BoxShape.circle,

              color: ProfileScreen.primaryBlue
                  .withOpacity(0.10),
            ),

            child: Icon(
              icon,
              color: ProfileScreen.primaryBlue,
              size: 24,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,

              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Text(
                  title,

                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
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
            color: ProfileScreen.primaryBlue,
            size: 25,
          ),
        ],
      ),
    );
  }
}


// ======================================================
// 学習時間
// ======================================================

class OtherStudyTimeSection extends StatelessWidget {
  const OtherStudyTimeSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        Row(
          children: [

            const Icon(
              Icons.access_time,
              color: ProfileScreen.primaryBlue,
              size: 23,
            ),

            const SizedBox(width: 7),

            const Expanded(
              child: Text(
                "今週・今月の総学習時間 ✨",

                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color: ProfileScreen.primaryBlue,
              size: 22,
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [

            Expanded(
              child: _OtherStudyTimeBox(
                title: "今週の学習時間",
                time: "12時間45分",
                target: "目標 20時間",
                percent: "62%",
                progress: 0.62,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: _OtherStudyTimeBox(
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

class _OtherStudyTimeBox extends StatelessWidget {
  final String title;
  final String time;
  final String target;
  final String percent;
  final double progress;

  const _OtherStudyTimeBox({
    required this.title,
    required this.time,
    required this.target,
    required this.percent,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 14,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(12),

        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Column(
        children: [

          Text(
            title,

            style: const TextStyle(
              color: ProfileScreen.primaryBlue,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            time,

            style: const TextStyle(
              color: ProfileScreen.primaryBlue,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius:
            BorderRadius.circular(10),

            child: LinearProgressIndicator(
              value: progress,

              minHeight: 6,

              backgroundColor:
              Colors.grey.shade200,

              valueColor:
              const AlwaysStoppedAnimation<Color>(
                ProfileScreen.primaryBlue,
              ),
            ),
          ),

          const SizedBox(height: 9),

          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,

            children: [

              Text(
                target,
                style: const TextStyle(
                  fontSize: 11,
                ),
              ),

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