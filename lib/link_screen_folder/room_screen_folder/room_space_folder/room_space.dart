import 'package:flutter/material.dart';
import 'dart:async';

class RoomSpaceScreen extends StatefulWidget {
  final String roomTitle;

  const RoomSpaceScreen({super.key, required this.roomTitle});

  @override
  State<RoomSpaceScreen> createState() => _RoomSpaceScreenState();
}

class _RoomSpaceScreenState extends State<RoomSpaceScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF7F7F7);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      appBar: _buildAppBar(context),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: bgColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(17, 17, 17, 28),
          child: Column(
            children: [
              const SizedBox(height: 3),

              // タイマー + 学習情報
              _buildTopStudyCard(),

              const SizedBox(height: 16),

              // メンバー・チャット・共有ノート
              _buildRoomFeatureButtons(),
              const SizedBox(height: 16),

              // アクティビティ
              _buildActivity(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;

    return AppBar(
      backgroundColor: cardColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      automaticallyImplyLeading: false,

      leading: IconButton(
        icon: Icon(Icons.arrow_back, size: 24, color: textColor),
        onPressed: _showExitDialog,
      ),

      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.roomTitle,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.public, size: 15, color: subtitleColor),
              const SizedBox(width: 4),
              Text(
                "公開ルーム・3人参加中",
                style: TextStyle(fontSize: 13, color: subtitleColor),
              ),
            ],
          ),
        ],
      ),

      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 7),
          child: IconButton(
            icon: Icon(Icons.more_vert, size: 24, color: textColor),
            onPressed: _showMenu,
          ),
        ),
      ],
    );
  }

  Widget _buildTopStudyCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB);

    return Container(
      width: double.infinity,
      height: 260,
      padding: const EdgeInsets.only(
        left: 18,
        right: 15,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 5,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: SizedBox(
        height: 230,
        child: Row(
          children: [
            // 左：タイマー
            Expanded(flex: 3, child: _buildTimer()),

            const SizedBox(width: 10),

            SizedBox(
              height: 212,
              child: VerticalDivider(
                width: 1,
                thickness: 1,
                color: borderColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return SizedBox(
      width: 220,
      height: 220,
      child: Transform.translate(
        offset: const Offset(-3, 0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 進捗バー
            SizedBox(
              width: 190,
              height: 190,
              child: CircularProgressIndicator(
                value: 0.45,
                strokeWidth: 7,
                strokeCap: StrokeCap.round,
                backgroundColor: isDark ? Colors.blue.withValues(alpha: 0.2) : const Color(0xFFBBDEFB),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF2196F3)),
              ),
            ),

            // 中央
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.translate(
                  offset: const Offset(0, 13),
                  child: Text(
                    "学習タイマー",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),

                const SizedBox(height: 0),

                Transform.translate(
                  offset: const Offset(0, 9),
                  child: Text(
                    _formatTime(),
                    style: const TextStyle(
                      color: Color(0xFF2196F3),
                      fontSize: 31,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                Transform.translate(
                  offset: const Offset(0, 14),
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
            decoration: const BoxDecoration(
              color: Color(0xFF2196F3),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB);

    return GestureDetector(
      onTap: _reset,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF2196F3),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black87;

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
                  style: TextStyle(fontSize: 12, color: textColor),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB);

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
                child: Divider(height: 1, color: dividerColor),
              ),
            ),
          ),

          _buildInfoRow(
            icon: Icons.hourglass_empty,
            title: "目標まで残り",
            value: "45分",
            iconColor: const Color(0xFF2196F3),
          ),

          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 0),
              child: SizedBox(
                width: 120,
                child: Divider(height: 1, color: dividerColor),
              ),
            ),
          ),

          _buildInfoRow(
            icon: Icons.timer_outlined,
            title: "今日の学習時間",
            value: "2時間15分",
            iconColor: const Color(0xFF2196F3),
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
            subtitle: "3人参加中",
            iconColor: const Color(0xFF2196F3),
            onTap: () {
              _openFeatureScreen(
                title: "メンバー",
                icon: Icons.groups_rounded,
                child: _buildMembersScreenContent(),
              );
            },
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _buildFeatureButton(
            icon: Icons.chat_bubble_rounded,
            title: "チャット",
            subtitle: "未読 3件",
            iconColor: const Color(0xFF2196F3),
            badge: "3",
            onTap: () {
              _openFeatureScreen(
                title: "チャット",
                icon: Icons.chat_bubble_rounded,
                child: _buildChatScreenContent(),
              );
            },
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _buildFeatureButton(
            icon: Icons.description_rounded,
            title: "共有ノート",
            subtitle: "更新 2件",
            iconColor: const Color(0xFF2196F3),
            badge: "2",
            onTap: () {
              _openFeatureScreen(
                title: "共有ノート",
                icon: Icons.description_rounded,
                child: _buildNotesScreenContent(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivity() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final borderColor = isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 5,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "アクティビティ",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),

          const SizedBox(height: 14),

          _buildActivityItem(
            icon: Icons.play_arrow_rounded,
            iconColor: const Color(0xFF2196F3),
            name: "Aさん",
            text: "学習を開始しました",
            time: "10:32",
          ),

          const SizedBox(height: 12),

          _buildActivityItem(
            icon: Icons.description_rounded,
            iconColor: const Color(0xFF2196F3),
            name: "Bさん",
            text: "共有ノートを更新しました",
            time: "10:18",
          ),

          const SizedBox(height: 12),

          _buildActivityItem(
            icon: Icons.login_rounded,
            iconColor: const Color(0xFF2196F3),
            name: "Cさん",
            text: "ルームに参加しました",
            time: "09:54",
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconColor,
    required String name,
    required String text,
    required String time,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final subtitleColor = isDark ? Colors.white60 : Colors.black45;
    final iconBgColor = isDark ? const Color(0xFF2196F3).withValues(alpha: 0.2) : const Color(0xFFEAF4FF);

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBgColor,
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                TextSpan(
                  text: "  $text",
                  style: TextStyle(fontSize: 13, color: textColor),
                ),
              ],
            ),
          ),
        ),

        Text(time, style: TextStyle(fontSize: 10, color: subtitleColor)),
      ],
    );
  }

  Widget _buildFeatureButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
    String? badge,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;
    final borderColor = isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB);
    final iconBgColor = isDark ? const Color(0xFF2196F3).withValues(alpha: 0.2) : const Color(0xFFEAF4FF);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          height: 125,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.035),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 25),
              ),

              const SizedBox(height: 8),

              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: subtitleColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // メンバー画面
  // =========================================================
  Widget _buildMembersScreenContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: const [
        MemberTile(name: "A", time: "00:15:32", studying: true),
        SizedBox(height: 10),
        MemberTile(name: "B", time: "01:05:18", studying: true),
        SizedBox(height: 10),
        MemberTile(name: "C", time: "01:42:18", studying: true),
        SizedBox(height: 10),
        MemberTile(name: "D", time: "休憩中", studying: false),
      ],
    );
  }

  // =========================================================
  // チャット画面（仮）
  // =========================================================
  Widget _buildChatScreenContent() {
    return Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final textFieldBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F7F7);
          final textColor = isDark ? Colors.white70 : Colors.black87;
          final subtitleColor = isDark ? Colors.white60 : Colors.black45;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  children: const [
                    _ChatBubble(
                      name: "A",
                      message: "おはよう！\n今日も一緒に頑張ろう！",
                      isMine: false,
                      time: "10:30",
                    ),
                    SizedBox(height: 12),
                    _ChatBubble(
                      name: "B",
                      message: "おはよう！\n今日は数学を進めるよ！",
                      isMine: true,
                      time: "10:31",
                    ),
                    SizedBox(height: 12),
                    _ChatBubble(
                      name: "C",
                      message: "私は英単語をやる予定！\n一緒に頑張ろう🔥",
                      isMine: false,
                      time: "10:32",
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: TextStyle(color: textColor),
                          cursorColor: const Color(0xFF2196F3),
                          decoration: InputDecoration(
                            hintText: "メッセージを入力...",
                            hintStyle: TextStyle(color: subtitleColor),
                            filled: true,
                            fillColor: textFieldBg,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: isDark ? Colors.grey.shade800 : Colors.transparent,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: isDark ? Colors.grey.shade800 : Colors.transparent,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: Color(0xFF2196F3),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2196F3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
    );
  }

  // =========================================================
  // 共有ノート画面（仮）
  // =========================================================
  Widget _buildNotesScreenContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _buildNoteTile("英単語まとめノート", "更新：今日 09:15"),
        _buildNoteTile("数学の公式まとめ", "更新：昨日 21:30"),
        _buildNoteTile("化学 重要ポイント", "更新：7/1 18:45"),
        _buildNoteTile("現代文 読解メモ", "更新：6/30 22:10"),
        _buildNoteTile("物理 演習問題集", "更新：6/29 20:05"),
      ],
    );
  }

  Widget _buildNoteTile(String title, String updatedAt) {
    return Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
          final textColor = isDark ? Colors.white70 : Colors.black87;
          final subtitleColor = isDark ? Colors.white60 : Colors.black54;
          final borderColor = isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB);
          final iconBgColor = isDark ? const Color(0xFF2196F3).withValues(alpha: 0.2) : const Color(0xFFEAF4FF);

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: Color(0xFF2196F3),
                ),
              ),
              title: Text(
                title,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
              ),
              subtitle: Text(
                updatedAt,
                style: TextStyle(fontSize: 12, color: subtitleColor),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: subtitleColor,
              ),
            ),
          );
        }
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
        builder: (_) =>
            _RoomFeatureScreen(title: title, icon: icon, child: child),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final textColor = isDark ? Colors.white70 : Colors.black87;
        final subtitleColor = isDark ? Colors.white60 : Colors.black54;

        return AlertDialog(
          backgroundColor: cardColor,
          title: Text("ルームを退出", style: TextStyle(color: textColor)),
          content: Text("このルームから退出しますか？", style: TextStyle(color: subtitleColor)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("キャンセル", style: TextStyle(color: subtitleColor)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
              ),
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final textColor = isDark ? Colors.white70 : Colors.black87;

        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.edit, color: textColor),
                  title: Text("ルーム情報を編集", style: TextStyle(color: textColor)),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.notifications, color: textColor),
                  title: Text("通知設定", style: TextStyle(color: textColor)),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.info_outline, color: textColor),
                  title: Text("ルーム情報", style: TextStyle(color: textColor)),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =========================================================
