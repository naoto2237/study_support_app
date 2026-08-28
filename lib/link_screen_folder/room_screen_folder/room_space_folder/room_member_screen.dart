import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RoomMemberScreen extends StatelessWidget {
  final String roomId;

  const RoomMemberScreen({
    super.key,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('members')
          .orderBy('joinedAt')
          .snapshots(),
      builder: (context, memberSnapshot) {
        // ==============================
        // 読み込み中
        // ==============================
        if (memberSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF258EDB),
            ),
          );
        }

        // ==============================
        // エラー
        // ==============================
        if (memberSnapshot.hasError) {
          return Center(
            child: Text(
              'メンバーの取得に失敗しました\n${memberSnapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        final memberDocs =
            memberSnapshot.data?.docs ?? [];

        // ==============================
        // メンバーなし
        // ==============================
        if (memberDocs.isEmpty) {
          return const Center(
            child: Text(
              '参加しているメンバーはいません',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          );
        }

        // ==============================
        // メンバー一覧
        // ==============================
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            24,
          ),
          itemCount: memberDocs.length,
          separatorBuilder: (_, __) {
            return const SizedBox(height: 10);
          },
          itemBuilder: (context, index) {
            final memberDoc = memberDocs[index];

            // members/{uid}
            final uid = memberDoc.id;

            return MemberTile(
              uid: uid,
            );
          },
        );
      },
    );
  }
}

// =========================================================
// メンバー1人分
// =========================================================

class MemberTile extends StatelessWidget {
  final String uid;

  const MemberTile({
    super.key,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(),
      builder: (context, snapshot) {
        // ==============================
        // ユーザー情報取得中
        // ==============================
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return _loadingTile();
        }

        // ==============================
        // エラー
        // ==============================
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        // ==============================
        // ユーザーが存在しない
        // ==============================
        if (!snapshot.hasData ||
            !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final data =
        snapshot.data!.data()
        as Map<String, dynamic>;

        final name =
            data['name']?.toString() ?? '名前未設定';

        return _memberTile(
          name: name,
        );
      },
    );
  }

  // =========================================================
  // ローディング
  // =========================================================

  Widget _loadingTile() {
    return Card(
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFFE5E7EB),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF258EDB),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // メンバー表示
  // =========================================================

  Widget _memberTile({
    required String name,
  }) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFFE5E7EB),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Row(
          children: [
            // アイコン
            const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFFEAF4FF),
              child: Icon(
                Icons.person,
                color: Color(0xFF258EDB),
              ),
            ),

            const SizedBox(width: 14),

            // 名前・学習時間
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    '今日 00:00:00',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // ステータス
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '勉強中',
                style: TextStyle(
                  color: Colors.green,
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
