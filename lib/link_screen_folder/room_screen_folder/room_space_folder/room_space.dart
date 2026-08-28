import 'package:flutter/material.dart';
import 'dart:async';
import 'room_chat_screen.dart';
import 'room_member_screen.dart';
import 'room_sharenote_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'wallpaper_adjust_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoomSpaceScreen extends StatefulWidget {
  final String roomTitle;
  final String roomId;
  final String backgroundImage;

  const RoomSpaceScreen({
    super.key,
    required this.roomTitle,
    required this.roomId,
    this.backgroundImage = 'assets/images/haikei5.png',
  });

  @override
  State<RoomSpaceScreen> createState() => _RoomSpaceScreenState();
}

class _RoomSpaceScreenState extends State<RoomSpaceScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            const SizedBox(height: 3),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17),
              child: _buildTopStudyCard(),
            ),

            const SizedBox(height: 0.0),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17),
              child: _buildRoomFeatureButtons(),
            ),

            const SizedBox(height: 15.0),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17),
              child: _buildMembersAndActivity(),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,

      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE5E7EB)),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          /* image: DecorationImage(
            image: AssetImage(widget.backgroundImage),
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
          ),*/
        ),
      ),

      leading: IconButton(
        icon: const Icon(Icons.arrow_back, size: 24, color: Colors.black87),
        onPressed: _showExitDialog,
      ),

      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.roomTitle,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          _buildMemberCount(),
        ],
      ),

      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 7),
          child: IconButton(
            icon: const Icon(Icons.more_vert, size: 24, color: Colors.black87),
            onPressed: _showMenu,
          ),
        ),
      ],
    );
  }

  Widget _buildMemberCount() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('members')
          .snapshots(),
      builder: (context, snapshot) {
        final count =
            snapshot.data?.docs.length ?? 0;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.public,
              size: 15,
              color: Colors.black54,
            ),
            const SizedBox(width: 4),
            Text(
              "公開ルーム・${count}人参加中",
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopStudyCard() {
    return Container(
      width: double.infinity,
      height: 245,
      //padding: const EdgeInsets.only(left: 18, right: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        //border: Border.all(color: const Color(0xFFE5E7EB)),
        /*boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 5,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
        ],:*/
      ),
      child: SizedBox(
        height: 230,
        child: Row(
          children: [
            // 左：タイマー
            Expanded(flex: 3, child: _buildTimer()),

            const SizedBox(width: 0),

            SizedBox(
              height: 205,
              child: VerticalDivider(
                width: 1,
                thickness: 1,
                color: const Color(0xFFE5E7EB),
              ),
            ),

            const SizedBox(width: 0),

            // 右：学習情報
            Expanded(flex: 2, child: _buildStudyInfoCard()),
          ],
        ),
      ),
    );
  }

  Widget _buildTimer() {
    return SizedBox(
      width: 220,
      height: 220,
      child: Transform.translate(
        offset: const Offset(-8, 0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 進捗バー
            SizedBox(
              width: 198,
              height: 198,
              child: CircularProgressIndicator(
                value: 0.45,
                strokeWidth: 7.1,
                strokeCap: StrokeCap.round,
                backgroundColor: const Color(0xFFC9E9FF),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF258EDB)),
              ),
            ),

            // 中央
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.translate(
                  offset: const Offset(0, 13),
                  child: const Text(
                    "学習タイマー",
                    style: TextStyle(
                      fontSize: 13.3,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

                const SizedBox(height: 0.4),

                Transform.translate(
                  offset: const Offset(0, 11.6),
                  child: Text(
                    _formatTime(),
                    style: GoogleFonts.roboto(
                      color: Color(0xFF258EDB),
                      fontSize: 35.2,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.9,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                Transform.translate(
                  offset: const Offset(0, 11.4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStartButton(),
                      const SizedBox(width: 24),
                      _buildResetButton(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: () {
        if (_stopwatch.isRunning) {
          _stop();
        } else {
          _start();
        }
      },
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFF258EDB),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _stopwatch.isRunning
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return GestureDetector(
      onTap: _reset,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
            ),
            child: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF258EDB),
              size: 28,
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(left: 11, right: 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Transform.translate(
                  offset: const Offset(0, 1),
                  child: Icon(icon, color: iconColor, size: 17),
                ),

                const SizedBox(width: 6),

                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyInfoCard() {
    return SizedBox(
      height: 220,
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.flag_rounded,
            title: "今日の目標",
            value: "3時間",
            iconColor: const Color(0xFFFF2D55),
          ),

          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 0),
              child: SizedBox(
                width: 120,
                child: const Divider(height: 1, color: Color(0xFFE5E7EB)),
              ),
            ),
          ),

          _buildInfoRow(
            icon: Icons.hourglass_empty,
            title: "目標まで残り",
            value: "45分",
            iconColor: const Color(0xFF258EDB),
          ),

          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 0),
              child: SizedBox(
                width: 120,
                child: const Divider(height: 1, color: Color(0xFFE5E7EB)),
              ),
            ),
          ),

          _buildInfoRow(
            icon: Icons.timer_outlined,
            title: "今日の学習時間",
            value: "2時間15分",
            iconColor: const Color(0xFF258EDB),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // メンバー・チャット・共有ノートの3つのボタン
  // =========================================================
  Widget _buildRoomFeatureButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildFeatureButton(
            icon: Icons.groups_rounded,
            title: "メンバー",
            iconColor: const Color(0xFF258EDB),
            iconSize: 36,
            onTap: () {
              _openFeatureScreen(
                title: "メンバー",
                icon: Icons.groups_rounded,
                child: RoomMemberScreen(
                  roomId: widget.roomId,
                ),

              );
            },
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _buildFeatureButton(
            icon: Icons.chat_rounded,
            title: "チャット",

            iconColor: const Color(0xFF258EDB),
            badge: "3",
            iconSize: 29,
            onTap: () {
              _openFeatureScreen(
                title: "チャット",
                icon: Icons.chat_rounded,
                child: RoomChatScreen(roomId: widget.roomId),
              );
            },
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _buildFeatureButton(
            icon: Icons.description_rounded,
            title: "共有ノート",

            iconColor: const Color(0xFF258EDB),
            badge: "2",
            iconSize: 30,
            onTap: () {
              _openFeatureScreen(
                title: "共有ノート",
                icon: Icons.description_rounded,
                child: const RoomShareNoteScreen(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureButton({
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onTap,
    String? badge,
    required double iconSize, // ← 追加
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          height: 79,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            /* boxShadow: [
             BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],*/
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 2),
              SizedBox(
                width: 40,
                height: 35,
                child: Center(
                  child: Icon(icon, color: iconColor, size: iconSize),
                ),
              ),

              const SizedBox(height: 2),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembersAndActivity() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildMembersSummary(),
          ),

          const SizedBox(height: 16),

          Container(
            height: 1,
            width: double.infinity,
            color: const Color(0xFFE5E7EB),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildActivity(),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('members')
          .orderBy('joinedAt')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF258EDB),
              ),
            ),
          );
        }

        final memberDocs =
            snapshot.data?.docs ?? [];

        return Column(
          children: [
            // ==============================
            // タイトル
            // ==============================

            Row(
              children: [
                const Text(
                  "メンバー",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  "(${memberDocs.length}人)",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),

                const Spacer(),

                GestureDetector(
                  onTap: () {
                    _openFeatureScreen(
                      title: "メンバー",
                      icon: Icons.groups_rounded,
                      child: RoomMemberScreen(
                        roomId: widget.roomId,
                      ),
                    );
                  },
                  child: const Text(
                    "すべて見る",
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF258EDB),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 13),

            // ==============================
            // メンバー一覧
            // ==============================

            SizedBox(
              height: 105,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: memberDocs.length + 1,
                separatorBuilder: (_, __) {
                  return const SizedBox(width: 8);
                },
                itemBuilder: (context, index) {
                  // 最後は招待ボタン
                  if (index == memberDocs.length) {
                    return _buildInviteSummaryItem();
                  }

                  final uid =
                      memberDocs[index].id;

                  return _MemberSummaryUser(
                    uid: uid,
                    isOwner: index == 0,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMemberSummaryItem({
    required String name,
    required bool isOwner,
    required bool isOnline,
  }) {
    return SizedBox(
      width: 70,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF4FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF64A9ED),
                  size: 34,
                ),
              ),

              // オンライン表示
              if (isOnline && !isOwner)
                Positioned(
                  right: -1,
                  bottom: 1,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),

              // オーナーの王冠
              if (isOwner)
                const Positioned(
                  left: -4,
                  top: -5,
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFFFC107),
                    size: 20,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 5),

          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 3),

          if (isOwner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "オーナー",
                style: TextStyle(
                  fontSize: 9,
                  color: Color(0xFF258EDB),
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.circle, size: 7, color: Color(0xFF22C55E)),
                SizedBox(width: 3),
                Text(
                  "オンライン",
                  style: TextStyle(fontSize: 9, color: Colors.black54),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInviteSummaryItem() {
    return SizedBox(
      width: 70,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF90CAF9), width: 1.5),
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Color(0xFF258EDB),
              size: 30,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            "招待する",
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF258EDB),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "アクティビティ",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 13),

        _buildActivityItem(
          icon: Icons.play_arrow_rounded,
          iconColor: const Color(0xFF258EDB),
          name: "Aさん",
          text: "学習を開始しました",
          time: "10:32",
        ),

        const SizedBox(height: 11),

        _buildActivityItem(
          icon: Icons.description_rounded,
          iconColor: const Color(0xFF258EDB),
          name: "Bさん",
          text: "共有ノートを更新しました",
          time: "10:18",
        ),

        const SizedBox(height: 11),

        _buildActivityItem(
          icon: Icons.login_rounded,
          iconColor: const Color(0xFF258EDB),
          name: "Cさん",
          text: "ルームに参加しました",
          time: "09:54",
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconColor,
    required String name,
    required String text,
    required String time,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFFEAF4FF),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 19),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextSpan(
                  text: "  $text",
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),

        Text(time, style: const TextStyle(fontSize: 10, color: Colors.black45)),
      ],
    );
  }

  // =========================================================
  // 各機能を専用画面として開く
  // =========================================================
  void _openFeatureScreen({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _RoomFeatureScreen(
          title: title,
          icon: icon,
          backgroundImage: widget.backgroundImage,
          child: child,
          roomId: widget.roomId,
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("ルームを退出"),
          content: const Text("このルームから退出しますか？"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("キャンセル"),
            ),

            ElevatedButton(
              onPressed: () async {
                // ダイアログを閉じる
                Navigator.pop(dialogContext);

                try {
                  // 現在ログインしているユーザー
                  final user =
                      FirebaseAuth.instance.currentUser;

                  if (user == null) {
                    throw Exception(
                      "ログインユーザーが見つかりません",
                    );
                  }

                  // ==========================================
                  // membersから自分を削除
                  // ==========================================

                  await FirebaseFirestore.instance
                      .collection("rooms")
                      .doc(widget.roomId)
                      .collection("members")
                      .doc(user.uid)
                      .delete();

                  // ==========================================
                  // ルーム画面を閉じる
                  // ==========================================

                  if (!mounted) return;

                  Navigator.pop(context);
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        "ルームの退出に失敗しました\n$e",
                      ),
                    ),
                  );
                }
              },
              child: const Text("退出"),
            ),
          ],
        );
      },
    );
  }


  void _start() {
    if (_stopwatch.isRunning) return;

    _stopwatch.start();
    setState(() {});

    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _stop() {
    _stopwatch.stop();
    _timer?.cancel();
    setState(() {});
  }

  void _reset() {
    _stop();
    _stopwatch.reset();
    setState(() {});
  }

  String _formatTime() {
    final elapsed = _stopwatch.elapsed;

    final hours = elapsed.inHours.toString().padLeft(2, '0');
    final minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return "$hours:$minutes:$seconds";
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("ルーム情報を編集"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text("通知設定"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text("ルーム情報"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// =========================================================
// 専用画面の共通レイアウト
// =========================================================
class _RoomFeatureScreen extends StatefulWidget {
  final String title;
  final IconData icon;
  final String backgroundImage;
  final Widget child;
  final String roomId;

  const _RoomFeatureScreen({
    required this.title,
    required this.icon,
    required this.backgroundImage,
    required this.child,
    required this.roomId,
  });

  @override
  State<_RoomFeatureScreen> createState() => _RoomFeatureScreenState();
}

class _RoomFeatureScreenState extends State<_RoomFeatureScreen> {
  File? _selectedBackground;

  String? _savedBackgroundUrl;

  double _backgroundScale = 1.0;
  Offset _backgroundOffset = Offset.zero;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadWallpaper();
  }

  // 壁紙を選択
  Future<void> _changeWallpaper() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    final File selectedImage = File(image.path);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WallpaperAdjustScreen(image: selectedImage),
      ),
    );

    if (result == null) return;

    if (result is WallpaperAdjustmentResult) {
      setState(() {
        _selectedBackground = selectedImage;
        _backgroundScale = result.scale;
        _backgroundOffset = result.offset;
      });

      await _saveWallpaper(selectedImage, result.scale, result.offset);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('壁紙を保存しました'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadWallpaper() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      final key = base64Url.encode(utf8.encode('${user.uid}_${widget.roomId}'));

      final path = prefs.getString('wallpaper_path_$key');

      if (path == null || path.isEmpty) {
        debugPrint('保存された壁紙はありません');
        return;
      }

      final file = File(path);

      // ファイルが実際に存在するか確認
      if (!await file.exists()) {
        debugPrint('保存された壁紙ファイルがありません');
        return;
      }

      final scale = prefs.getDouble('wallpaper_scale_$key') ?? 1.0;

      final offsetX = prefs.getDouble('wallpaper_offset_x_$key') ?? 0.0;

      final offsetY = prefs.getDouble('wallpaper_offset_y_$key') ?? 0.0;

      if (!mounted) return;

      setState(() {
        _selectedBackground = file;
        _backgroundScale = scale;
        _backgroundOffset = Offset(offsetX, offsetY);
      });

      debugPrint('壁紙を読み込みました');
    } catch (e) {
      debugPrint('壁紙読み込みエラー: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('壁紙の読み込みに失敗しました\n$e')));
    }
  }

  Future<void> _saveWallpaper(File image, double scale, Offset offset) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      // アプリ専用の保存場所
      final directory = await getApplicationDocumentsDirectory();

      final wallpaperDirectory = Directory('${directory.path}/wallpapers');

      if (!await wallpaperDirectory.exists()) {
        await wallpaperDirectory.create(recursive: true);
      }

      // ユーザーID + ルームIDから安全な名前を作る
      final key = base64Url.encode(utf8.encode('${user.uid}_${widget.roomId}'));

      final wallpaperFile = File('${wallpaperDirectory.path}/$key');

      // 選択した画像を端末内にコピー
      await image.copy(wallpaperFile.path);

      // 設定値を保存
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('wallpaper_path_$key', wallpaperFile.path);

      await prefs.setDouble('wallpaper_scale_$key', scale);

      await prefs.setDouble('wallpaper_offset_x_$key', offset.dx);

      await prefs.setDouble('wallpaper_offset_y_$key', offset.dy);

      debugPrint('壁紙を保存しました');
      debugPrint(wallpaperFile.path);
    } catch (e) {
      debugPrint('壁紙保存エラー: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('壁紙の保存に失敗しました\n$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 背景画像をキーボードで動かさない
      resizeToAvoidBottomInset: false,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 24),
          onPressed: () => Navigator.pop(context),
        ),

        title: Transform.translate(
          offset: const Offset(-8, 0),
          child: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: IconButton(
              icon: const Icon(
                Icons.wallpaper,
                color: Colors.black87,
                size: 24,
              ),
              onPressed: _changeWallpaper,
            ),
          ),
        ],
      ),

      body: Container(
        color: const Color(0xFFF7F7F7),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ==========================================
            // 背景画像
            // 完全に固定する
            // ==========================================
            if (_selectedBackground != null)
              Positioned.fill(
                child: ClipRect(
                  child: Transform.translate(
                    offset: _backgroundOffset,
                    child: Transform.scale(
                      scale: _backgroundScale,
                      alignment: Alignment.center,
                      child: Image.file(
                        _selectedBackground!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),

            // ==========================================
            // 背景の上にチャット画面
            // ==========================================
            Positioned.fill(child: widget.child),
          ],
        ),
      ),
    );
  }
}

class _MemberSummaryUser extends StatelessWidget {
  final String uid;
  final bool isOwner;

  const _MemberSummaryUser({
    required this.uid,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData ||
            !snapshot.data!.exists) {
          return const SizedBox(
            width: 70,
          );
        }

        final data =
        snapshot.data!.data()
        as Map<String, dynamic>;

        final name =
            data['name']?.toString() ?? '名前未設定';

        return _buildItem(name);
      },
    );
  }

  Widget _buildItem(String name) {
    return SizedBox(
      width: 70,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF4FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF64A9ED),
                  size: 34,
                ),
              ),

              // オーナー
              if (isOwner)
                const Positioned(
                  left: -4,
                  top: -5,
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFFFC107),
                    size: 20,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 5),

          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 3),

          if (isOwner)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "オーナー",
                style: TextStyle(
                  fontSize: 9,
                  color: Color(0xFF258EDB),
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.circle,
                  size: 7,
                  color: Color(0xFF22C55E),
                ),
                SizedBox(width: 3),
                Text(
                  "オンライン",
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
