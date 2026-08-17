import 'package:flutter/material.dart';
import '../room_space_folder/room_space.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomMakingScreen extends StatefulWidget {
  const RoomMakingScreen({super.key});

  @override
  State<RoomMakingScreen> createState() => _RoomMakingScreenState();
}

class _RoomMakingScreenState extends State<RoomMakingScreen> {
  int _selectedVisibility = 0;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF7F7F7);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final subtitleColor = isDark ? Colors.white60 : Colors.grey;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // キーボードを閉じる
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          foregroundColor: textColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: Text(
            "ルームを作る",
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: textColor),
          ),
        ),

        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              "ルーム設定",
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: textColor),
            ),

            const SizedBox(height: 25),
            Text(
              "ルームのタイトル *",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _titleController,
              style: TextStyle(color: textColor),
              cursorColor: const Color(0xFF3D96E8),
              decoration: InputDecoration(
                hintText: "例）TOEIC800点を目指す仲間のルーム",
                hintStyle: TextStyle(color: subtitleColor),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: borderColor),
                ),
                // 【修正】borderRadius と borderSide の間にカンマを追加
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Color(0xFF3D96E8), width: 2),
                ),
              ),
            ),

            const SizedBox(height: 25),
            Text(
              "ルームの説明（自由入力）",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _descriptionController,
              maxLines: 5,
              style: TextStyle(color: textColor),
              cursorColor: const Color(0xFF3D96E8),
              decoration: InputDecoration(
                hintText: "このルームの目的や活動内容を入力してください",
                hintStyle: TextStyle(color: subtitleColor),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: borderColor),
                ),
                // 【修正】borderRadius と borderSide の間にカンマを追加
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Color(0xFF3D96E8), width: 2),
                ),
              ),
            ),

            const SizedBox(height: 40),
            Text(
              "公開設定",
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: textColor),
            ),

            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                border: Border.all(
                  color: _selectedVisibility == 0
                      ? const Color(0xFF3D96E8)
                      : borderColor,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: RadioListTile<int>(
                value: 0,
                groupValue: _selectedVisibility,
                activeColor: const Color(0xFF3D96E8),
                onChanged: (value) {
                  setState(() {
                    _selectedVisibility = value!;
                  });
                },
                title: Text(
                  "🌐 全体公開",
                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                ),
                subtitle: Text("すべてのユーザーが参加できます", style: TextStyle(color: subtitleColor)),
              ),
            ),

            const SizedBox(height: 15),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                border: Border.all(
                  color: _selectedVisibility == 1
                      ? const Color(0xFF3D96E8)
                      : borderColor,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: RadioListTile<int>(
                value: 1,
                groupValue: _selectedVisibility,
                activeColor: const Color(0xFF3D96E8),
                onChanged: (value) {
                  setState(() {
                    _selectedVisibility = value!;
                  });
                },
                title: Text(
                  "🔒 非公開",
                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                ),
                subtitle: Text("招待されたユーザーのみ参加できます", style: TextStyle(color: subtitleColor)),
              ),
            ),

            const SizedBox(height: 40),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  if (_titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("ルームタイトルを入力してください")),
                    );
                    return;
                  }

                  await FirebaseFirestore.instance.collection("rooms").add({
                    "title": _titleController.text.trim(),
                    "description": _descriptionController.text.trim(),
                    "isPublic": _selectedVisibility == 0,
                    "members": 1,
                    "createdAt": FieldValue.serverTimestamp(),
                  });

                  if (!context.mounted) return;

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoomSpaceScreen(
                        roomTitle: _titleController.text.trim(),
                      ),
                    ),
                  );
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D96E8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "ルームを作成する",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}