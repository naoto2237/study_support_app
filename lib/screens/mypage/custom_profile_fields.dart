// ======================================================================
// 【部品】プロフィールの自由項目（見出しも中身も自分で書く）
//
// 主なクラス: CustomProfileField / CustomFieldsEditor
// 使う場所: プロフィール編集（profile_edit_screen.dart）で書く
//           マイページ（mypage_profile_section.dart）で出す
// ・保存の形：users/{uid}.customFields = [{"label": "趣味", "value": "読書"}, ...]
// ・いくつでもではなく、最大 maxCount こまで（プロフィールが長くなりすぎないように）
// ・見出しか中身のどちらかが空の行は、保存しない
// ======================================================================

import 'package:flutter/material.dart';
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/theme/app_palette.dart';

// 1つ分（編集中は、入力欄の中身を持つ）
class CustomProfileField {
  static const int maxCount = 3;
  static const int maxLabelLength = 10;
  static const int maxValueLength = 30;

  final TextEditingController label;
  final TextEditingController value;

  CustomProfileField({String label = '', String value = ''})
    : label = TextEditingController(text: label),
      value = TextEditingController(text: value);

  void dispose() {
    label.dispose();
    value.dispose();
  }

  // 保存されている形から読む（形がちがうものは、とばす）
  static List<({String label, String value})> read(dynamic raw) {
    if (raw is! List) return const [];

    final result = <({String label, String value})>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final label = (item['label'] ?? '').toString().trim();
      final value = (item['value'] ?? '').toString().trim();
      if (label.isEmpty || value.isEmpty) continue;
      result.add((label: label, value: value));
      if (result.length >= maxCount) break;
    }
    return result;
  }

  // 保存する形にする（見出しか中身が空の行は、入れない）
  static List<Map<String, String>> toSave(List<CustomProfileField> fields) {
    return [
      for (final f in fields)
        if (f.label.text.trim().isNotEmpty && f.value.text.trim().isNotEmpty)
          {'label': f.label.text.trim(), 'value': f.value.text.trim()},
    ];
  }
}

// プロフィール編集の「自由項目」の欄（行を足す・消す）
class CustomFieldsEditor extends StatelessWidget {
  final List<CustomProfileField> fields;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const CustomFieldsEditor({
    super.key,
    required this.fields,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    InputDecoration decoration(String hint) {
      return InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: p.muted, fontSize: 14),
        // 文字数（0/10）は出さない（上限だけかける）
        counterText: '',
        isDense: true,
        filled: true,
        fillColor: p.field,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "自由項目（${fields.length}/${CustomProfileField.maxCount}）",
          style: TextStyle(fontSize: 13, color: p.secondary),
        ),
        const SizedBox(height: 4),
        Text(
          "見出しと中身を自由に書けます（例：趣味・読書）",
          style: TextStyle(fontSize: 11.5, color: p.muted),
        ),
        const SizedBox(height: 10),

        for (int i = 0; i < fields.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                // 見出し（短め）
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: fields[i].label,
                    maxLength: CustomProfileField.maxLabelLength,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(
                      fontSize: 14,
                      color: p.text,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: decoration("見出し"),
                  ),
                ),
                const SizedBox(width: 8),
                // 中身
                Expanded(
                  child: TextField(
                    controller: fields[i].value,
                    maxLength: CustomProfileField.maxValueLength,
                    textInputAction: TextInputAction.done,
                    style: TextStyle(fontSize: 14, color: p.text),
                    decoration: decoration("中身"),
                  ),
                ),
                // この行を消す
                IconButton(
                  tooltip: "消す",
                  onPressed: () => onRemove(i),
                  icon: Icon(
                    Icons.remove_circle_outline_rounded,
                    color: p.muted,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),

        // 行を足す（いっぱいのときは出さない）
        if (fields.length < CustomProfileField.maxCount)
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              "項目を足す",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
      ],
    );
  }
}