// 専用画面の共通レイアウト
// =========================================================
class _RoomFeatureScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _RoomFeatureScreen({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF7F7F7);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF2196F3), size: 21),
            const SizedBox(width: 7),
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: child,
    );
  }
}

// =========================================================
// チャット吹き出し
// =========================================================
class _ChatBubble extends StatelessWidget {
  final String name;
  final String message;
  final bool isMine;
  final String time;

  const _ChatBubble({
    required this.name,
    required this.message,
    required this.isMine,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final myBubbleColor = isDark ? const Color(0xFF2196F3).withValues(alpha: 0.3) : const Color(0xFFDCEEFF);
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final subtitleColor = isDark ? Colors.white60 : Colors.black45;
    final borderColor = isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB);
    final iconBgColor = isDark ? const Color(0xFF2196F3).withValues(alpha: 0.2) : const Color(0xFFEAF4FF);

    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMine ? myBubbleColor : cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 3),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              time,
              style: TextStyle(fontSize: 10, color: subtitleColor),
            ),
          ),
        ],
      ),
    );

    return Row(
      mainAxisAlignment: isMine
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMine) ...[
          CircleAvatar(
            radius: 19,
            backgroundColor: iconBgColor,
            child: const Icon(Icons.person, color: Color(0xFF2196F3), size: 20),
          ),
          const SizedBox(width: 8),
        ],
        bubble,
      ],
    );
  }
}

// =========================================================
// メンバーカード
// =========================================================
class MemberTile extends StatelessWidget {
  final String name;
  final String time;
  final bool studying;

  const MemberTile({
    super.key,
    required this.name,
    required this.time,
    required this.studying,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;
    final borderColor = isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB);
    final iconBgColor = isDark ? const Color(0xFF2196F3).withValues(alpha: 0.2) : const Color(0xFFEAF4FF);

    return Card(
      elevation: 0,
      color: cardColor,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: iconBgColor,
              child: const Icon(Icons.person, color: Color(0xFF2196F3)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "今日 $time",
                    style: TextStyle(fontSize: 13, color: subtitleColor),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: studying
                    ? (isDark ? Colors.green.withValues(alpha: 0.2) : const Color(0xFFE8F5E9))
                    : (isDark ? Colors.grey.shade800 : const Color(0xFFF3F4F6)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                studying ? "勉強中" : "休憩中",
                style: TextStyle(
                  color: studying ? Colors.green : (isDark ? Colors.white60 : Colors.grey),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}