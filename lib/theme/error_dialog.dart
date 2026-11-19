// ======================================================================
// 【部品】うまくいかなかったことを知らせる小さな画面
//
// 主な関数: showErrorDialog
// ・下に出る黒いお知らせ（SnackBar）は使わないので、そのかわりに使う
// ・カードを押したときなど、画面の中に赤い文字を出す場所がないときだけ使う
// ======================================================================

import 'package:flutter/material.dart';
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/theme/app_palette.dart';

Future<void> showErrorDialog(BuildContext context, String message) {
  final p = context.pal;

  return showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
      content: Text(
        message,
        style: TextStyle(color: p.text, fontSize: 14, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text("閉じる", style: TextStyle(color: AppColors.primary)),
        ),
      ],
    ),
  );
}
