import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AllFriendsScreen extends StatelessWidget {
  final String userId;

  const AllFriendsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Transform.translate(
          offset: const Offset(-19, 0),
          child: const Text(
            '友達',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('friends')
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          // エラー
          if (snapshot.hasError) {
            return const Center(child: Text('友達を読み込めませんでした'));
          }

          // 読み込み中
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final friends = snapshot.data!.docs;

          // 友達がいない場合
          if (friends.isEmpty) {
            return const Center(
              child: Text(
                '友達がここに表示されます',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          // 友達一覧
          return ListView.separated(
            padding: const EdgeInsets.all(16),

            itemCount: friends.length,

            separatorBuilder: (_, __) => const SizedBox(height: 8),

            itemBuilder: (context, index) {
              final data = friends[index].data();

              final friendId = data['userId'] ?? '';

              final friendName = data['username'] ?? 'ユーザー';

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),

                child: ListTile(
                  leading: const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFFEAF4FF),

                    child: Icon(Icons.person, color: Color(0xFF258EDB), size: 27,),
                  ),

                  title: Text(
                    friendName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF258EDB),
                  ),

                  onTap: () {
                    // friendId を使って、
                    // 後で相手のプロフィール画面を開けます。
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
