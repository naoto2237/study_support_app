// ======================================================================
// 【画面】ルームの機能画面の共通レイアウト（メンバー／チャット／共有ノート）
//
// 主なクラス: RoomFeatureScreen
// 開き方: ルームの中（room_space_screen.dart）でメンバー・チャット・共有ノートを押す
// ・タイトル、ルームの壁紙、中身（child）をまとめて表示する
// ・壁紙の変更（wallpaper_adjust_screen.dart）もここから
// ======================================================================

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:study_support_app/screens/link/room/space/wallpaper_adjust_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =========================================================
// 専用画面の共通レイアウト
// =========================================================
class RoomFeatureScreen extends StatefulWidget {
  final String title;
  final IconData icon;
  final String backgroundImage;
  final Widget child;
  final String roomId;

  const RoomFeatureScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.backgroundImage,
    required this.child,
    required this.roomId,
  });

  @override
  State<RoomFeatureScreen> createState() => _RoomFeatureScreenState();
}

class _RoomFeatureScreenState extends State<RoomFeatureScreen> {
  File? _selectedBackground;

  double _backgroundScale = 1.0;
  Offset _backgroundOffset = Offset.zero;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadWallpaper();
  }

  // 壁紙を選択
  Future<void> _changeWallpaper() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    final File selectedImage = File(image.path);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WallpaperAdjustScreen(image: selectedImage),
      ),
    );

    if (result == null) return;

    if (result is WallpaperAdjustmentResult) {
      setState(() {
        _selectedBackground = selectedImage;
        _backgroundScale = result.scale;
        _backgroundOffset = result.offset;
      });

      await _saveWallpaper(selectedImage, result.scale, result.offset);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('壁紙を保存しました'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadWallpaper() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      final key = base64Url.encode(utf8.encode('${user.uid}_${widget.roomId}'));

      final path = prefs.getString('wallpaper_path_$key');

      if (path == null || path.isEmpty) {
        debugPrint('保存された壁紙はありません');
        return;
      }

      final file = File(path);

      // ファイルが実際に存在するか確認
      if (!await file.exists()) {
        debugPrint('保存された壁紙ファイルがありません');
        return;
      }

      final scale = prefs.getDouble('wallpaper_scale_$key') ?? 1.0;

      final offsetX = prefs.getDouble('wallpaper_offset_x_$key') ?? 0.0;

      final offsetY = prefs.getDouble('wallpaper_offset_y_$key') ?? 0.0;

      if (!mounted) return;

      setState(() {
        _selectedBackground = file;
        _backgroundScale = scale;
        _backgroundOffset = Offset(offsetX, offsetY);
      });

      debugPrint('壁紙を読み込みました');
    } catch (e) {
      debugPrint('壁紙読み込みエラー: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('壁紙の読み込みに失敗しました\n$e')));
    }
  }

  Future<void> _saveWallpaper(File image, double scale, Offset offset) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      // アプリ専用の保存場所
      final directory = await getApplicationDocumentsDirectory();

      final wallpaperDirectory = Directory('${directory.path}/wallpapers');

      if (!await wallpaperDirectory.exists()) {
        await wallpaperDirectory.create(recursive: true);
      }

      // ユーザーID + ルームIDから安全な名前を作る
      final key = base64Url.encode(utf8.encode('${user.uid}_${widget.roomId}'));

      final wallpaperFile = File('${wallpaperDirectory.path}/$key');

      // 選択した画像を端末内にコピー
      await image.copy(wallpaperFile.path);

      // 設定値を保存
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('wallpaper_path_$key', wallpaperFile.path);

      await prefs.setDouble('wallpaper_scale_$key', scale);

      await prefs.setDouble('wallpaper_offset_x_$key', offset.dx);

      await prefs.setDouble('wallpaper_offset_y_$key', offset.dy);

      debugPrint('壁紙を保存しました');
      debugPrint(wallpaperFile.path);
    } catch (e) {
      debugPrint('壁紙保存エラー: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('壁紙の保存に失敗しました\n$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 背景画像をキーボードで動かさない
      resizeToAvoidBottomInset: false,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 24),
          onPressed: () => Navigator.pop(context),
        ),

        title: Transform.translate(
          offset: const Offset(-8, 0),
          child: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: IconButton(
              icon: const Icon(
                Icons.wallpaper,
                color: Colors.black87,
                size: 24,
              ),
              onPressed: _changeWallpaper,
            ),
          ),
        ],
      ),

      body: Container(
        color: const Color(0xFFF7F7F7),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ==========================================
            // 背景画像
            // 完全に固定する
            // ==========================================
            if (_selectedBackground != null)
              Positioned.fill(
                child: ClipRect(
                  child: Transform.translate(
                    offset: _backgroundOffset,
                    child: Transform.scale(
                      scale: _backgroundScale,
                      alignment: Alignment.center,
                      child: Image.file(
                        _selectedBackground!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),

            // ==========================================
            // 背景の上にチャット画面
            // ==========================================
            Positioned.fill(child: widget.child),
          ],
        ),
      ),
    );
  }
}
