// ======================================================================
// 【部品】ルームの中の「チャット」
//
// 主なクラス: RoomChatScreen / RoomChatBubble（吹き出し）
// ・使うデータ: rooms/{id}/messages, users
// ・見た目は友達とのチャット（chat/chat_room_screen.dart）とそろえる
//   自分：右に青い吹き出し／相手：左にアイコンと名前、白い吹き出し
//   時刻は吹き出しの横の下。メッセージは上から詰めて並べる
// ・下の入力欄は、RoomFeatureScreen がキーボードで背景を動かさないため、
//   キーボードの高さぶんを自分で上げる（_ChatInputArea）
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_support_app/screens/record/comparison/compare_user_picker.dart'
    show PartnerAvatar;
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/theme/app_palette.dart';
import 'package:study_support_app/theme/empty_message.dart';

class RoomChatScreen extends StatefulWidget {
  final String roomId;

  const RoomChatScreen({super.key, required this.roomId});

  @override
  State<RoomChatScreen> createState() => _RoomChatScreenState();
}

class _RoomChatScreenState extends State<RoomChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 新しい順（いちばん新しいものを下に出すため、リストを下から並べる）
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _messageStream;

  // 送った人のアイコン（同じ人を何度も読まないよう、uid ごとに取っておく）
  final Map<String, Future<String>> _iconCache = {};

  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    _messageStream = _firestore
        .collection('rooms')
        .doc(widget.roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<String> _iconOf(String uid) {
    return _iconCache.putIfAbsent(uid, () async {
      if (uid.isEmpty) return '';
      final doc = await _firestore.collection('users').doc(uid).get();
      return (doc.data()?['icon'] ?? '').toString();
    });
  }

  // =========================
  // メッセージ送信
  // =========================
  Future<void> _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty || _isSending) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isSending = true;

    try {
      // 今のユーザー名（メッセージといっしょに保存する）
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['name'] as String? ?? 'ユーザー';

      _controller.clear();

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

      // いちばん新しいメッセージ（下のはし）へ
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      debugPrint('メッセージ送信エラー: $e');

      // 送れなかったときは、書いた文を入力欄に戻す
      if (_controller.text.isEmpty) _controller.text = message;
    } finally {
      _isSending = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      children: [
        // ==========================================
        // メッセージの一覧
        // ==========================================
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _messageStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const EmptyMessage(
                  icon: Icons.cloud_off_rounded,
                  text: 'メッセージを読み込めませんでした',
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              final messages = snapshot.data?.docs ?? [];

              if (messages.isEmpty) {
                return const EmptyMessage(
                  icon: Icons.forum_rounded,
                  text: 'まだメッセージはありません',
                  subText: '最初のメッセージを送ってみましょう',
                );
              }

              // 少ないときも上から詰めて並べる（下から並べ、上にそろえる）
              return Align(
                alignment: Alignment.topCenter,
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data();
                    final uid = (data['uid'] ?? '').toString();
                    final createdAt = data['createdAt'];

                    // 1つ前（上）のメッセージと同じ人なら、アイコンと名前を省く
                    final olderUid = index + 1 < messages.length
                        ? (messages[index + 1].data()['uid'] ?? '').toString()
                        : null;

                    return RoomChatBubble(
                      key: ValueKey(messages[index].id),
                      name: (data['name'] ?? 'ユーザー').toString(),
                      message: (data['message'] ?? '').toString(),
                      isMine: uid == currentUid,
                      time: createdAt is Timestamp
                          ? createdAt.toDate()
                          : DateTime.now(),
                      showSender: olderUid != uid,
                      icon: _iconOf(uid),
                    );
                  },
                ),
              );
            },
          ),
        ),

        // ==========================================
        // 入力欄
        // ==========================================
        _ChatInputArea(controller: _controller, onSend: _sendMessage),
      ],
    );
  }
}

// =====================================================
// 入力欄（友達とのチャットと同じ形）
// 入力欄：丸い形（入力中は青い枠。長い文は4行まで広がる）
// 送るボタン：青い丸に白い紙飛行機（何も入れていないときは灰色で押せない）
//
// MediaQuery（キーボードの高さ）はここだけで使う。
// そうすると、キーボードが開いたときにメッセージの一覧まで描き直さずにすむ
// =====================================================

class _ChatInputArea extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _ChatInputArea({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    OutlineInputBorder pill(Color color, double width) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: width == 0
            ? BorderSide.none
            : BorderSide(color: color, width: width),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        decoration: BoxDecoration(
          color: p.card,
          border: Border(top: BorderSide(color: p.divider)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                    cursorColor: AppColors.primary,
                    style: TextStyle(color: p.text, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'メッセージを入力',
                      hintStyle: TextStyle(color: p.muted, fontSize: 15),
                      filled: true,
                      fillColor: p.field,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      border: pill(Colors.transparent, 0),
                      enabledBorder: pill(Colors.transparent, 0),
                      focusedBorder: pill(AppColors.primary, 1.5),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // 入力があるかどうかで、ボタンの色を変える
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, child) {
                    final canSend = value.text.trim().isNotEmpty;

                    return Material(
                      color: canSend
                          ? AppColors.primary
                          : (p.isDark ? Colors.white12 : AppColors.border),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: canSend ? onSend : null,
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: Icon(
                            Icons.send_rounded,
                            size: 20,
                            color: canSend ? Colors.white : p.muted,
                          ),
                        ),
                      ),
                    );
                  },
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
// 吹き出し1つ分
// 自分：右に青い吹き出し（白い文字）
// 相手：左にアイコン、上に名前、白い吹き出し（枠つき）
//       同じ人が続けて送ったときは、2つ目からアイコンと名前を省く
// 時刻は吹き出しの横の下にそろえて小さく出す（自分は左、相手は右）
// =====================================================

class RoomChatBubble extends StatelessWidget {
  final String name;
  final String message;
  final bool isMine;
  final DateTime time;
  final bool showSender;
  final Future<String> icon;

  const RoomChatBubble({
    super.key,
    required this.name,
    required this.message,
    required this.isMine,
    required this.time,
    required this.showSender,
    required this.icon,
  });

  // 相手のアイコンの大きさ（省いたときも、同じ幅だけあける）
  static const double _avatarRadius = 16;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    final timeText = '${time.hour}:${time.minute.toString().padLeft(2, '0')}';

    final timeLabel = Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 3.5),
      child: Text(timeText, style: TextStyle(color: p.muted, fontSize: 11)),
    );

    final bubble = Flexible(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * (isMine ? 0.7 : 0.62),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMine ? AppColors.primary : p.card,
            border: isMine ? null : Border.all(color: p.border),
            // AIサポートと同じく、角を1つだけ小さく丸めて「とがり」をつける
            // （自分は右上、相手は左上）
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isMine ? 18 : 6),
              topRight: Radius.circular(isMine ? 6 : 18),
              bottomLeft: const Radius.circular(18),
              bottomRight: const Radius.circular(18),
            ),
          ),
          child: Text(
            message,
            style: TextStyle(
              color: isMine ? Colors.white : p.text,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
      ),
    );

    // ---------------- 自分 ----------------
    if (isMine) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [timeLabel, bubble],
        ),
      );
    }

    // ---------------- 相手 ----------------
    return Padding(
      padding: EdgeInsets.only(top: showSender ? 8 : 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _avatarRadius * 2,
            child: showSender
                ? FutureBuilder<String>(
                    future: icon,
                    builder: (context, snapshot) => PartnerAvatar(
                      icon: snapshot.data ?? '',
                      radius: _avatarRadius,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showSender)
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 4),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: p.secondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [bubble, timeLabel],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
