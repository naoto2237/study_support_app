import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RoomChatScreen extends StatefulWidget {
  final String roomId;

  const RoomChatScreen({super.key, required this.roomId});

  @override
  State<RoomChatScreen> createState() => _RoomChatScreenState();
}

class _RoomChatScreenState extends State<RoomChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _textFieldScrollController = ScrollController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _messageStreamData;

  @override
  void initState() {
    super.initState();

    _messageStreamData = _firestore
        .collection('rooms')
        .doc(widget.roomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _textFieldScrollController.dispose();
    super.dispose();
  }

  // =========================
  // メッセージ送信
  // =========================
  Future<void> _sendMessage() async {
    final message = _controller.text.trim();

    if (message.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      // Firestoreから現在のユーザー名を取得
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      final userName = userDoc.data()?['name'] as String? ?? 'ユーザー';

      await _firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('messages')
          .add({
            'uid': user.uid,
            'name': userName,
            'message': message,
            'createdAt': FieldValue.serverTimestamp(),
          });

      _controller.clear();

      // キーボードはそのまま表示
      if (_focusNode.canRequestFocus) {
        _focusNode.requestFocus();
      }

      // 少し待ってから一番下へ
      await Future.delayed(const Duration(milliseconds: 50));

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      debugPrint('メッセージ送信エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      children: [
        // ==========================================
        // チャット一覧
        // ==========================================
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _messageStreamData,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('メッセージを取得できませんでした'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data?.docs ?? [];

              if (messages.isEmpty) {
                return const Center(
                  child: Text(
                    'まだチャットはありません',
                    style: TextStyle(color: Colors.black45, fontSize: 14),
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final data = messages[index].data();

                  final uid = data['uid'] as String? ?? '';

                  final name = data['name'] as String? ?? 'ユーザー';

                  final message = data['message'] as String? ?? '';

                  final timestamp = data['createdAt'] as Timestamp?;

                  String time = '';

                  if (timestamp != null) {
                    final date = timestamp.toDate();

                    time =
                        '${date.hour.toString().padLeft(2, '0')}:'
                        '${date.minute.toString().padLeft(2, '0')}';
                  } else {
                    // serverTimestampがまだ確定していない場合
                    time = '送信中';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: RoomChatBubble(
                      name: name,
                      message: message,
                      isMine: uid == currentUid,
                      time: time,
                    ),
                  );
                },
              );
            },
          ),
        ),

        // ==========================================
        // 入力欄
        // ==========================================
        _ChatInputArea(
          controller: _controller,
          focusNode: _focusNode,
          textFieldScrollController: _textFieldScrollController,
          onSend: _sendMessage,
        ),
      ],
    );
  }
}

// =====================================================
// 入力欄
//
// MediaQueryはここだけで使用する。
// そのためキーボードが開いたときに
// チャット一覧までMediaQueryの変更を受けにくくする。
// =====================================================

class _ChatInputArea extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ScrollController textFieldScrollController;
  final VoidCallback onSend;

  const _ChatInputArea({
    required this.controller,
    required this.focusNode,
    required this.textFieldScrollController,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 8, 13, 12),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            ),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 13, 60, 13),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    scrollController: textFieldScrollController,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    minLines: 1,
                    maxLines: 10,
                    style: const TextStyle(fontSize: 16, height: 1.4),
                    cursorColor: const Color(0xFF258EDB),
                    decoration: const InputDecoration(
                      hintText: 'チャットを送る...',
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                    onSubmitted: (_) {
                      onSend();
                    },
                  ),
                ),

                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onSend,
                      child: Ink(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFF258EDB),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// チャット吹き出し
// =====================================================

class RoomChatBubble extends StatelessWidget {
  final String name;
  final String message;
  final bool isMine;
  final String time;

  const RoomChatBubble({
    super.key,
    required this.name,
    required this.message,
    required this.isMine,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    // =========================
    // 吹き出し
    // =========================
    final bubble = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 282),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: isMine ? const Color(0xFFC9E9FF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),

        // =========================
        // 吹き出しの「ちょん」
        // =========================
        Positioned(
          top: 1.76,
          left: isMine ? null : -2.17,
          right: isMine ? -2.17 : null,
          child: Transform.flip(
            flipX: !isMine,
            child: Transform.rotate(
              angle: 18.635,
              child: ClipPath(
                clipper: _BubbleTailClipper(),
                child: Container(
                  width: 10,
                  height: 18,
                  color: isMine ? const Color(0xFFC9E9FF) : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    // =========================
    // 相手
    // =========================
    if (!isMine) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // アイコン
          Transform.translate(
            offset: const Offset(0, -27),
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFF258EDB), size: 20),
            ),
          ),

          const SizedBox(width: 8),

          // 名前 + メッセージ
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black45,
                ),
              ),

              const SizedBox(height: 7),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  bubble,

                  const SizedBox(width: 5),

                  Transform.translate(
                    offset: const Offset(0, -6),
                    child: Text(
                      time,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black45,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    }

    // =========================
    // 自分
    // =========================
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Transform.translate(
          offset: const Offset(0, -6),
          child: Text(
            time,
            style: const TextStyle(fontSize: 10, color: Colors.black45),
          ),
        ),

        const SizedBox(width: 5),

        bubble,
      ],
    );
  }
}

// =====================================================
// 吹き出しの尻尾
// =====================================================

class _BubbleTailClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
