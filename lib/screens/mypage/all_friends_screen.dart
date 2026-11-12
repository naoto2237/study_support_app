// ======================================================================
// 【画面】友達の一覧
//
// 主なクラス: AllFriendsScreen
// 開き方: マイページの「友達」
// ======================================================================

import 'package:flutter/material.dart';
import 'package:study_support_app/theme/app_palette.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_support_app/theme/app_colors.dart';

class AllFriendsScreen extends StatelessWidget {
  final String userId;

  const AllFriendsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pal.page,

      appBar: AppBar(
        backgroundColor: context.pal.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.pal.text),
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
              color: context.pal.text,
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
            return Center(
              child: Text(
                '友達がここに表示されます',
                style: TextStyle(fontSize: 16, color: context.pal.secondary),
              ),
            );
          }

          // 友達一覧
          return ListView.separated(
            padding: const EdgeInsets.all(16),

            itemCount: friends.length,

            separatorBuilder: (_, _) => const SizedBox(height: 8),

            itemBuilder: (context, index) {
              final data = friends[index].data();

              final friendName = data['username'] ?? 'ユーザー';

              return Container(
                decoration: BoxDecoration(
                  color: context.pal.card,
                  borderRadius: BorderRadius.circular(14),
                ),

                child: ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: context.pal.primarySoft,

                    child: Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 27,
                    ),
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
                    color: AppColors.primary,
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
