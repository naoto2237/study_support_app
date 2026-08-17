import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const ProfileEditScreen({super.key, required this.data});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _commentController = TextEditingController();

  File? _selectedImage;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _commentController.text = widget.data["comment"] ?? "";
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ======================================================
  // アイコンを選択
  // ======================================================

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      _selectedImage = File(image.path);
    });
  }

  Future<String> _uploadImageToImageKit(File imageFile) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("ユーザーがログインしていません");
    }

    final fileName = "${user.uid}.jpg";

    // Cloudflare Worker
    const workerUrl =
        "https://study-support-imagekit.naototomita930.workers.dev/";

    // ------------------------------------------
    // ① WorkerからJWTを取得
    // ------------------------------------------

    final authResponse = await http.post(
      Uri.parse(workerUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "uploadPayload": {
          "fileName": fileName,
          "folder": "profile_icons",
          "useUniqueFileName": "false",
        },
      }),
    );

    if (authResponse.statusCode != 200) {
      throw Exception(
        "ImageKit認証情報の取得に失敗しました: "
        "${authResponse.statusCode}",
      );
    }

    final authData = jsonDecode(authResponse.body);

    final token = authData["token"];

    if (token == null || token.toString().isEmpty) {
      throw Exception("ImageKit tokenが取得できませんでした");
    }

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("https://upload.imagekit.io/api/v2/files/upload"),
    );

    request.headers["Accept"] = "application/json";

    request.files.add(
      await http.MultipartFile.fromPath("file", imageFile.path),
    );

    request.fields["fileName"] = fileName;
    request.fields["token"] = token;
    request.fields["folder"] = "profile_icons";
    request.fields["useUniqueFileName"] = "false";

    // ------------------------------------------
    // ③ ImageKitへ送信
    // ------------------------------------------

    final response = await request.send();

    final responseBody = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        "ImageKitアップロード失敗: "
        "${response.statusCode}\n$responseBody",
      );
    }

    final result = jsonDecode(responseBody);

    final url = result["url"];

    if (url == null || url.toString().isEmpty) {
      throw Exception("ImageKitから画像URLを取得できませんでした");
    }

    return url.toString();
  }

  // ======================================================
  // 保存
  // ======================================================

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      String? iconUrl = widget.data["icon"];

      // ------------------------------------------
      // アイコンが変更されている場合
      // ------------------------------------------
      if (_selectedImage != null) {
        iconUrl = await _uploadImageToImageKit(_selectedImage!);
      }

      // ------------------------------------------
      // Firestoreへ保存
      // ------------------------------------------
      await FirebaseFirestore.instance.collection("users").doc(user.uid).update(
        {"icon": iconUrl ?? "", "comment": _commentController.text.trim()},
      );

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      debugPrint("プロフィール保存エラー: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("保存に失敗しました\n$e"),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // ======================================================
  // アイコン表示
  // ======================================================

  Widget _buildProfileIcon() {
    if (_selectedImage != null) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: FileImage(_selectedImage!),
      );
    }

    final icon = widget.data["icon"] ?? "";

    if (icon.isNotEmpty) {
      return CircleAvatar(radius: 50, backgroundImage: NetworkImage(icon));
    }

    return CircleAvatar(
      radius: 50,
      backgroundColor: const Color(0xFF3D96E8).withOpacity(0.12),
      child: const Icon(Icons.person, size: 65, color: Color(0xFF3D96E8)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.data["name"] ?? "名前未設定";

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          "プロフィールを編集",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: true,

        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: const Text(
              "保存",
              style: TextStyle(
                color: Color(0xFF3D96E8),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // アイコン
            // ==========================================
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildProfileIcon(),

                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D96E8),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Center(
              child: Text(
                "アイコンを変更",
                style: TextStyle(
                  color: const Color(0xFF3D96E8),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 35),

            // ==========================================
            // 名前
            // ==========================================
            const Text(
              "名前",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ==========================================
            // 一言コメント
            // ==========================================
            const Text(
              "一言コメント",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _commentController,
              maxLength: 50,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "一言コメントを入力してください",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF7F7F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF3D96E8),
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "プロフィール情報を変更すると、他のユーザーにも表示されます。",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
