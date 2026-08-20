import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------
// 1. チャット一覧画面（チャット履歴があるユーザーのみ表示）
// ---------------------------------------------------------
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('ログインが必要です')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: const Color(0xFF258EDB),
        title: const Text(
          "メッセージ",
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // 自分が参加しているチャットルームをリアルタイム取得
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .where('participants', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, roomSnapshot) {
          if (roomSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!roomSnapshot.hasData || roomSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'チャット履歴がありません',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final roomDocs = roomSnapshot.data!.docs;

          // 各ルームから「自分以外の相手のUID」を抽出する
          final List<String> partnerUserIds = [];
          for (var room in roomDocs) {
            final data = room.data() as Map<String, dynamic>;
            final List<dynamic> participants = data['participants'] ?? [];

            for (var id in participants) {
              if (id != currentUserId && !partnerUserIds.contains(id)) {
                partnerUserIds.add(id);
              }
            }
          }

          if (partnerUserIds.isEmpty) {
            return const Center(
              child: Text(
                'チャット履歴がありません',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          // 相手のユーザー情報をusersコレクションから一括取得（最大30件までの制限に注意）
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where(FieldPath.documentId, whereIn: partnerUserIds)
                .snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'ユーザー情報が見つかりませんでした',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              final userDocs = userSnapshot.data!.docs;

              return ListView.builder(
                itemCount: userDocs.length,
                itemBuilder: (context, index) {
                  final userData = userDocs[index].data() as Map<String, dynamic>;
                  final userId = userDocs[index].id;
                  final userName = userData['name'] ?? '名前なし';

                  // ルームIDの生成
                  List<String> ids = [currentUserId, userId];
                  ids.sort();
                  final roomId = '${ids[0]}_${ids[1]}';

                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: Text(
                            userName.isNotEmpty ? userName[0] : '?',
                            style: const TextStyle(
                              color: Color(0xFF258EDB),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          userName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'タップしてチャットを開く',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatRoomScreen(
                                partnerUserId: userId,
                                userName: userName,
                                roomId: roomId,
                              ),
                            ),
                          );
                        },
                      ),
                      Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------
// 2. 個別のチャットルーム画面
// ---------------------------------------------------------
class ChatRoomScreen extends StatefulWidget {
  final String partnerUserId;
  final String userName;
  final String roomId;

  const ChatRoomScreen({
    Key? key,
    required this.partnerUserId,
    required this.userName,
    required this.roomId,
  }) : super(key: key);

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || currentUser == null) return;

    final text = _controller.text.trim();
    _controller.clear();

    try {
      // ルームに参加者の情報を保存（これによってチャット履歴一覧に表示されるようになります）
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .set({
        'participants': [currentUser!.uid, widget.partnerUserId],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // メッセージを追加
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('messages')
          .add({
        'text': text,
        'senderId': currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ メッセージ送信エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: const Color(0xFF258EDB),
        title: Text(
          widget.userName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.roomId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
                    final data = docs[index].data() as Map<String, dynamic>;
                    final messageText = data['text'] ?? '';
                    final senderId = data['senderId'] ?? '';
                    final isMe = senderId == currentUser?.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xFF258EDB)
                              : (isDark ? const Color(0xFF2D2D2D) : Colors.grey[300]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          messageText,
                          style: TextStyle(
                            color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
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
          Container(
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
                      hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF258EDB)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}