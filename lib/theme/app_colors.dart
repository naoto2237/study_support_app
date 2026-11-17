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

  // ---------------- 赤と緑の文字（2026-11-17 に決定） ----------------
  // 青がメイン。タブから開く画面の要所の「文字の色」にだけ使う
  //   赤：取り消す・やめる・拒否など「なくなる」操作
  //   緑：「友達になりました」・合計など「うまくいった・たまった」こと
  // （応援・目標達成の数字や、上の帯の色には使わない）
  static const Color red = Color(0xFFE5484D);

  static const Color green = Color(0xFF2EAD6B);

  // ---------------- アイコンに使うほかの色（2026-11-17 に決定） ----------------
  // アイコンが青ばかりにならないよう、中身に合わせて使い分ける
  // （文字・数字・上の帯・ボタンには使わない）
  static const Color orange = Color(0xFFF2994A);

  // ---------------- 背景・線 ----------------
  // 画面の背景（うすい灰色）
  static const Color background = Color(0xFFF5F7FA);

  // カードの枠線
  static const Color border = Color(0xFFE5E8EC);

  // 一覧の行と行の間の線
  static const Color divider = Color(0xFFEEF0F3);

  // ---------------- グラフの吹き出し ----------------
  // 棒をタップしたときに出る吹き出し（うすい青。2026-11-12 に決定）
  // 面はうすい青、枠は少し濃いうすい青、時間の数字は濃い青
  static const Color tooltipBackground = primarySoft;
  static const Color tooltipBorder = Color(0xFFC9DFF4);
  static const Color tooltipText = primaryDeep;
  static const Color tooltipSubText = Color(0xFF4A7DB0);

  // ダークモードのとき（暗いカードの上で、青みのある面にする）
  static const Color tooltipBackgroundDark = Color(0xFF1E3550);
  static const Color tooltipBorderDark = Color(0xFF2F5478);
  static const Color tooltipTextDark = Colors.white;
  static const Color tooltipSubTextDark = Color(0xFFB5D4F4);
}
