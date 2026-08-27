import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'profile_icon_adjust_screen.dart';
import 'profile_edit_screen2.dart';

class ProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const ProfileEditScreen({super.key, required this.data});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _commentController = TextEditingController();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _userIdController = TextEditingController();

  final TextEditingController gradeController = TextEditingController();
  final TextEditingController goalController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController studyStyleController = TextEditingController();

  File? _selectedImage;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _commentController.text = widget.data["comment"] ?? "";
    _nameController.text = widget.data["name"] ?? "";
    _userIdController.text = widget.data["userId"] ?? "";
    gradeController.text = widget.data["grade"] ?? "";
    goalController.text = widget.data["goal"] ?? "";
    locationController.text = widget.data["location"] ?? "";
    studyStyleController.text = widget.data["studyStyle"] ?? "";
    _loadLatestProfile();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _nameController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _loadLatestProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (!snapshot.exists) return;

      final latestData = snapshot.data();

      if (latestData == null || !mounted) return;

      setState(() {
        widget.data.clear();
        widget.data.addAll(latestData);

        _commentController.text = latestData["comment"] ?? "";
      });
    } catch (e) {
      debugPrint("プロフィール情報取得エラー: $e");
    }
  }

  // ======================================================
  // アイコンを選択
  // ======================================================

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();

    final image = await picker.pickImage(source: source, imageQuality: 85);

    if (image == null) return;

    final selectedFile = File(image.path);

    // アイコン調整画面へ
    final adjustedImage = await Navigator.push<File>(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileIconAdjustScreen(image: selectedFile),
      ),
    );

    if (adjustedImage == null) return;

    setState(() {
      _selectedImage = adjustedImage;
    });
  }

  Future<String> _uploadImageToImageKit(File imageFile) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("ユーザーがログインしていません");
    }

    // 毎回違うファイル名にする
    final fileName = "${user.uid}_${DateTime.now().millisecondsSinceEpoch}.png";

    // Cloudflare Worker
    const workerUrl =
        "https://study-support-imagekit.naototomita930.workers.dev/";

    // ======================================================
    // ① WorkerからJWTを取得
    // ======================================================

    final authResponse = await http.post(
      Uri.parse(workerUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "uploadPayload": {
          "fileName": fileName,
          "folder": "profile_icons",

          // 毎回新しいファイルとして保存
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

    // ======================================================
    // ② ImageKitアップロード
    // ======================================================

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("https://upload.imagekit.io/api/v2/files/upload"),
    );

    request.headers["Accept"] = "application/json";

    request.files.add(
      await http.MultipartFile.fromPath("file", imageFile.path),
    );

    request.fields["fileName"] = fileName;

    request.fields["token"] = token.toString();

    request.fields["folder"] = "profile_icons";

    request.fields["useUniqueFileName"] = "false";

    // ======================================================
    // ③ ImageKitへ送信
    // ======================================================

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

    debugPrint("ImageKit新URL: $url");

    return url.toString();
  }

  Future<void> _editName() async {
    _nameController.text = widget.data["name"] ?? "";

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            "名前を変更",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: _nameController,
            maxLength: 20,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "名前を入力する",
              filled: true,
              fillColor: const Color(0xFFF7F7F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("キャンセル", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                final name = _nameController.text.trim();

                if (name.isEmpty) return;

                Navigator.pop(context, name);
              },
              child: const Text(
                "変更",
                style: TextStyle(
                  color: Color(0xFF3D96E8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) return;

    setState(() {
      widget.data["name"] = result;
      _nameController.text = result;
    });
  }

  Future<void> _editUserId() async {
    _userIdController.text = widget.data["userId"] ?? "";

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            "ユーザーIDを変更",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: _userIdController,
            maxLength: 20,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "ユーザーIDを入力する",
              filled: true,
              fillColor: const Color(0xFFF7F7F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("キャンセル", style: TextStyle(color: Colors.grey)),
            ),

            TextButton(
              onPressed: () {
                final userId = _userIdController.text.trim();

                if (userId.isEmpty) return;

                Navigator.pop(context, userId);
              },
              child: const Text(
                "変更",
                style: TextStyle(
                  color: Color(0xFF3D96E8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) return;

    setState(() {
      widget.data["userId"] = result;
      _userIdController.text = result;
    });
  }

  Future<void> _showIconOptions() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 上のつまみ
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "アイコンを変更",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFF3D96E8),
                  ),
                  title: const Text("カメラで撮影"),
                  onTap: _showIconOptions,
                ),

                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFF3D96E8),
                  ),
                  title: const Text("写真を選択"),
                  onTap: () {
                    Navigator.pop(context, "gallery");
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    "アイコンを削除",
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context, "delete");
                  },
                ),

                const SizedBox(height: 8),

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "キャンセル",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || result == null) return;

    if (result == "camera") {
      await _pickImage(ImageSource.camera);
    } else if (result == "gallery") {
      await _pickImage(ImageSource.gallery);
    } else if (result == "delete") {
      setState(() {
        _selectedImage = null;
        widget.data["icon"] = "";
      });
    }
  }

  // ======================================================
  // 保存
  // ======================================================
  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint("保存失敗: ユーザーがログインしていません");
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String? iconUrl = widget.data["icon"];

      // ==========================================
      // アイコンが変更されている場合
      // ==========================================

      if (_selectedImage != null) {
        debugPrint("① 調整済み画像をImageKitへアップロード開始");

        iconUrl = await _uploadImageToImageKit(_selectedImage!);

        debugPrint("② ImageKit URL: $iconUrl");

        if (iconUrl == null || iconUrl.isEmpty) {
          throw Exception("ImageKitからURLが返ってきませんでした");
        }
      }

      // ==========================================
      // Firestoreへ保存
      // ==========================================

      // ==========================================
      // ユーザーIDの重複チェック
      // ==========================================

      final userId = _userIdController.text.trim();

      if (userId.isEmpty) {
        throw Exception("ユーザーIDを入力する");
      }

      // @から始まっているか確認
      if (!userId.startsWith("@")) {
        throw Exception("ユーザーIDは@から始めてください");
      }

      // 同じユーザーIDを検索
      final existingUser = await FirebaseFirestore.instance
          .collection("users")
          .where("userId", isEqualTo: userId)
          .limit(1)
          .get();

      // 自分以外が同じユーザーIDを使用している場合
      if (existingUser.docs.isNotEmpty &&
          existingUser.docs.first.id != user.uid) {
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("このユーザーIDはすでに使用されています")));

        return;
      }

      // ==========================================
      // Firestoreへ保存
      // ==========================================

      debugPrint("③ Firestoreへ保存開始");

      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "name": _nameController.text.trim(),
        "userId": userId,
        "icon": iconUrl ?? "",
        "comment": _commentController.text.trim(),
      }, SetOptions(merge: true));

      debugPrint("④ Firestore保存成功");

      // ==========================================
      // 現在の画面にも保存した画像を反映
      // ==========================================

      if (iconUrl != null && iconUrl.isNotEmpty) {
        widget.data["icon"] = iconUrl;
      }

      widget.data["comment"] = _commentController.text.trim();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("プロフィールを保存しました")));

      // 少し表示してから戻る
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e, stackTrace) {
      debugPrint("プロフィール保存エラー: $e");

      debugPrint(stackTrace.toString());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("プロフィールの保存に失敗しました\n$e"),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ======================================================
  // アイコン表示
  // ======================================================

  Widget _buildProfileIcon() {
    if (_selectedImage != null) {
      return ClipOval(
        child: SizedBox(
          width: 96,
          height: 96,
          child: Image.file(
            _selectedImage!,
            width: 96,
            height: 96,
            fit: BoxFit.fill,
          ),
        ),
      );
    }

    final icon = widget.data["icon"] ?? "";

    if (icon.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: 96,
          height: 96,
          child: Image.network(icon, width: 96, height: 96, fit: BoxFit.fill),
        ),
      );
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
            fontSize: 19,
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
        padding: const EdgeInsets.fromLTRB(14, 24, 14, 40),
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
                  GestureDetector(
                    onTap: _showIconOptions,
                    child: _buildProfileIcon(),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: GestureDetector(
                      onTap: _showIconOptions,
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
              child: GestureDetector(
                onTap: _showIconOptions,
                child: const Text(
                  "アイコンを変更",
                  style: TextStyle(
                    color: Color(0xFF3D96E8),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
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

            GestureDetector(
              onTap: _editName,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          // fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.edit_outlined,
                      size: 19,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ==========================================
            // ユーザーID
            // ==========================================
            const Text(
              "ユーザーID",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            GestureDetector(
              onTap: _editUserId,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _userIdController.text.isEmpty
                            ? "未設定"
                            : _userIdController.text,
                        style: const TextStyle(
                          fontSize: 15,
                          //fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    const Icon(
                      Icons.edit_outlined,
                      size: 19,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ==========================================
            // プロフィールコメント
            // ==========================================
            const Text(
              "プロフィールコメント",
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
                hintText: "プロフィールコメントを入力する",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF7F7F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF3D96E8),
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            ProfileEditSection2(
              gradeController: gradeController,
              goalController: goalController,
              //locationController: locationController,
              //studyStyleController: studyStyleController,
            ),

            const SizedBox(height: 20),

            const Center(
              child: Text(
                "プロフィール情報を変更すると他のユーザーにも表示されます",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
