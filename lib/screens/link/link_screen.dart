// ======================================================================
// 【画面】Link（下のタブ「Link」）
//
// 主なクラス: LinkScreen
// 開き方: main.dart の MainNavigationScreen
// ・3つの入口：ユーザー検索／Q&A／ルーム
// ・上部：チャット・通知のアイコン
// ======================================================================

import 'package:flutter/material.dart';
import 'package:study_support_app/screens/link/user_search_screen.dart';
import 'package:study_support_app/screens/link/qna_screen.dart';
import 'package:study_support_app/screens/link/room/room_screen.dart';
import 'package:study_support_app/screens/chat/chat_list_screen.dart';
import 'package:study_support_app/screens/notification/notification_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_support_app/theme/app_colors.dart';

class LinkScreen extends StatelessWidget {
  const LinkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF121212) : AppColors.background;
    final appBarColor = isDark ? AppColors.primary : AppColors.primary;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;
    final borderColor = isDark ? Colors.grey.shade800 : AppColors.border;
    final trailingColor = isDark ? Colors.white60 : Colors.grey;

    return Scaffold(
      backgroundColor: bgColor,

      appBar: AppBar(
        backgroundColor: appBarColor,

        iconTheme: const IconThemeData(color: Colors.white),

        title: Text(
          'Link',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: false,

        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 9),
            child: IconButton(
              icon: const Icon(Icons.chat_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatListScreen(),
                  ), // ※ファイル名に合わせて変更
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .collection('friend_requests')
                  .where('status', isEqualTo: 'pending')
                  .where('isRead', isEqualTo: false)
                  .snapshots(),

              builder: (context, requestSnapshot) {
                final hasFriendRequest =
                    requestSnapshot.hasData &&
                    requestSnapshot.data!.docs.isNotEmpty;

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection('notifications')
                      .where('isRead', isEqualTo: false)
                      .snapshots(),

                  builder: (context, notificationSnapshot) {
                    final hasNotification =
                        notificationSnapshot.hasData &&
                        notificationSnapshot.data!.docs.isNotEmpty;

                    final hasUnread = hasFriendRequest || hasNotification;

                    return IconButton(
                      onPressed: () async {
                        // =========================================
                        // 先に通知画面を表示
                        // =========================================
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationScreen(),
                          ),
                        );

                        // =========================================
                        // その後、未読を既読にする
                        // =========================================
                        final user = FirebaseAuth.instance.currentUser;

                        if (user != null) {
                          final firestore = FirebaseFirestore.instance;

                          // 未読の友達申請を既読にする
                          final friendRequests = await firestore
                              .collection('users')
                              .doc(user.uid)
                              .collection('friend_requests')
                              .where('isRead', isEqualTo: false)
                              .get();

                          for (final doc in friendRequests.docs) {
                            await doc.reference.update({'isRead': true});
                          }

                          // 未読の通知を既読にする
                          final notifications = await firestore
                              .collection('users')
                              .doc(user.uid)
                              .collection('notifications')
                              .where('isRead', isEqualTo: false)
                              .get();

                          for (final doc in notifications.docs) {
                            await doc.reference.update({'isRead': true});
                          }
                        }
                      },

                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications_none),

                          // =========================================
                          // 赤い点
                          // =========================================
                          if (hasUnread)
                            Positioned(
                              right: -1,
                              top: -1,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // スクロールできる作りにして、キーボードで縦が縮んだときも
      // はみ出し（黄色と黒の縞）が出ないようにする
      body: SingleChildScrollView(
        // 見出しの文字の高さを、ホームの日付の高さにそろえる
        padding: const EdgeInsets.fromLTRB(17, 11, 17, 24),

        child: Column(
          children: [
            // 上部メッセージ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              child: Column(
                children: [
                  Text(
                    "一緒に学ぶ仲間を見つけよう",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 3.5),
                  Text(
                    "同じ目標を持つ仲間とつながって、学びをもっと楽しく",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: subtitleColor,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _buildMenuCard(
              context,
              icon: Icons.person_search_rounded,
              title: 'ユーザー検索',
              subtitle: '同じ目標を持つ学習仲間を探す',
              screen: const UserSearchScreen(),
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              borderColor: borderColor,
              trailingColor: trailingColor,
            ),

            const SizedBox(height: 12),

            _buildMenuCard(
              context,
              icon: Icons.forum_rounded,
              title: 'Q&A',
              subtitle: '質問・回答で疑問を解決する',
              screen: QnaListScreen(),
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              borderColor: borderColor,
              trailingColor: trailingColor,
            ),

            const SizedBox(height: 12),

            _buildMenuCard(
              context,
              icon: Icons.groups_rounded,
              title: 'ルーム',
              subtitle: '同じ目標の仲間と交流する',
              screen: const RoomScreen(),
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              borderColor: borderColor,
              trailingColor: trailingColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget screen,
    required Color cardColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required Color trailingColor,
  }) {
    return Card(
      color: cardColor,
      elevation: 0,
      // カードの外側の余白をなくし、画面の左右の余白（16）をほかの画面とそろえる
      margin: EdgeInsets.zero,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 1),
      ),

      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

        // アイコンは、うすい青の角丸の四角にのせる
        // （ホームの「曜日ごとの目標を設定」やAIサポートの質問例と同じ形）
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.primary.withValues(alpha: 0.18)
                : AppColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 26, color: AppColors.primary),
        ),

        title: Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            style: TextStyle(color: subtitleColor, fontSize: 13),
          ),
        ),

        trailing: Icon(
          Icons.chevron_right_rounded,
          color: trailingColor,
          size: 24,
        ),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
      ),
    );
  }
}
