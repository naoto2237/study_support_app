import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
                            otherUserId: widget.userId,
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

class OtherProfileContent extends StatefulWidget {
  final Map<String, dynamic> data;

  // 表示している相手のFirebase UID
  final String otherUserId;

  const OtherProfileContent({
    super.key,
    required this.data,
    required this.otherUserId,
  });

  @override
  State<OtherProfileContent> createState() =>
      _OtherProfileContentState();
}

class _OtherProfileContentState
    extends State<OtherProfileContent> {

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  bool _processing = false;

  // ==========================================================
  // 自分のUID
  // ==========================================================

  String? get myUid {
    return _auth.currentUser?.uid;
  }

  // ==========================================================
  // 相手のUID
  // ==========================================================

  String get otherUid {
    return widget.otherUserId;
  }

  @override
  Widget build(BuildContext context) {

    final String grade =
        widget.data["grade"] ?? "未設定";

    final String goal =
        widget.data["goal"] ?? "未設定";

    final String location =
        widget.data["location"] ?? "未設定";

    final String studyStyle =
        widget.data["studyStyle"] ?? "未設定";

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
            widget.data["comment"] ?? "",

            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),

            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 18),

          // ======================================================
          // フレンドボタン
          // ======================================================

          SizedBox(
            width: double.infinity,

            child: _buildFriendButton(),
          ),

          const SizedBox(height: 12),

          // ======================================================
          // プロフィール分析
          // ======================================================

          SizedBox(
            width: double.infinity,

            child: _OtherActionButton(
              icon: Icons.bar_chart_rounded,
              text: "プロフィール分析",

              onTap: () {
                // 後で実装
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

  // ==========================================================
  // フレンド状態を監視
  // ==========================================================

  Stream<String> _friendStatusStream() async* {

    final String? me = myUid;

    final String other = otherUid;

    // ログインしていない
    if (me == null) {
      yield "none";
      return;
    }

    // 自分自身
    if (me == other) {
      yield "self";
      return;
    }

    // ========================================================
    // ① 自分 → 相手
    // ========================================================

    final sentSnapshot = await _firestore
        .collection("friendRequests")
        .where(
      "fromUserId",
      isEqualTo: me,
    )
        .where(
      "toUserId",
      isEqualTo: other,
    )
        .limit(1)
        .get();

    if (sentSnapshot.docs.isNotEmpty) {

      final data =
      sentSnapshot.docs.first.data();

      if (data["status"] == "pending") {
        yield "sent";
        return;
      }

      if (data["status"] == "accepted") {
        yield "friend";
        return;
      }
    }

    // ========================================================
    // ② 相手 → 自分
    // ========================================================

    final receivedSnapshot = await _firestore
        .collection("friendRequests")
        .where(
      "fromUserId",
      isEqualTo: other,
    )
        .where(
      "toUserId",
      isEqualTo: me,
    )
        .limit(1)
        .get();

    if (receivedSnapshot.docs.isNotEmpty) {

      final data =
      receivedSnapshot.docs.first.data();

      if (data["status"] == "pending") {
        yield "received";
        return;
      }

      if (data["status"] == "accepted") {
        yield "friend";
        return;
      }
    }

    // ========================================================
    // ③ 何もない
    // ========================================================

    yield "none";
  }

  // ==========================================================
  // フレンドボタン
  // ==========================================================

  Widget _buildFriendButton() {

    return StreamBuilder<String>(
      stream: _friendStatusStream(),

      builder: (context, snapshot) {

        if (snapshot.connectionState ==
            ConnectionState.waiting) {

          return Container(
            height: 56,

            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius:
              BorderRadius.circular(30),
            ),

            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,

                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }

        final status =
            snapshot.data ?? "none";

        // ======================================================
        // 自分自身
        // ======================================================

        if (status == "self") {

          return _FriendButton(
            icon: Icons.person,
            text: "自分のプロフィール",
            color: Colors.grey,
            enabled: false,
            onTap: () {},
          );
        }

        // ======================================================
        // フレンド
        // ======================================================

        if (status == "friend") {

          return _FriendButton(
            icon: Icons.people,
            text: "フレンド",
            color: Colors.grey,
            enabled: false,
            onTap: () {},
          );
        }

        // ======================================================
        // 自分から申請中
        // ======================================================

        if (status == "sent") {

          return _FriendButton(
            icon: Icons.hourglass_top,
            text: "申請中",
            color: Colors.grey,
            enabled: true,

            onTap: () {
              _cancelFriendRequest();
            },
          );
        }

        // ======================================================
        // 相手から申請されている
        // ======================================================

        if (status == "received") {

          return _FriendButton(
            icon: Icons.person_add,
            text: "申請を承認する",
            color: ProfileScreen.primaryBlue,
            enabled: true,

            onTap: () {
              _acceptFriendRequest();
            },
          );
        }

        // ======================================================
        // 未申請
        // ======================================================

        return _FriendButton(
          icon: Icons.person_add_alt_1,
          text: "フレンド申請",
          color: ProfileScreen.primaryBlue,
          enabled: true,

          onTap: () {
            _sendFriendRequest();
          },
        );
      },
    );
  }

  // ==========================================================
  // フレンド申請
  // ==========================================================

  Future<void> _sendFriendRequest() async {
    if (_processing) return;

    final String? me = myUid;
    final String other = otherUid;

    if (me == null) {
      _showMessage("ログインしてください");
      return;
    }

    if (me == other) {
      _showMessage("自分自身には申請できません");
      return;
    }

    // ========================================================
    // 確認ダイアログ
    // ========================================================

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final name = widget.data["name"] ?? "このユーザー";

        return AlertDialog(
          title: const Text("フレンド申請"),
          content: Text("$nameさんにフレンド申請を送りますか？"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("キャンセル"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("申請する"),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    setState(() {
      _processing = true;
    });

    try {
      // ========================================================
      // 既に自分から申請しているか確認
      // ========================================================

      final existing = await _firestore
          .collection("friendRequests")
          .where(
        "fromUserId",
        isEqualTo: me,
      )
          .where(
        "toUserId",
        isEqualTo: other,
      )
          .where(
        "status",
        isEqualTo: "pending",
      )
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        _showMessage("すでに申請しています");
        return;
      }

      // ========================================================
      // 相手からの申請があるか確認
      // ========================================================

      final received = await _firestore
          .collection("friendRequests")
          .where(
        "fromUserId",
        isEqualTo: other,
      )
          .where(
        "toUserId",
        isEqualTo: me,
      )
          .where(
        "status",
        isEqualTo: "pending",
      )
          .limit(1)
          .get();

      if (received.docs.isNotEmpty) {
        _showMessage(
          "相手からすでにフレンド申請が届いています",
        );
        return;
      }

      // ========================================================
      // フレンド申請を作成
      // ========================================================

      final requestRef = await _firestore
          .collection("friendRequests")
          .add({
        "fromUserId": me,
        "toUserId": other,
        "status": "pending",
        "createdAt": FieldValue.serverTimestamp(),
      });

      // ========================================================
      // 自分の名前を取得
      // ========================================================

      final myUserDoc = await _firestore
          .collection("users")
          .doc(me)
          .get();

      final myData = myUserDoc.data();

      final String myName =
          myData?["name"] ?? "ユーザー";

      // ========================================================
      // 通知を作成
      // ========================================================

      await _firestore
          .collection("notifications")
          .add({
        // 通知を受け取る人
        "toUserId": other,

        // 通知を送った人
        "fromUserId": me,

        // 通知の種類
        "type": "friend_request",

        // 通知タイトル
        "title": "フレンド申請",

        // 通知本文
        "message": "$myNameさんからフレンド申請が届きました",

        // 元になったフレンド申請
        "requestId": requestRef.id,

        // 未読
        "read": false,

        // 作成日時
        "createdAt": FieldValue.serverTimestamp(),
      });

      _showMessage(
        "フレンド申請を送信しました",
      );
    } catch (e) {
      debugPrint("フレンド申請エラー: $e");

      _showMessage(
        "申請に失敗しました",
      );
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  // ==========================================================
  // 申請を取り消す
  // ==========================================================

  Future<void> _cancelFriendRequest() async {

    final String? me = myUid;

    if (me == null) return;

    try {

      final snapshot = await _firestore
          .collection("friendRequests")
          .where(
        "fromUserId",
        isEqualTo: me,
      )
          .where(
        "toUserId",
        isEqualTo: otherUid,
      )
          .where(
        "status",
        isEqualTo: "pending",
      )
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      final requestId =
          snapshot.docs.first.id;

      await _firestore
          .collection("friendRequests")
          .doc(requestId)
          .delete();

      _showMessage(
        "フレンド申請を取り消しました",
      );

    } catch (e) {

      _showMessage(
        "申請の取り消しに失敗しました",
      );
    }
  }

  // ==========================================================
  // フレンド申請を承認
  // ==========================================================

  Future<void> _acceptFriendRequest() async {

    final String? me = myUid;

    if (me == null) return;

    try {

      // ========================================================
      // 相手から届いた申請を取得
      // ========================================================

      final snapshot = await _firestore
          .collection("friendRequests")
          .where(
        "fromUserId",
        isEqualTo: otherUid,
      )
          .where(
        "toUserId",
        isEqualTo: me,
      )
          .where(
        "status",
        isEqualTo: "pending",
      )
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {

        _showMessage(
          "申請が見つかりません",
        );

        return;
      }

      final requestId =
          snapshot.docs.first.id;

      // ========================================================
      // Transaction
      // ========================================================

      await _firestore.runTransaction(
            (transaction) async {

          final requestRef =
          _firestore
              .collection("friendRequests")
              .doc(requestId);

          final friendRef =
          _firestore
              .collection("friends")
              .doc();

          // 申請を承認済みにする
          transaction.update(
            requestRef,
            {
              "status": "accepted",
              "acceptedAt":
              FieldValue.serverTimestamp(),
            },
          );

          // フレンド登録
          transaction.set(
            friendRef,
            {
              "user1": otherUid,
              "user2": me,
              "createdAt":
              FieldValue.serverTimestamp(),
            },
          );
        },
      );

      _showMessage(
        "フレンドになりました！",
      );

    } catch (e) {

      _showMessage(
        "承認に失敗しました",
      );
    }
  }

  // ==========================================================
  // SnackBar
  // ==========================================================

  void _showMessage(String message) {

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
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

class _FriendButton extends StatelessWidget {

  final IconData icon;
  final String text;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _FriendButton({
    required this.icon,
    required this.text,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return InkWell(
      borderRadius:
      BorderRadius.circular(30),

      onTap: enabled
          ? onTap
          : null,

      child: Container(
        height: 56,

        decoration: BoxDecoration(
          color: enabled
              ? color
              : Colors.grey.shade100,

          borderRadius:
          BorderRadius.circular(30),

          border: !enabled
              ? Border.all(
            color: Colors.grey.shade300,
          )
              : null,
        ),

        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [

            Icon(
              icon,

              color: enabled
                  ? Colors.white
                  : Colors.grey,

              size: 23,
            ),

            const SizedBox(width: 8),

            Text(
              text,

              style: TextStyle(
                color: enabled
                    ? Colors.white
                    : Colors.grey,

                fontSize: 14,

                fontWeight:
                FontWeight.bold,
              ),
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

