// ======================================================================
// 【画面】1対1のチャット
//
// 主なクラス: ChatRoomScreen
// 開き方: チャットの相手一覧（chat_list_screen.dart）・相手のマイページの「メッセージ」
// ・送れない相手（chat_permission.dart）には、入力欄の代わりに案内を出す
// ・送ると users/{自分}/chats/{相手} と users/{相手}/chats/{自分} に会話の記録を残す
// ・使うデータ: chats/{id}/messages, users
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_support_app/theme/app_colors.dart';
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,

      appBar: AppBar(
        centerTitle: false,
        backgroundColor: AppColors.primary,

        title: Transform.translate(
          offset: const Offset(-19, 0),
          child: Text(
            widget.userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser!.uid)
                  .collection('chats')
                  .doc(widget.userId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('メッセージを取得できませんでした'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'まだメッセージはありません。\n最初のメッセージを送ってみましょう！',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,

                  itemBuilder: (context, index) {
                    final data = docs[index].data();

                    final messageText = data['text'] ?? '';

                    final senderId = data['senderId'] ?? '';

                    final isMe = senderId == currentUser?.uid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,

                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),

                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),

                        decoration: BoxDecoration(
                          color: isMe
                              ? AppColors.primary
                              : isDark
                              ? const Color(0xFF2D2D2D)
                              : Colors.grey[300],

                          borderRadius: BorderRadius.circular(16),
                        ),

                        child: Text(
                          messageText,

                          style: TextStyle(
                            color: isMe
                                ? Colors.white
                                : isDark
                                ? Colors.white
                                : Colors.black87,

                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 送れない相手には、入力欄の代わりに案内を出す
          CanMessageBuilder(
            userId: widget.userId,
            builder: (context, canMessage, loading) {
              if (!canMessage && !loading) {
                return SafeArea(
                  top: false,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 18,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '友達になると、メッセージを送れます',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return _buildInput(isDark);
            },
          ),
        ],
      ),
    );
  }

  // メッセージの入力欄と送るボタン
  Widget _buildInput(bool isDark) {
    return Builder(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],

          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,

                  style: TextStyle(color: isDark ? Colors.white : Colors.black),

                  decoration: InputDecoration(
                    hintText: 'メッセージを入力...',

                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),

                    filled: true,

                    fillColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,

                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),

                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              IconButton(
                icon: const Icon(Icons.send, color: AppColors.primary),

                onPressed: _sendMessage,
              ),
            ],
          ),
        );
      },
    );
  }
}
