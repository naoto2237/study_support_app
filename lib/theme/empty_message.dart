// ======================================================================
// 【部品】何もないときの案内（アプリ全体で同じ見た目にする）
//
// 主なクラス: EmptyMessage
// ・うすい青の丸の中にアイコン、その下に案内の文
// ・例: 「通知はありません」「まだ友達がいません」「ユーザー名を検索してください」
// ・画面のまん中より少し上に出す（下にキーボードが出ても隠れにくい）
// ======================================================================

import 'package:flutter/material.dart';
import 'package:study_support_app/theme/app_colors.dart';

class EmptyMessage extends StatelessWidget {
  final IconData icon;
  final String text;

  // 2行目の小さい説明（なくてもよい）
  final String? subText;

  const EmptyMessage({
    super.key,
    required this.icon,
    required this.text,
    this.subText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: const Alignment(0, -0.4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : AppColors.primarySoft,
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            if (subText != null) ...[
              const SizedBox(height: 4),
              Text(
                subText!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: isDark ? Colors.white54 : Colors.black38,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
