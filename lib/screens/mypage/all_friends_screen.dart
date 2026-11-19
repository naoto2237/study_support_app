// ======================================================================
// 【画面】友達の一覧
//
// 主なクラス: AllFriendsScreen
// 開き方: マイページの「友達」
// ・上に人数、その下に白いカード（枠つき・角丸16）で友達を並べる
// ・名前・ID・アイコンは、相手の今のプロフィール（users/{相手}）から出す
//   （friends に保存した名前は、友達になったときのままなので使わない）
// ・押すと、その人のページ（user_profile_screen.dart）を開く
// ======================================================================

import 'package:flutter/material.dart';
import 'package:study_support_app/screens/link/user_profile_screen.dart';
import 'package:study_support_app/theme/app_palette.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/theme/empty_message.dart';

class AllFriendsScreen extends StatelessWidget {
  final String userId;

  const AllFriendsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Scaffold(
      backgroundColor: p.page,

      appBar: AppBar(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: p.text),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Transform.translate(
          offset: const Offset(-19, 0),
          child: Text(
            '友達',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: p.text,
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
            return const EmptyMessage(
              icon: Icons.error_outline_rounded,
              text: '友達を読み込めませんでした',
            );
          }

          // 読み込み中
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final friends = snapshot.data!.docs;

          // 友達がいない場合
          if (friends.isEmpty) {
            return const EmptyMessage(
              icon: Icons.people_outline_rounded,
              text: 'まだ友達がいません',
              subText: '友達になると、ここに表示されます',
            );
          }

          // 友達一覧
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // 人数
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  '${friends.length}人',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: p.secondary,
                  ),
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                // 枠線は中身の上に描く（中の行の色で、角の枠線が隠れないように）
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (int i = 0; i < friends.length; i++)
                      _FriendRow(
                        friendId: friends[i].id,
                        savedName: (friends[i].data()['username'] ?? 'ユーザー')
                            .toString(),
                        showDivider: i < friends.length - 1,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ======================================================
// 友達1人分の行（アイコン・名前・ID・「>」）
// ======================================================

class _FriendRow extends StatelessWidget {
  final String friendId;

  // 相手のプロフィールが読めないときに出す名前
  final String savedName;

  final bool showDivider;

  const _FriendRow({
    required this.friendId,
    required this.savedName,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        final String name = (data?['name'] ?? data?['username'] ?? savedName)
            .toString();
        final String id = (data?['userId'] ?? '').toString();
        final String icon = (data?['icon'] ?? '').toString();

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserProfileScreen(userId: friendId),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: showDivider
                ? BoxDecoration(
                    border: Border(bottom: BorderSide(color: p.divider)),
                  )
                : null,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primarySoft,
                  backgroundImage: icon.isNotEmpty ? NetworkImage(icon) : null,
                  child: icon.isEmpty
                      ? const Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 25,
                        )
                      : null,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: p.text,
                        ),
                      ),
                      if (id.isNotEmpty)
                        Text(
                          id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: p.secondary),
                        ),
                    ],
                  ),
                ),

                Icon(Icons.chevron_right_rounded, color: p.muted, size: 22),
              ],
            ),
          ),
        );
      },
    );
  }
}
