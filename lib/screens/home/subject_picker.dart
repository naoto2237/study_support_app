// ======================================================================
// 【部品】タイマーの近くに置く「教科をえらぶ」ボタン
//
// 主なクラス: SubjectPicker
// 使う場所: home_screen.dart（タイマーの上）
// ・押すと教科の一覧が出て、1つえらぶ（current_subject.dart に覚える）
// ・タイマーが動いている間は押せない（鍵のマークを出す）
// ======================================================================

import 'package:flutter/material.dart';
import 'package:study_support_app/data/profile_options.dart';
import 'package:study_support_app/services/current_subject.dart';
import 'package:study_support_app/services/study_timer_remote.dart';
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/theme/app_palette.dart';
import 'package:study_support_app/theme/option_picker.dart';

class SubjectPicker extends StatelessWidget {
  const SubjectPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return ValueListenableBuilder<bool>(
      valueListenable: StudyTimerRemote.isRunning,
      builder: (context, running, _) {
        return ValueListenableBuilder<String?>(
          valueListenable: CurrentSubject.value,
          builder: (context, subject, _) {
            final hasSubject = subject != null;

            return Material(
              color: hasSubject ? AppColors.primarySoft : p.card,
              shape: StadiumBorder(
                side: BorderSide(
                  color: hasSubject ? AppColors.primary : p.border,
                ),
              ),
              child: InkWell(
                customBorder: const StadiumBorder(),
                // 計測中は変えられない
                onTap: running
                    ? null
                    : () async {
                        final picked = await showOptionPicker(
                          context,
                          title: '勉強する教科',
                          options: ProfileOptions.subjects,
                          selected: subject,
                          allowClear: true,
                          iconOf: ProfileOptions.subjectIcon,
                        );
                        if (picked == null) return;
                        await CurrentSubject.set(picked);
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasSubject
                            ? ProfileOptions.subjectIcon(subject)
                            : Icons.menu_book_outlined,
                        size: 17,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasSubject ? subject : '教科をえらぶ',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          // うすい青の上は、ダークモードでも濃い青の文字
                          color: hasSubject ? AppColors.primary : p.secondary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        running
                            ? Icons.lock_outline_rounded
                            : Icons.expand_more_rounded,
                        size: running ? 15 : 19,
                        color: hasSubject ? AppColors.primary : p.secondary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
