// ======================================================================
// 【画面】プロフィール分析
//
// 主なクラス: ProfileAnalysisScreen
// 開き方: マイページの「プロフィール分析」
// ・プロフィールを見た人の数（合計・今週・今月）
// ・応援された数（合計・今週・今月）
// ・友達の数
// ・記録のしくみは profile_activity.dart
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_support_app/screens/mypage/profile_activity.dart';
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/theme/app_palette.dart';

class ProfileAnalysisScreen extends StatelessWidget {
  final String userId;

  const ProfileAnalysisScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pal.page,

      appBar: AppBar(
        backgroundColor: context.pal.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.pal.text),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Transform.translate(
          offset: const Offset(-19, 0),
          child: Text(
            'プロフィール分析',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: context.pal.text,
            ),
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ------------------------------------------
          // プロフィールを見た人
          // ------------------------------------------
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: ProfileActivity.viewsOf(userId).snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];

              final now = DateTime.now();
              final weekStart = ProfileActivity.weekStartOf(now);
              final monthStart = ProfileActivity.monthStartOf(now);

              int week = 0;
              int month = 0;

              for (final doc in docs) {
                final time = doc.data()['lastViewedAt'];

                // 書きこんだ直後で、まだ時刻が入っていないときは「今」とみなす
                final viewedAt = time is Timestamp ? time.toDate() : now;

                if (!viewedAt.isBefore(weekStart)) week++;
                if (!viewedAt.isBefore(monthStart)) month++;
              }

              return _StatCard(
                icon: Icons.visibility_outlined,
                title: 'プロフィールを見た人',
                total: docs.length,
                week: week,
                month: month,
                unit: '人',
                note: '同じ人が何度見ても、1人と数えます',
                isLoading: !snapshot.hasData && !snapshot.hasError,
                hasError: snapshot.hasError,
              );
            },
          ),

          const SizedBox(height: 14),

          // ------------------------------------------
          // 応援された数
          // ------------------------------------------
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: ProfileActivity.cheersOf(userId).snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];

              final now = DateTime.now();
              final weekStart = ProfileActivity.dateIdOf(
                ProfileActivity.weekStartOf(now),
              );
              final monthStart = ProfileActivity.dateIdOf(
                ProfileActivity.monthStartOf(now),
              );

              int week = 0;
              int month = 0;

              // date は "2026-11-16" の形なので、文字のままくらべられる
              for (final doc in docs) {
                final date = (doc.data()['date'] ?? '').toString();

                if (date.compareTo(weekStart) >= 0) week++;
                if (date.compareTo(monthStart) >= 0) month++;
              }

              return _StatCard(
                icon: Icons.favorite_border_rounded,
                title: '応援された数',
                iconColor: AppColors.red,
                total: docs.length,
                week: week,
                month: month,
                unit: '回',
                note: '応援は、1人につき1日1回までです',
                isLoading: !snapshot.hasData && !snapshot.hasError,
                hasError: snapshot.hasError,
              );
            },
          ),

          const SizedBox(height: 14),

          // ------------------------------------------
          // 友達
          // ------------------------------------------
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('friends')
                .snapshots(),
            builder: (context, snapshot) {
              return _StatCard(
                icon: Icons.people_outline_rounded,
                title: '友達',
                iconColor: AppColors.green,
                total: snapshot.data?.docs.length ?? 0,
                unit: '人',
                isLoading: !snapshot.hasData && !snapshot.hasError,
                hasError: snapshot.hasError,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ======================================================
// 数を出すカード
// 上に見出し、まん中に合計、下に今週・今月（あるときだけ）
// ======================================================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int total;
  final int? week;
  final int? month;
  final String unit;
  final String? note;
  final bool isLoading;
  final bool hasError;

  // 見出しのアイコンの色（ふだんは青。数字の色は変えない）
  final Color iconColor;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.total,
    required this.unit,
    this.week,
    this.month,
    this.note,
    this.isLoading = false,
    this.hasError = false,
    this.iconColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 見出し
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: p.text,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (hasError)
            Text(
              '読み込めませんでした',
              style: TextStyle(fontSize: 14, color: p.secondary),
            )
          else ...[
            // 合計
            _Number(
              value: isLoading ? '-' : '$total',
              unit: unit,
              size: 30,
              color: p.text,
              unitColor: p.secondary,
            ),

            // 今週・今月
            if (week != null && month != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: p.field,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _PeriodItem(
                        label: '今週',
                        color: AppColors.primary,
                        value: isLoading ? '-' : '$week',
                        unit: unit,
                      ),
                    ),
                    Container(width: 1, height: 28, color: p.divider),
                    Expanded(
                      child: _PeriodItem(
                        label: '今月',
                        color: AppColors.primary,
                        value: isLoading ? '-' : '$month',
                        unit: unit,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          if (note != null) ...[
            const SizedBox(height: 10),
            Text(note!, style: TextStyle(fontSize: 12, color: p.muted)),
          ],
        ],
      ),
    );
  }
}

class _PeriodItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _PeriodItem({
    required this.label,
    required this.value,
    required this.unit,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12.5, color: p.secondary)),
        const SizedBox(height: 2),
        _Number(
          value: value,
          unit: unit,
          size: 19,
          color: color,
          unitColor: p.secondary,
        ),
      ],
    );
  }
}

// 数字と単位（「12人」）
class _Number extends StatelessWidget {
  final String value;
  final String unit;
  final double size;
  final Color color;
  final Color unitColor;

  const _Number({
    required this.value,
    required this.unit,
    required this.size,
    required this.color,
    required this.unitColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: size,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          unit,
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
            color: unitColor,
          ),
        ),
      ],
    );
  }
}
