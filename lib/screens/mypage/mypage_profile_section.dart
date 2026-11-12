// ======================================================================
// 【部品】マイページの下半分（ボタン・統計・プロフィール項目）
//
// 主なクラス: MypageProfileSection/ ProfileStatsSection
// ・自分のページ：プロフィール分析、プロフィール編集
// ・他人のページ：友達申請、メッセージ（メッセージの移動先はまだ未実装）
// ・統計（友達・応援・目標達成）。「友達」から友達一覧へ
// ・一言コメント、学年・学習目標・自由項目
// ・最近の学習記録（recent_records_section.dart）
// ・見た目はほかの画面とそろえて、白いカード（枠つき・角丸16）を並べる
// ・旧ファイル名: mypage_screen2.dart
// ======================================================================

import 'package:flutter/material.dart';
import 'package:study_support_app/screens/mypage/profile_edit_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_support_app/screens/record/my_record/recent_records_section.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_support_app/screens/mypage/friend_request_dialog.dart';
import 'package:study_support_app/screens/mypage/all_friends_screen.dart';
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/theme/empty_message.dart';

// マイページで使う色（明るい画面・暗い画面）
class _MypageColors {
  final Color card;
  final Color border;
  final Color divider;
  final Color text;
  final Color secondary;
  final Color muted;

  const _MypageColors({
    required this.card,
    required this.border,
    required this.divider,
    required this.text,
    required this.secondary,
    required this.muted,
  });

  factory _MypageColors.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return isDark
        ? const _MypageColors(
            card: Color(0xFF1E1E1E),
            border: Colors.white12,
            divider: Colors.white12,
            text: Colors.white,
            secondary: Colors.white70,
            muted: Colors.white38,
          )
        : const _MypageColors(
            card: Colors.white,
            border: AppColors.border,
            divider: AppColors.divider,
            text: Colors.black87,
            secondary: Colors.black54,
            muted: Colors.black38,
          );
  }
}

