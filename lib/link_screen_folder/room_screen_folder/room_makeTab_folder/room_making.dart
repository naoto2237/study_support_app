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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // キーボードを閉じる
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "ルームを作る",
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
        ),

        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              "ルーム設定",
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 25),
            const Text(
              "ルームのタイトル *",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: "例）TOEIC800点を目指す仲間のルーム",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 25),
            const Text(
              "ルームの説明（自由入力）",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "このルームの目的や活動内容を入力してください",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 40),
            const Text(
              "公開設定",
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedVisibility == 0
                      ? const Color(0xFF3D96E8)
                      : Colors.grey.shade300,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: RadioListTile<int>(
                value: 0,
                groupValue: _selectedVisibility,
                onChanged: (value) {
                  setState(() {
                    _selectedVisibility = value!;
                  });
                },
                title: const Text(
                  "🌐 全体公開",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("すべてのユーザーが参加できます"),
              ),
            ),

            const SizedBox(height: 15),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedVisibility == 1
                      ? const Color(0xFF3D96E8)
                      : Colors.grey.shade300,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: RadioListTile<int>(
                value: 1,
                groupValue: _selectedVisibility,
                onChanged: (value) {
                  setState(() {
                    _selectedVisibility = value!;
                  });
                },
                title: const Text(
                  "🔒 非公開",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("招待されたユーザーのみ参加できます"),
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
