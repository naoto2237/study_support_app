// ======================================================================
// 【色の一覧】アプリ全体で使う色
//
// 主なクラス: AppColors
// ・色を変えたいときは、ここを変える（各画面はこの名前で色を使う）
// ・primary（青）は、少し落ち着いた青 #2C86D4（2026-11-10 に決定）
// ・背景はうすい灰色、カードは白（白いカードが背景から浮いて見える）
// ======================================================================

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ---------------- 青（メインの色） ----------------
  // ボタン・選んでいるタブ・リンク・グラフなど
  static const Color primary = Color(0xFF2C86D4);

  // グラデーションの明るい側・濃い側（タイマーのカードなど）
  static const Color primaryLight = Color(0xFF4A9DE3);
  static const Color primaryDeep = Color(0xFF1F6FB8);

  // うすい青の面（アイコンの丸・選んでいる行など）
  static const Color primarySoft = Color(0xFFEAF3FC);

  // 進み具合のバーなどの土台
  static const Color primaryTrack = Color(0xFFD4E6F8);

  // 文字を選んだときの色
  static const Color selection = Color(0x552C86D4);

  // ---------------- 背景・線 ----------------
  // 画面の背景（うすい灰色）
  static const Color background = Color(0xFFF5F7FA);

  // カードの枠線
  static const Color border = Color(0xFFE5E8EC);

  // 一覧の行と行の間の線
  static const Color divider = Color(0xFFEEF0F3);
}