class MypageProfileSection extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMyPage;
  final String userId;
  final bool isPublic; // 公開・非公開の状態

  const MypageProfileSection({
    super.key,
    required this.data,
    required this.isMyPage,
    required this.userId,
    required this.isPublic,
  });

  static const Color primaryBlue = AppColors.primary;

  void _openEditScreen(BuildContext context) {
    if (!isMyPage) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileEditScreen(data: data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _MypageColors.of(context);

    final String grade = data["grade"] ?? "未設定";
    final String goal = data["goal"] ?? "未設定";
    final String location = "未設定";
    final String studyStyle = "未設定";

    final String comment = (data["comment"] ?? "").toString().trim();

    // 他人のページかつ非公開の場合かどうか
    final bool isPrivateOther = !isMyPage && !isPublic;

    // 自分のページだけ、項目を押すと編集画面へ
    final VoidCallback? onEdit = isMyPage
        ? () => _openEditScreen(context)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------
          // プロフィールアクション（前のデザインのまま：灰色の丸いボタン）
          // ------------------------------------------
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: isMyPage
                      ? Icons.bar_chart_rounded
                      : Icons.person_add_alt_1,
                  text: isMyPage ? "プロフィール分析" : "友達申請",
                  onTap: () {
                    if (isMyPage) {
                      // プロフィール分析
                    } else {
                      FriendRequestDialog.show(
                        context,
                        userId: userId,
                        data: data,
                      );
                    }
                  },
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: _ActionButton(
                  icon: isMyPage ? Icons.edit : Icons.chat_outlined,
                  text: isMyPage ? "プロフィール編集" : "メッセージ",
                  onTap: () {
                    if (isMyPage) {
                      _openEditScreen(context);
                    } else {
                      // チャット画面へ移動
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12.5),

          // ------------------------------------------
          // プロフィール統計（友達・応援・目標達成。前のデザインのまま）
          // ------------------------------------------
          ProfileStatsSection(userId: userId),

          const SizedBox(height: 15),

          // ------------------------------------------
          // 一言コメント
          // ------------------------------------------
          if (comment.isNotEmpty) ...[
            Center(
              child: Text(
                comment,
                style: TextStyle(color: colors.text, fontSize: 14, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 18),
          ],

          const SizedBox(height: 7),

          // ------------------------------------------
          // プロフィール項目
          // ------------------------------------------
          _SectionTitle(title: "プロフィール", color: colors.text),

          const SizedBox(height: 8),

          _Card(
            colors: colors,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _ProfileRow(
                  icon: Icons.school_outlined,
                  title: "学年・職種",
                  value: grade,
                  colors: colors,
                  onTap: onEdit,
                ),
                _ProfileRow(
                  icon: Icons.flag_outlined,
                  title: "学習目標",
                  value: goal,
                  colors: colors,
                  onTap: onEdit,
                ),
                _ProfileRow(
                  icon: Icons.notes_rounded,
                  title: "自由項目①",
                  value: location,
                  colors: colors,
                  onTap: onEdit,
                ),
                _ProfileRow(
                  icon: Icons.notes_rounded,
                  title: "自由項目②",
                  value: studyStyle,
                  colors: colors,
                  onTap: onEdit,
                  showDivider: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // ------------------------------------------
          // 学習記録（非公開の場合は、記録の代わりに案内を出す）
          // ------------------------------------------
          if (isPrivateOther)
            _Card(
              colors: colors,
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: const SizedBox(
                width: double.infinity,
                child: EmptyMessage(
                  icon: Icons.lock_outline_rounded,
                  text: "このユーザーは学習記録を非公開にしています",
                ),
              ),
            )
          else
            RecentRecordsSection(
              cardColor: colors.card,
              textColor: colors.text,
              secondaryColor: colors.secondary,
              userId: userId,
            ),

          SizedBox(height: isMyPage ? 140 : 200),
        ],
      ),
    );
  }
}

// ======================================================
// 見出し
// ======================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

// ======================================================
// カード（ほかの画面と同じ：枠つき・角丸16）
// ======================================================

class _Card extends StatelessWidget {
  final _MypageColors colors;
  final EdgeInsetsGeometry padding;
  final Widget child;

  const _Card({
    required this.colors,
    required this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: child,
    );
  }
}

// ======================================================
// アクションボタン（前のデザイン：灰色の丸いボタン）
// ======================================================

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 35,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          // 暗い画面では、灰色の代わりにうすい白にする
          backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
          foregroundColor: isDark ? Colors.white : Colors.black87,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),

            const SizedBox(width: 7),

            Text(
              text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// プロフィール統計（友達・応援・目標達成。前のデザイン）
// ======================================================

class ProfileStatsSection extends StatelessWidget {
  final String userId;

  const ProfileStatsSection({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dividerColor = isDark ? Colors.white24 : Colors.grey.shade300;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('friends')
          .snapshots(),

      builder: (context, friendSnapshot) {
        final friendCount = friendSnapshot.data?.docs.length ?? 0;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('studyRecords')
              .snapshots(),

          builder: (context, recordSnapshot) {
            int achievementDays = 0;

            if (recordSnapshot.hasData) {
              achievementDays = recordSnapshot.data!.docs.where((doc) {
                final data = doc.data();

                return data['goalAchieved'] == true;
              }).length;
            }

            return Padding(
              // 外側の余白（17）と合わせて、前と同じ 34 にする
              padding: const EdgeInsets.symmetric(horizontal: 17),

              child: Row(
                children: [
                  // ======================================
                  // 友達
                  // ======================================
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllFriendsScreen(userId: userId),
                          ),
                        );
                      },

                      child: _ProfileStatItem(
                        count: friendCount.toString(),
                        label: "友達",
                      ),
                    ),
                  ),

                  Container(width: 1, height: 16, color: dividerColor),

                  // ======================================
                  // 応援
                  // ======================================
                  const Expanded(
                    child: _ProfileStatItem(count: "0", label: "応援"),
                  ),

                  Container(width: 1, height: 16, color: dividerColor),

                  // ======================================
                  // 目標達成
                  // ======================================
                  Expanded(
                    child: _ProfileStatItem(
                      count: achievementDays.toString(),
                      label: "目標達成",
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ProfileStatItem extends StatelessWidget {
  final String count;
  final String label;

  const _ProfileStatItem({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.roboto(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(height: 1),

        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ======================================================
// プロフィール項目（左にアイコンと項目名、右に値）
// ======================================================
class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final _MypageColors colors;
  final VoidCallback? onTap;
  final bool showDivider;

  const _ProfileRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.colors,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final isUnset = value.trim().isEmpty || value == "未設定";

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: showDivider
            ? BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.divider)),
              )
            : null,
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),

            const SizedBox(width: 10),

            Text(
              title,
              style: TextStyle(fontSize: 14, color: colors.secondary),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                isUnset ? "未設定" : value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  color: isUnset ? colors.muted : colors.text,
                  fontWeight: isUnset ? FontWeight.normal : FontWeight.w600,
                ),
              ),
            ),

            // 押して編集できるとき（自分のページ）だけ「>」を出す
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: colors.muted, size: 22),
            ],
          ],
        ),
      ),
    );
  }
}
