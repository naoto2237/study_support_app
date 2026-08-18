import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class ProfileIconAdjustScreen extends StatefulWidget {
  final File image;

  const ProfileIconAdjustScreen({
    super.key,
    required this.image,
  });

  @override
  State<ProfileIconAdjustScreen> createState() =>
      _ProfileIconAdjustScreenState();
}

class _ProfileIconAdjustScreenState
    extends State<ProfileIconAdjustScreen> {
  // ======================================================
  // 調整値
  // ======================================================

  double _scale = 1.0;
  Offset _offset = Offset.zero;

  double _startScale = 1.0;
  Offset _startOffset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;

  // ======================================================
  // プレビューサイズ
  // ======================================================

  double _previewSize = 300.0;

  // ======================================================
  // 保存対象
  // ======================================================

  final GlobalKey _previewKey = GlobalKey();

  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  // ======================================================
  // 画像読み込み
  // ======================================================

  Future<void> _loadImage() async {
    try {
      await widget.image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _imageLoaded = true;
      });
    } catch (e) {
      debugPrint('画像読み込みエラー: $e');
    }
  }

  // ======================================================
  // 移動範囲
  // ======================================================

  Offset _clampOffset(Offset offset) {
    final maxOffset =
        (_previewSize * (_scale - 1)) / 2;

    return Offset(
      offset.dx.clamp(
        -maxOffset,
        maxOffset,
      ),
      offset.dy.clamp(
        -maxOffset,
        maxOffset,
      ),
    );
  }

  // ======================================================
  // プレビューの「画像部分」だけを保存
  //
  // ClipOvalはここには入れない
  // ======================================================

  Future<File?> _capturePreview() async {
    try {
      final renderObject =
      _previewKey.currentContext?.findRenderObject();

      if (renderObject is! RenderRepaintBoundary) {
        debugPrint(
          'RenderRepaintBoundaryが取得できません',
        );
        return null;
      }

      final ui.Image image =
      await renderObject.toImage(
        pixelRatio: 3.0,
      );

      final ByteData? byteData =
      await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        return null;
      }

      final Uint8List bytes =
      byteData.buffer.asUint8List();

      final directory =
      await getTemporaryDirectory();

      final file = File(
        '${directory.path}/profile_icon_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      await file.writeAsBytes(bytes);

      return file;
    } catch (e) {
      debugPrint(
        'プレビュー保存エラー: $e',
      );

      return null;
    }
  }

  // ======================================================
  // 決定
  // ======================================================

  Future<void> _complete() async {
    if (!_imageLoaded) return;

    final file = await _capturePreview();

    if (!mounted) return;

    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '画像の保存に失敗しました',
          ),
        ),
      );

      return;
    }

    Navigator.pop(
      context,
      file,
    );
  }

  // ======================================================
  // Build
  // ======================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF7F7F7),

      // ==================================================
      // AppBar
      // ==================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor:
        Colors.transparent,
        elevation: 0,

        title: const Text(
          'アイコンを調整',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: Colors.black87,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        actions: [
          TextButton(
            onPressed:
            _imageLoaded ? _complete : null,
            child: const Text(
              '決定',
              style: TextStyle(
                color: Color(0xFF258EDB),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),

      // ==================================================
      // 本体
      // ==================================================

      body: LayoutBuilder(
        builder: (
            context,
            constraints,
            ) {
          final previewSize =
          constraints.maxWidth < 300
              ? constraints.maxWidth - 32
              : 300.0;

          _previewSize = previewSize;

          return Stack(
            children: [

              // ==================================================
              // アイコンプレビュー
              // ==================================================

              Center(
                child: GestureDetector(
                  onScaleStart: (details) {
                    _startScale = _scale;
                    _startOffset = _offset;
                    _startFocalPoint =
                        details.focalPoint;
                  },

                  onScaleUpdate: (details) {
                    setState(() {
                      // 拡大
                      _scale =
                          (_startScale *
                              details.scale)
                              .clamp(
                            1.0,
                            4.0,
                          );

                      // 移動
                      final delta =
                          details.focalPoint -
                              _startFocalPoint;

                      final newOffset =
                          _startOffset +
                              delta;

                      _offset =
                          _clampOffset(
                            newOffset,
                          );
                    });
                  },

                  // ==================================================
                  // ここは「正方形」を保存する
                  // ==================================================

                  child: RepaintBoundary(
                    key: _previewKey,

                    child: SizedBox(
                      width: previewSize,
                      height: previewSize,

                      child: ClipRect(
                        child: Container(
                          color: Colors.white,

                          child: Transform.translate(
                            offset: _offset,

                            child: Transform.scale(
                              scale: _scale,
                              alignment:
                              Alignment.center,

                              child: Image.file(
                                widget.image,
                                width:
                                previewSize,
                                height:
                                previewSize,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ==================================================
              // 円形のガイド
              //
              // 保存されない
              // ==================================================

              Center(
                child: IgnorePointer(
                  child: Container(
                    width: previewSize,
                    height: previewSize,

                    decoration:
                    BoxDecoration(
                      shape: BoxShape.circle,

                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),

              // ==================================================
              // 説明
              // ==================================================

              Positioned(
                top: 20,
                left: 0,
                right: 0,

                child: Center(
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),

                    decoration:
                    BoxDecoration(
                      color: Colors.black
                          .withValues(
                        alpha: 0.55,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),
                    ),

                    child: const Text(
                      'ドラッグして移動・ピンチで拡大縮小',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              // ==================================================
              // リセット
              // ==================================================

              Positioned(
                right: 16,
                bottom: 16,

                child: Material(
                  color: Colors.white,
                  shape:
                  const CircleBorder(),
                  elevation: 2,

                  child: InkWell(
                    customBorder:
                    const CircleBorder(),

                    onTap: () {
                      setState(() {
                        _scale = 1.0;
                        _offset =
                            Offset.zero;
                      });
                    },

                    child:
                    const SizedBox(
                      width: 48,
                      height: 48,

                      child: Icon(
                        Icons
                            .refresh_rounded,
                        color:
                        Color(0xFF258EDB),
                        size: 25,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}