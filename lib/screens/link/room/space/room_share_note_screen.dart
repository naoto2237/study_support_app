// ======================================================================
// 【部品】ルームの中の「共有ノート」
//
// 主なクラス: RoomShareNoteScreen
// ・今は見本のノートを並べて表示しているだけ（データとはつながっていない）
// ・旧ファイル名: room_sharenote_screen.dart
// ======================================================================

import 'package:flutter/material.dart';
import 'package:study_support_app/theme/app_palette.dart';
import 'package:study_support_app/theme/app_colors.dart';

class RoomShareNoteScreen extends StatelessWidget {
  const RoomShareNoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildNoteTile(context, "英単語まとめノート", "更新：今日 09:15"),
          _buildNoteTile(context, "数学の公式まとめ", "更新：昨日 21:30"),
          _buildNoteTile(context, "化学 重要ポイント", "更新：7/1 18:45"),
          _buildNoteTile(context, "現代文 読解メモ", "更新：6/30 22:10"),
          _buildNoteTile(context, "物理 演習問題集", "更新：6/29 20:05"),
        ],
      ),
    );
  }

  Widget _buildNoteTile(BuildContext context, String title, String updatedAt) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: context.pal.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.pal.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: context.pal.primarySoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.description_rounded,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          updatedAt,
          style: TextStyle(fontSize: 12, color: context.pal.secondary),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: context.pal.muted),
      ),
    );
  }
}
