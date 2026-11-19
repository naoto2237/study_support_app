// ======================================================================
// 【画面】1対1のチャット
//
// 主なクラス: ChatRoomScreen
// 開き方: チャットの相手一覧（chat_list_screen.dart）・相手のマイページの「メッセージ」
// ・上の帯は白く、相手のアイコン・名前・ID（チャット一覧・友達一覧とそろえる）
// ・吹き出し：自分は右に青、相手は左に白（枠つき）。下に時刻
// ・送れない相手（chat_permission.dart）には、入力欄の代わりに案内を出す
// ・送ると users/{自分}/chats/{相手} と users/{相手}/chats/{自分} に会話の記録を残す
// ・使うデータ: chats/{id}/messages, users
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/theme/app_palette.dart';
import 'package:study_support_app/theme/empty_message.dart';
import 'package:study_support_app/screens/chat/chat_permission.dart';

class ChatRoomScreen extends StatefulWidget {
  final String userName;
  final String userId;

  const ChatRoomScreen({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _controller = TextEditingController();

  final currentUser = FirebaseAuth.instance.currentUser;

  // Stream は1回だけ作る（入力のたびに読みなおさない）
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _messages =
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('chats')
          .doc(widget.userId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .snapshots();

  // 相手のプロフィール（上の帯の名前・ID・アイコン）
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _partner =
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .snapshots();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || currentUser == null) {
      return;
    }

    final text = _controller.text.trim();

    _controller.clear();

    try {
      final firestore = FirebaseFirestore.instance;

      final myUid = currentUser!.uid;
      final friendUid = widget.userId;

      // 同じメッセージIDを使用
      final messageId = firestore.collection('users').doc().id;

      final messageData = {
        'text': text,
        'senderId': myUid,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final myChat = firestore
          .collection('users')
          .doc(myUid)
          .collection('chats')
          .doc(friendUid);

      final theirChat = firestore
          .collection('users')
          .doc(friendUid)
          .collection('chats')
          .doc(myUid);

      final batch = firestore.batch();

      // =========================================
      // 自分側・相手側の両方に保存
      // users / 自分 / chats / 相手 / messages
      // users / 相手 / chats / 自分 / messages
      // =========================================
      batch.set(myChat.collection('messages').doc(messageId), messageData);
      batch.set(theirChat.collection('messages').doc(messageId), messageData);

      // =========================================
      // 会話の記録（チャット一覧に出すため）
      // userId: 話している相手 / lastMessage・updatedAt: 最後のメッセージ
      // 相手側には otherSent: true（相手から見て「こちらから届いた」）を残す
      //   → 相手は、設定に関係なく返事を送れる（chat_permission.dart）
      // =========================================
      batch.set(myChat, {
        'userId': friendUid,
        'lastMessage': text,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      batch.set(theirChat, {
        'userId': myUid,
        'lastMessage': text,
        'updatedAt': FieldValue.serverTimestamp(),
        'otherSent': true,
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      debugPrint('メッセージ送信エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Scaffold(
      backgroundColor: p.page,

      // 上の帯：白い帯に、相手のアイコン・名前・ID（チャット一覧・友達一覧と同じ）
      appBar: AppBar(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        iconTheme: IconThemeData(color: p.text),
        shape: Border(bottom: BorderSide(color: p.divider)),
        title: _buildTitle(),
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _messages,

              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const EmptyMessage(
                    icon: Icons.cloud_off_rounded,
                    text: 'メッセージを取得できませんでした',
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const EmptyMessage(
                    icon: Icons.chat_outlined,
                    text: 'まだメッセージはありません',
                    subText: '最初のメッセージを送ってみましょう',
                  );
                }

                // メッセージが少ないときは上に詰める（多いときは、いちばん新しいものが下）
                return Align(
                  alignment: Alignment.topCenter,
                  child: ListView.builder(
                    shrinkWrap: true,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    itemCount: docs.length,

                    itemBuilder: (context, index) {
                      final data = docs[index].data();

                      final createdAt = data['createdAt'];

                      return _MessageBubble(
                        text: (data['text'] ?? '').toString(),
                        isMe: data['senderId'] == currentUser?.uid,
                        // 送った直後で、まだ時刻が入っていないときは今の時刻
                        time: createdAt is Timestamp
                            ? createdAt.toDate()
                            : DateTime.now(),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // 送れない相手には、入力欄の代わりに案内を出す
          CanMessageBuilder(
            userId: widget.userId,
            builder: (context, canMessage, loading) {
              if (!canMessage && !loading) {
                return _bottomBar(
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: p.muted,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '友達になると、メッセージを送れます',
                          style: TextStyle(fontSize: 13.5, color: p.secondary),
                        ),
                      ),
                    ],
                  ),
                  vertical: 16,
                );
              }

              return _buildInput();
            },
          ),
        ],
      ),
    );
  }

  // 上の帯の、相手のアイコン・名前・ID（相手の今のプロフィールから出す）
  Widget _buildTitle() {
    final p = context.pal;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _partner,
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        final name = (data?['name'] ?? data?['username'] ?? widget.userName)
            .toString();
        final id = (data?['userId'] ?? '').toString();
        final icon = (data?['icon'] ?? '').toString();

        return Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primarySoft,
              backgroundImage: icon.isNotEmpty ? NetworkImage(icon) : null,
              child: icon.isEmpty
                  ? const Icon(Icons.person, color: AppColors.primary, size: 21)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: p.text,
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (id.isNotEmpty)
                    Text(
                      id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.secondary, fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // 下の白い帯（入力欄・送れないときの案内）。上に区切り線、下はスマホの端をよける
  Widget _bottomBar(Widget child, {double vertical = 8}) {
    final p = context.pal;

    return Container(
      decoration: BoxDecoration(
        color: p.card,
        border: Border(top: BorderSide(color: p.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: vertical),
          child: child,
        ),
      ),
    );
  }

  // メッセージの入力欄と送るボタン
  // 入力欄：丸い形（入力中は青い枠。長い文は4行まで広がる）
  // 送るボタン：青い丸に白い紙飛行機（何も入れていないときは灰色で押せない）
  Widget _buildInput() {
    final p = context.pal;

    OutlineInputBorder pill(Color color, double width) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: width == 0
            ? BorderSide.none
            : BorderSide(color: color, width: width),
      );
    }

    return _bottomBar(
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
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
            valueListenable: _controller,
            builder: (context, value, child) {
              final canSend = value.text.trim().isNotEmpty;

              return Material(
                color: canSend
                    ? AppColors.primary
                    : (p.isDark ? Colors.white12 : AppColors.border),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: canSend ? _sendMessage : null,
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
    );
  }
}

// ======================================================
// 吹き出し1つ分
// 自分：右に青い吹き出し（白い文字）／相手：左に白い吹き出し（枠つき）
// 角はすべて同じ丸さ
// 時刻は吹き出しの横の下にそろえて小さく出す（自分は吹き出しの左、相手は右）
// ======================================================

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final DateTime time;

  const _MessageBubble({
    required this.text,
    required this.isMe,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    final timeText = '${time.hour}:${time.minute.toString().padLeft(2, '0')}';

    final timeLabel = Padding(
      // 下に少し余白をつけて、吹き出しの下のはしより少しだけ上に出す
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 3.5),
      child: Text(timeText, style: TextStyle(color: p.muted, fontSize: 11)),
    );

    final bubble = Flexible(
      child: ConstrainedBox(
        // 画面の幅の70%まで（横に時刻が入るぶん、少しせまく）
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? AppColors.primary : p.card,
            border: isMe ? null : Border.all(color: p.border),
            // AIサポートと同じく、角を1つだけ小さく丸めて「とがり」をつける
            // （自分は右上、相手は左上）
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isMe ? 18 : 6),
              topRight: Radius.circular(isMe ? 6 : 18),
              bottomLeft: const Radius.circular(18),
              bottomRight: const Radius.circular(18),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isMe ? Colors.white : p.text,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
      ),
    );

    return Padding(
      // 吹き出しどうしの上下の間（せまめ）
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        // 時刻は吹き出しの下のはしにそろえる
        crossAxisAlignment: CrossAxisAlignment.end,
        children: isMe ? [timeLabel, bubble] : [bubble, timeLabel],
      ),
    );
  }
}
