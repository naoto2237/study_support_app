import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:study_support_app/setting_screen.dart';
import 'mypage_screen2.dart';

class MypageScreen extends StatefulWidget {
  final String? targetUserId; // 他人のプロフィールを表示する場合のUID（省略時は自分）

  const MypageScreen({super.key, this.targetUserId});

  static const Color primaryBlue = Color(0xFF258EDB);

  @override
  State<MypageScreen> createState() => _MypageScreenState();
}

class _MypageScreenState extends State<MypageScreen> {
  final ScrollController _scrollController = ScrollController();

  double _scrollOffset = 0;

  // FirebaseのStreamはinitStateで1回だけ作成する。
  // スクロールによるsetStateで再作成されないようにする。
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream;
  bool _isMyPage = true;

  @override
  void initState() {
    super.initState();

    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUid = currentUser?.uid;

    // 表示する対象のUIDを決定（指定がなければ自分のUID）
    final String uidToFetch =
        (widget.targetUserId != null && widget.targetUserId!.isNotEmpty)
        ? widget.targetUserId!
        : (currentUid ?? '');

    // 自分のマイページかどうかの判定
    if (widget.targetUserId == null ||
        widget.targetUserId!.isEmpty ||
        (currentUid != null && widget.targetUserId == currentUid)) {
      _isMyPage = true;
    } else {
      _isMyPage = (currentUid != null && uidToFetch == currentUid);
    }

    if (uidToFetch.isNotEmpty) {
      _userStream = FirebaseFirestore.instance
          .collection("users")
          .doc(uidToFetch)
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
                          ProfileContent(
                            data: data,
                            isMyPage: _isMyPage, // 自分のページかどうかのフラグを渡す
                          ),
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
      // 他人のプロフィールを表示しているときは戻るボタン（←）を自動で出す
      automaticallyImplyLeading: !_isMyPage,
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
        // 自分のページのときだけ設定アイコンを表示
        if (_isMyPage)
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
      height: 123.5,
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
                                        0xFF258EDB,
                                      ).withOpacity(0.12),
                                      child: Icon(
                                        Icons.person,
                                        size: iconSize * 0.65,
                                        color: const Color(0xFF258EDB),
                                      ),
                                    ),
                            ),
                          ),
                        ),
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
