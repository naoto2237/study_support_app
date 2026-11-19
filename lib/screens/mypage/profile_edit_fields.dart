// ======================================================================
// 【部品】プロフィール編集の、えらぶ欄（学年・職種／学習目標）
//
// 主なクラス: ProfileEditFields
// ・自由入力ではなく、一覧（profile_options.dart）からえらぶ（絞り込みに使うため）
// ・前に自由入力で入れた文字（一覧にないもの）は、「えらびなおしてください」と出す
// ・旧ファイル名: profile_edit_screen2.dart
// ======================================================================

import 'package:flutter/material.dart';
import 'package:study_support_app/data/profile_options.dart';
import 'package:study_support_app/theme/app_palette.dart';
import 'package:study_support_app/theme/option_picker.dart';

class ProfileEditFields extends StatelessWidget {
  final String? grade;
  final String? goal;
  final ValueChanged<String> onGradeChanged;
  final ValueChanged<String> onGoalChanged;

  const ProfileEditFields({
    super.key,
    required this.grade,
    required this.goal,
    required this.onGradeChanged,
    required this.onGoalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, thickness: 1, color: context.pal.border),

        const SizedBox(height: 18),

        Text(
          "プロフィール",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: context.pal.text,
          ),
        ),

        const SizedBox(height: 16),

        _SelectField(
          title: "学年・職種",
          options: ProfileOptions.grades,
          value: grade,
          onChanged: onGradeChanged,
        ),

        _SelectField(
          title: "学習目標",
          options: ProfileOptions.goals,
          value: goal,
          onChanged: onGoalChanged,
        ),
      ],
    );
  }
}

class _SelectField extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;

  const _SelectField({
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    // 前の自由入力（一覧にない文字）のときは、空として出し、えらびなおしてもらう
    final old = (value ?? '').trim();
    final isOld = old.isNotEmpty && !options.contains(old);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, color: p.secondary)),
          const SizedBox(height: 8),
          OptionField(
            // えらびなおしたら、新しい値で描き直す
            key: ValueKey('$title/$value'),
            title: title,
            options: options,
            value: isOld ? null : value,
            onChanged: onChanged,
          ),
          if (isOld)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 6),
              child: Text(
                "前に入れた「$old」は一覧にないので、えらびなおしてください",
                style: TextStyle(fontSize: 12, color: p.secondary),
              ),
            ),
        ],
      ),
    );
  }
}
