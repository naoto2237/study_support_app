// ======================================================================
// 【画面】ルームの機能画面の共通レイアウト（メンバー／チャット／共有ノート）
//
// 主なクラス: RoomFeatureScreen
// 開き方: ルームの中（room_space_screen.dart）でメンバー・チャット・共有ノートを押す
// ・タイトル、ルームの壁紙、中身（child）をまとめて表示する
// ・壁紙の変更（wallpaper_adjust_screen.dart）もここから
// ======================================================================

import 'package:flutter/material.dart';
import 'package:study_support_app/theme/app_palette.dart';
import 'package:study_support_app/theme/error_dialog.dart';
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

    if (!mounted) return;

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

      // 壁紙はすぐ画面に出るので、保存のお知らせは出さない
      await _saveWallpaper(selectedImage, result.scale, result.offset);
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
      // 読めないときは、いつもの背景のままにする（お知らせは出さない）
      debugPrint('壁紙読み込みエラー: $e');
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

      showErrorDialog(context, '壁紙を保存できませんでした。\nルームを開きなおすと、元の背景に戻ります。');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 背景画像をキーボードで動かさない
      resizeToAvoidBottomInset: false,

      appBar: AppBar(
        backgroundColor: context.pal.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,

        // 文字の位置は、ほかの画面（Q&A・ユーザー検索・ルームの中など）と同じ
        // （戻るボタンのすぐ右に、左寄せで出す）
        titleSpacing: 0,
        iconTheme: IconThemeData(color: context.pal.text),

        // 下の区切り線（ルームの中の上の帯と同じ）
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.pal.divider),
        ),

        title: Text(
          widget.title,
          style: TextStyle(
            color: context.pal.text,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: IconButton(
              icon: Icon(Icons.wallpaper, color: context.pal.text, size: 24),
              onPressed: _changeWallpaper,
            ),
          ),
        ],
      ),

      body: Container(
        color: context.pal.field,
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
