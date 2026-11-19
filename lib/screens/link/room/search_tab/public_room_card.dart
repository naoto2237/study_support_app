// ======================================================================
// 【部品】公開ルームのカード1枚分（「検索」タブの一覧に表示）
//
// 主なクラス: PublicRoomCard
// ・ルームへの参加、「入る」でルームの中（room_space_screen.dart）へ
// ・見た目は room_card_body.dart（「作成」タブのカードと同じ形）
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_support_app/screens/link/room/space/room_space_screen.dart';
import 'package:study_support_app/screens/link/room/room_card_body.dart';
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/theme/app_palette.dart';
import 'package:study_support_app/theme/error_dialog.dart';

// =============================================================
// 公開ルームカード
// =============================================================

class PublicRoomCard extends StatelessWidget {
  final String title;
  final String roomId;
  final String ownerId;
  final String description;
  final String goal;

  const PublicRoomCard({
    super.key,
    required this.title,
    required this.roomId,
    this.ownerId = "",
    this.description = "",
    this.goal = "",
  });

  // ===========================================================
  // ルーム参加
  // ===========================================================

  Future<void> _joinRoom(BuildContext context) async {
    try {
      // -------------------------------------------------------
      // ユーザー取得
      // -------------------------------------------------------

      User? user = FirebaseAuth.instance.currentUser;

      // ログインしていなければ匿名ログイン
      if (user == null) {
        final credential = await FirebaseAuth.instance.signInAnonymously();

        user = credential.user;
      }

      if (user == null) {
        throw Exception("ユーザー情報を取得できませんでした");
      }

      // -------------------------------------------------------
      // ルーム取得
      // -------------------------------------------------------

      final roomRef = FirebaseFirestore.instance
          .collection("rooms")
          .doc(roomId);

      final roomSnapshot = await roomRef.get();

      if (!roomSnapshot.exists) {
        throw Exception("このルームは存在しません");
      }

      final data = roomSnapshot.data() as Map<String, dynamic>;

      // -------------------------------------------------------
      // 公開ルームか確認
      // -------------------------------------------------------

      final bool isPublic = data["isPublic"] ?? false;

      if (!isPublic) {
        throw Exception("このルームは非公開です");
      }

      // -------------------------------------------------------
      // membersにユーザー追加
      // -------------------------------------------------------

      // まだメンバーでないときだけ、参加した時刻を入れる
      // （入るたびに入れると、参加した時刻が今に変わり、
      //   ルームの「最近のできごと」に「参加しました」が何度も出てしまう）
      final memberRef = roomRef.collection("members").doc(user.uid);
      final memberSnapshot = await memberRef.get();

      if (!memberSnapshot.exists) {
        await memberRef.set({"joinedAt": FieldValue.serverTimestamp()});
      }

      // -------------------------------------------------------
      // RoomSpaceScreenへ
      // -------------------------------------------------------

      if (!context.mounted) return;

      Navigator.push(
        context,

        MaterialPageRoute(
          builder: (_) => RoomSpaceScreen(
            roomTitle: data["title"] ?? title,

            roomId: roomId,
          ),
        ),
      );
    } catch (e) {
      debugPrint("ルームへの参加に失敗しました: $e");

      if (!context.mounted) return;

      showErrorDialog(context, "ルームに参加できませんでした。\n通信の状態を確かめて、もう一度お試しください。");
    }
  }

  // ===========================================================
  // Build（見た目は room_card_body.dart。「作成」タブのカードと同じ形）
  // ===========================================================

  @override
  Widget build(BuildContext context) {
    return RoomCardBody(
      roomId: roomId,
      title: title,
      description: description,
      goal: goal,
      isPublic: true,
      ownerId: ownerId,
      onTap: () => _confirmAndJoin(context),

      // 右の「参加」ボタン（青い丸みのあるボタン）
      trailing: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: SizedBox(
          height: 34,
          child: ElevatedButton(
            onPressed: () => _confirmAndJoin(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            child: const Text(
              "参加",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  // 確かめてから参加する
  Future<void> _confirmAndJoin(BuildContext context) async {
    final p = context.pal;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: p.card,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "ルームに入る",
            style: TextStyle(
              color: p.text,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "「$title」に入りますか？",
            style: TextStyle(color: p.text, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text("キャンセル", style: TextStyle(color: p.secondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                "入る",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result == true && context.mounted) {
      await _joinRoom(context);
    }
  }
}
