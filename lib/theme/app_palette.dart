// ======================================================================
// 【色】明るい画面・暗い画面（ダークモード）で切りかわる色
//
// 主なクラス: AppPalette
// 使い方: final p = AppPalette.of(context);  →  p.card, p.text など
// ・画面の背景（page）の上に、白いカード（card）を並べる作りの色
// ・暗い画面では、背景は黒に近い色、カードは少し明るい灰色になる
// ・青（AppColors.primary）など、明るさで変わらない色は app_colors.dart を使う
// ======================================================================

import 'package:flutter/material.dart';
import 'package:study_support_app/theme/app_colors.dart';

class AppPalette {
  final bool isDark;

  // 画面の背景
  final Color page;

  // カード・上の帯（AppBar）・下から出る画面などの面
  final Color card;

  // カードの中の、少しくぼんだ面（入力欄・切りかえボタンの土台など）
  final Color field;

  // 文字（本文・補足・うすい文字）
  final Color text;
  final Color secondary;
  final Color muted;

  // カードの枠・行の区切り線
  final Color border;
  final Color divider;

  // うすい青の面（アイコンの丸・選んでいる行など）
  final Color primarySoft;

  const AppPalette._({
    required this.isDark,
    required this.page,
    required this.card,
    required this.field,
    required this.text,
    required this.secondary,
    required this.muted,
    required this.border,
    required this.divider,
    required this.primarySoft,
  });

  static const AppPalette light = AppPalette._(
    isDark: false,
    page: AppColors.background,
    card: Colors.white,
    field: AppColors.background,
    text: Colors.black87,
    secondary: Colors.black54,
    muted: Colors.black38,
    border: AppColors.border,
    divider: AppColors.divider,
    primarySoft: AppColors.primarySoft,
  );

  static const AppPalette dark = AppPalette._(
    isDark: true,
    page: Color(0xFF121212),
    card: Color(0xFF1E1E1E),
    field: Color(0xFF2A2A2A),
    text: Colors.white,
    secondary: Colors.white70,
    muted: Colors.white38,
    border: Colors.white12,
    divider: Colors.white12,
    primarySoft: Color(0x2E2C86D4),
  );

  static AppPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}

// 短く書くため： context.pal.card のように使う
extension AppPaletteContext on BuildContext {
  AppPalette get pal => AppPalette.of(this);
}
