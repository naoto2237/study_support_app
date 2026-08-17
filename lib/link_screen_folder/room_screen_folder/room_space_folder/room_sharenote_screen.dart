import 'package:flutter/material.dart';

class RoomShareNoteScreen extends StatelessWidget {
  const RoomShareNoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildNoteTile("英単語まとめノート", "更新：今日 09:15"),
          _buildNoteTile("数学の公式まとめ", "更新：昨日 21:30"),
          _buildNoteTile("化学 重要ポイント", "更新：7/1 18:45"),
          _buildNoteTile("現代文 読解メモ", "更新：6/30 22:10"),
          _buildNoteTile("物理 演習問題集", "更新：6/29 20:05"),
        ],
      ),
    );
  }

  Widget _buildNoteTile(String title, String updatedAt) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Color(0xFFEAF4FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.description_rounded,
            color: Color(0xFF258EDB),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          updatedAt,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.black38,
        ),
      ),
    );
  }
}
