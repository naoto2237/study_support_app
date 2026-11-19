// ======================================================================
// 【部品】ルームの中の「共有ノート」の一覧
//
// 主なクラス: RoomShareNoteScreen / _NoteTile（ノート1つ分）
// ・使うデータ: rooms/{id}/notes
//   { title, body, createdBy, createdByName, updatedBy, updatedByName,
//     createdAt, updatedAt }
// ・新しく更新した順に並べる。ノートを押すと読む・直す画面（room_note_edit_screen.dart）
// ・右下の「＋」で新しいノートを作る
// ・ルームのメンバーなら、だれでも読んで直せる（消せるのは作った人だけ）
// ・旧ファイル名: room_sharenote_screen.dart
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:study_support_app/screens/link/room/space/room_note_edit_screen.dart';
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/theme/app_palette.dart';
import 'package:study_support_app/theme/empty_message.dart';

class RoomShareNoteScreen extends StatefulWidget {
  final String roomId;

  const RoomShareNoteScreen({super.key, required this.roomId});

  @override
  State<RoomShareNoteScreen> createState() => _RoomShareNoteScreenState();
}

class _RoomShareNoteScreenState extends State<RoomShareNoteScreen> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _notes =
      FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('notes')
          .orderBy('updatedAt', descending: true)
          .snapshots();

  void _openNote({String? noteId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RoomNoteEditScreen(roomId: widget.roomId, noteId: noteId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _notes,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const EmptyMessage(
                  icon: Icons.cloud_off_rounded,
                  text: 'ノートを読み込めませんでした',
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              final notes = snapshot.data?.docs ?? [];

              if (notes.isEmpty) {
                return const EmptyMessage(
                  icon: Icons.description_outlined,
                  text: 'まだノートはありません',
                  subText: '右下の「＋」から、最初のノートを作ってみましょう',
                );
              }

              return ListView.separated(
                // 下は「＋」ボタンに重ならないよう広めにあける
                padding: const EdgeInsets.fromLTRB(17, 14, 17, 96),
                itemCount: notes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final doc = notes[index];

                  return _NoteTile(
                    key: ValueKey(doc.id),
                    data: doc.data(),
                    onTap: () => _openNote(noteId: doc.id),
                  );
                },
              );
            },
          ),
        ),

        // 新しいノート
        Positioned(
          right: 18,
          bottom: 18,
          child: SafeArea(
            child: FloatingActionButton(
              onPressed: () => _openNote(),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: const CircleBorder(),
              tooltip: 'ノートを作る',
              child: const Icon(Icons.add_rounded, size: 30),
            ),
          ),
        ),
      ],
    );
  }
}

// =========================================================
// ノート1つ分
// 左：オレンジのノートのアイコン（ルームの中のボタンと同じ色）
// まん中：題名、本文の書き出し（1行）、「更新：今日 9:15・たろう」
// =========================================================

class _NoteTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _NoteTile({super.key, required this.data, required this.onTap});

  // 今日なら「今日 9:15」、昨日なら「昨日 21:30」、それより前は「11/18」
  static String timeLabel(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    final hm = "${time.hour}:${time.minute.toString().padLeft(2, '0')}";

    if (day == today) return "今日 $hm";
    if (day == today.subtract(const Duration(days: 1))) return "昨日 $hm";
    if (time.year != now.year) return "${time.year}/${time.month}/${time.day}";
    return "${time.month}/${time.day}";
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    final title = (data['title'] ?? '').toString().trim();
    final body = (data['body'] ?? '').toString().trim().replaceAll('\n', ' ');
    final updatedAt = data['updatedAt'];
    final updatedByName = (data['updatedByName'] ?? '').toString();

    final updatedText = [
      if (updatedAt is Timestamp) "更新：${timeLabel(updatedAt.toDate())}",
      if (updatedByName.isNotEmpty) updatedByName,
    ].join("・");

    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(
                    alpha: p.isDark ? 0.22 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: AppColors.green,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? "題名なし" : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: title.isEmpty ? p.muted : p.text,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: p.secondary, fontSize: 12.5),
                      ),
                    ],
                    if (updatedText.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        updatedText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: p.muted, fontSize: 11.5),
                      ),
                    ],
                  ],
                ),
              ),

              Icon(Icons.chevron_right_rounded, color: p.muted),
            ],
          ),
        ),
      ),
    );
  }
}
