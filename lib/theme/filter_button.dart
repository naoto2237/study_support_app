// ======================================================================
// 【部品】絞り込みのボタン（「学年・職種 ▼」など）
//
// 主なクラス: FilterButton
// 使う場所: ユーザー検索／ルームを探す／比較の相手選び
// ・押すと一覧（option_picker.dart）が出て、1つえらぶ。「指定しない」で外せる
// ・えらんでいるときは、青い丸いボタンに、えらんだものを出す
// ======================================================================

import 'package:flutter/material.dart';
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/theme/app_palette.dart';
import 'package:study_support_app/theme/option_picker.dart';

class FilterButton extends StatelessWidget {
  // 何で絞り込むか（「学年・職種」など）
  final String title;
  final List<String> options;

  // えらんでいるもの（指定しないときは null）
  final String? value;
  final ValueChanged<String?> onChanged;

  const FilterButton({
    super.key,
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final active = value != null;

    return Material(
      color: active ? AppColors.primary : p.card,
      shape: StadiumBorder(
        side: BorderSide(color: active ? AppColors.primary : p.border),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () async {
          final picked = await showOptionPicker(
            context,
            title: '$titleで絞り込む',
            options: options,
            selected: value ?? '',
            allowClear: true,
          );
          if (picked == null) return;
          onChanged(picked.isEmpty ? null : picked);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value ?? title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: active ? Colors.white : p.text,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.expand_more_rounded,
                size: 18,
                color: active ? Colors.white : p.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
