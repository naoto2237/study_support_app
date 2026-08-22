import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------
// 1. チャット一覧画面（上部に検索バー付き）
// ---------------------------------------------------------
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final borderColor = isDark ? Colors.grey[850]! : Colors.grey[200]!;
    final textColor = isDark ? Colors.white70 : Colors.black87;

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
      body: Column(
        children: [
          // ─── 上部の検索バーエリア ───
          Container(
            padding: const EdgeInsets.all(12.0),
            color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: textColor),
              onChanged: (value) {
                setState(() {
                  _searchText = value.trim();
                });
              },
              decoration: InputDecoration(
                hintText: "ユーザー名で検索...",
                hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey[400] : Colors.grey),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: isDark ? Colors.grey[400] : Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchText = "";
                    });
                  },
                )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF258EDB), width: 1.5),
                ),
              ),
            ),
          ),

          // ─── メイン表示エリア（検索中かどうかで切り替え） ───
          Expanded(
            child: _searchText.isEmpty
                ? _buildChatHistoryList(currentUserId, isDark) // 1. チャット履歴一覧
                : _buildUserSearchResultList(currentUserId, _searchText, isDark), // 2. ユーザー検索結果
          ),
        ],
      ),
    );
  }

  // ① チャット履歴があるユーザーの一覧を表示
  Widget _buildChatHistoryList(String currentUserId, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
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
              'チャット履歴がありません\n上部のバーからユーザーを検索してみましょう！',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final roomDocs = roomSnapshot.data!.docs;
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
                final icon = userData['icon'] ?? '';

                List<String> ids = [currentUserId, userId];
                ids.sort();
                final roomId = '${ids[0]}_${ids[1]}';

                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: icon.isNotEmpty
                          ? CircleAvatar(backgroundImage: NetworkImage(icon))
                          : CircleAvatar(
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
    );
  }

  // ② 検索ワードがある時のユーザー検索結果一覧（タップしたらプロフィール画面へ）
  Widget _buildUserSearchResultList(String currentUserId, String searchText, bool isDark) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .where("name", isGreaterThanOrEqualTo: searchText)
          .where("name", isLessThan: "$searchText\uf8ff")
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "エラーが発生しました\n${snapshot.error}",
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data?.docs ?? [];

        // 自分自身を除外したい場合はここでフィルタリング可能
        final filteredUsers = users.where((doc) => doc.id != currentUserId).toList();

        if (filteredUsers.isEmpty) {
          return const Center(
            child: Text(
              "ユーザーが見つかりません",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final data = filteredUsers[index].data();
            final String name = data["name"] ?? "名前なし";
            final String email = data["email"] ?? "";
            final String icon = data["icon"] ?? "";
            final String userId = filteredUsers[index].id;

            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: icon.isNotEmpty
                      ? CircleAvatar(backgroundImage: NetworkImage(icon))
                      : CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: const TextStyle(
                        color: Color(0xFF258EDB),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    email,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                    // タップしたらプロフィール画面へ遷移
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(userId: userId),
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
  }
}

// ---------------------------------------------------------
// 2. プロフィール画面（「チャットする」ボタン付き）
// ---------------------------------------------------------
class ProfileScreen extends StatelessWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final bool isMe = currentUserId == userId;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF258EDB),
        title: const Text('プロフィール', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('ユーザーが見つかりませんでした'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final userName = data['name'] ?? '名前なし';
          final email = data['email'] ?? '';
          final icon = data['icon'] ?? '';

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: icon.isNotEmpty
                      ? CircleAvatar(radius: 40, backgroundImage: NetworkImage(icon))
                      : CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      userName.isNotEmpty ? userName[0] : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Color(0xFF258EDB),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  email,
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                const SizedBox(height: 40),

                if (!isMe && currentUserId != null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF258EDB),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    icon: const Icon(Icons.chat),
                    label: const Text('チャットする', style: TextStyle(fontSize: 16)),
                    onPressed: () {
                      List<String> ids = [currentUserId, userId];
                      ids.sort();
                      final roomId = '${ids[0]}_${ids[1]}';

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
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------
// 3. 個別のチャットルーム画面
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
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .set({
        'participants': [currentUser!.uid, widget.partnerUserId],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

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