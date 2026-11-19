// ======================================================================
// 【部品】一覧から1つえらぶ（学年・職種、学習目標、教科、絞り込み）
//
// 主な関数・クラス: showOptionPicker / OptionField
// ・showOptionPicker：下から出る画面に、えらぶ項目をボタンで並べる。えらんだら閉じて返す
// ・OptionField：入力欄と同じ見た目の欄。押すと showOptionPicker が開く
//   （Form の中で使えて、空のときは validator の文を赤で出す）
// ======================================================================

import 'package:flutter/material.dart';
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/theme/app_palette.dart';

// えらばれたもの（閉じただけなら null）
// allowClear が true のときは、いちばん上に「指定しない」を出し、えらぶと '' を返す
Future<String?> showOptionPicker(
  BuildContext context, {
  required String title,
  required List<String> options,
  String? selected,
  bool allowClear = false,
  IconData Function(String)? iconOf,
}) async {
  // えらぶ前に、入力中の欄をおわらせる（キーボードを閉じる）
  FocusManager.instance.primaryFocus?.unfocus();

  final result = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: context.pal.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final p = sheetContext.pal;

      Widget chip(String value, String label, {IconData? icon}) {
        final isSelected = value == (selected ?? '');

        return ChoiceChip(
          label: Text(label),
          avatar: icon == null
              ? null
              : Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
          selected: isSelected,
          showCheckmark: false,
          onSelected: (_) => Navigator.pop(sheetContext, value),
          labelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : p.text,
          ),
          selectedColor: AppColors.primary,
          backgroundColor: p.field,
          side: BorderSide(color: isSelected ? AppColors.primary : p.border),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 上のつまみ
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: p.text,
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: [
                      if (allowClear) chip('', '指定しない'),
                      for (final option in options)
                        chip(option, option, icon: iconOf?.call(option)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  // 閉じたあと、前の入力欄に戻って入力が続かないようにする
  // （下から出る画面は、閉じると前に入力していた欄へ戻ろうとするため）
  FocusManager.instance.primaryFocus?.unfocus();
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => FocusManager.instance.primaryFocus?.unfocus(),
  );

  return result;
}

// 入力欄と同じ見た目の「えらぶ欄」
class OptionField extends FormField<String> {
  OptionField({
    super.key,
    required String title,
    required List<String> options,
    required ValueChanged<String> onChanged,
    String? value,
    String hint = 'えらんでください',
    super.validator,
  }) : super(
         initialValue: value,
         builder: (state) {
           final context = state.context;
           final p = context.pal;
           final current = state.value ?? '';
           final hasError = state.hasError;

           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               InkWell(
                 borderRadius: BorderRadius.circular(12),
                 onTap: () async {
                   // 入力中の欄は、showOptionPicker の中でおわらせる
                   final picked = await showOptionPicker(
                     context,
                     title: title,
                     options: options,
                     selected: current,
                   );
                   if (picked == null || picked.isEmpty) return;
                   state.didChange(picked);
                   onChanged(picked);
                 },
                 child: Container(
                   padding: const EdgeInsets.symmetric(
                     horizontal: 14,
                     vertical: 13,
                   ),
                   decoration: BoxDecoration(
                     color: p.field,
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(
                       color: hasError ? AppColors.red : p.border,
                     ),
                   ),
                   child: Row(
                     children: [
                       Expanded(
                         child: Text(
                           current.isEmpty ? hint : current,
                           style: TextStyle(
                             fontSize: current.isEmpty ? 14 : 15,
                             color: current.isEmpty ? p.muted : p.text,
                           ),
                         ),
                       ),
                       Icon(
                         Icons.expand_more_rounded,
                         color: p.secondary,
                         size: 22,
                       ),
                     ],
                   ),
                 ),
               ),
               if (hasError)
                 Padding(
                   padding: const EdgeInsets.only(left: 12, top: 6),
                   child: Text(
                     state.errorText!,
                     style: const TextStyle(color: AppColors.red, fontSize: 12),
                   ),
                 ),
             ],
           );
         },
       );
}
