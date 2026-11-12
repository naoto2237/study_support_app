// ======================================================================
// 【画面】ルームの壁紙の位置・大きさの調整
//
// 主なクラス: WallpaperAdjustScreen / WallpaperAdjustmentResult（調整結果）
// 開き方: ルームの中（room_space_screen.dart）で壁紙を選んだあと
// ======================================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:study_support_app/theme/app_palette.dart';
import 'package:study_support_app/theme/app_colors.dart';

class WallpaperAdjustScreen extends StatefulWidget {
  final File image;

  const WallpaperAdjustScreen({super.key, required this.image});

  @override
  State<WallpaperAdjustScreen> createState() => _WallpaperAdjustScreenState();
}

class _WallpaperAdjustScreenState extends State<WallpaperAdjustScreen> {
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  double _startScale = 1.0;
  Offset _startOffset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pal.page,

      appBar: AppBar(
        backgroundColor: context.pal.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,

        title: Text(
          '壁紙を調整',
          style: TextStyle(
            color: context.pal.text,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        leading: IconButton(
          icon: Icon(Icons.close, color: context.pal.text),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                context,
                WallpaperAdjustmentResult(scale: _scale, offset: _offset),
              );
            },
            child: const Text(
              '決定',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // =========================
              // 壁紙プレビュー
              // =========================
              Positioned.fill(
                child: ClipRect(
                  child: GestureDetector(
                    onScaleStart: (details) {
                      _startScale = _scale;
                      _startOffset = _offset;
                      _startFocalPoint = details.focalPoint;
                    },

                    onScaleUpdate: (details) {
                      setState(() {
                        // 拡大・縮小
                        _scale = (_startScale * details.scale).clamp(1.0, 4.0);

                        // 移動
                        final delta = details.focalPoint - _startFocalPoint;

                        _offset = _startOffset + delta;
                      });
                    },

                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: ClipRect(
                        child: Transform.translate(
                          offset: _offset,
                          child: Transform.scale(
                            scale: _scale,
                            alignment: Alignment.center,
                            child: Image.file(
                              widget.image,
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // =========================
              // 説明
              // =========================
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'ドラッグして移動・ピンチで拡大縮小',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              // =========================
              // リセット
              // =========================
              Positioned(
                right: 16,
                bottom: 16,
                child: Material(
                  color: context.pal.card,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      setState(() {
                        _scale = 1.0;
                        _offset = Offset.zero;
                      });
                    },
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.refresh_rounded,
                        color: AppColors.primary,
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

// ========================================
// 調整結果
// ========================================

class WallpaperAdjustmentResult {
  final double scale;
  final Offset offset;

  const WallpaperAdjustmentResult({required this.scale, required this.offset});
}
