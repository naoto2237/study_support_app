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
        color: const Color(0xFFF7F7F7),
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,

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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.public, size: 15, color: Colors.black54),
              SizedBox(width: 4),
              Text(
                "公開ルーム・3人参加中",
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
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

  Widget _buildTopStudyCard() {
    return Container(
      width: double.infinity,
      height: 260,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
            Expanded(
              flex: 3,
              child: _buildTimer(),
            ),

            const SizedBox(width: 4),

            // 右：学習情報
            Expanded(
              flex: 2,
              child: _buildStudyInfoCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimer() {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 進捗バー
          SizedBox(
            width: 202,
            height: 202,
            child: CircularProgressIndicator(
              value: 0.45,
              strokeWidth: 7,
              strokeCap: StrokeCap.round,
              backgroundColor: const Color(0xFFBBDEFB),
              valueColor: const AlwaysStoppedAnimation(
                Color(0xFF2196F3),
              ),
            ),
          ),

          // 中央
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.translate(
                offset: const Offset(0, 18),
                child: const Text(
                  "学習タイマー",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 0),

              Transform.translate(
                offset: const Offset(0, 12),
                child: Text(
                  _formatTime(),
                  style: const TextStyle(
                    color: Color(0xFF2196F3),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              Transform.translate(
                offset: const Offset(0, 15),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(0xFF2196F3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _stopwatch.isRunning
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 33,
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
            ),
            child: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF2196F3),
              size: 33,
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
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 22,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
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

          const Divider(
            height: 1,
            color: Color(0xFFE5E7EB),
          ),

          _buildInfoRow(
            icon: Icons.hourglass_empty,
            title: "目標まで残り",
            value: "45分",
            iconColor: const Color(0xFF2196F3),
          ),

          const Divider(
            height: 1,
            color: Color(0xFFE5E7EB),
          ),

          _buildInfoRow(
            icon: Icons.timer_outlined,
            title: "今日の総学習時間",
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 5,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "アクティビティ",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
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

  Widget _buildFeatureButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          height: 125,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
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
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF4FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 25),
              ),

              const SizedBox(height: 8),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: Colors.black54),
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
                    decoration: InputDecoration(
                      hintText: "メッセージを入力...",
                      filled: true,
                      fillColor: const Color(0xFFF7F7F7),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Color(0xFFEAF4FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.description_rounded,
            color: Color(0xFF2196F3),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          updatedAt,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.black38,
        ),
      ),
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
        return AlertDialog(
          title: const Text("ルームを退出"),
          content: const Text("このルームから退出しますか？"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("キャンセル"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF2196F3), size: 21),
            const SizedBox(width: 7),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
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
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMine ? const Color(0xFFDCEEFF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 3),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              time,
              style: const TextStyle(fontSize: 10, color: Colors.black45),
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
          const CircleAvatar(
            radius: 19,
            backgroundColor: Color(0xFFEAF4FF),
            child: Icon(Icons.person, color: Color(0xFF2196F3), size: 20),
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
    return Card(
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFFEAF4FF),
              child: Icon(Icons.person, color: Color(0xFF2196F3)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "今日 $time",
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: studying
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                studying ? "勉強中" : "休憩中",
                style: TextStyle(
                  color: studying ? Colors.green : Colors.grey,
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
