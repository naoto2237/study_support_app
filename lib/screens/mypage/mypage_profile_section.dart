// ======================================================================
// 【部品】マイページの下半分（ボタン・統計・プロフィール項目）
//
// 主なクラス: MypageProfileSection/ ProfileStatsSection
// ・自分のページ：プロフィール分析（profile_analysis_screen.dart）、プロフィール編集
// ・他人のページ：友達申請（友達・申請中・承認するに切りかわる）、
//   メッセージ（友達か、相手が友達以外からも受け取る設定ならチャットへ）、応援
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
import 'package:study_support_app/screens/mypage/profile_activity.dart';
import 'package:study_support_app/screens/mypage/profile_analysis_screen.dart';
import 'package:study_support_app/screens/chat/chat_permission.dart';
import 'package:study_support_app/screens/chat/chat_room_screen.dart';
import 'package:study_support_app/screens/notification/friend_request_notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/theme/app_palette.dart';
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
                child: isMyPage
                    ? _ActionButton(
                        icon: Icons.bar_chart_rounded,
                        text: "プロフィール分析",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProfileAnalysisScreen(userId: userId),
                            ),
                          );
                        },
                      )
                    // 他の人のページ：相手との関係で「友達申請・申請中・承認する・友達」
                    : _FriendButton(userId: userId, data: data),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: isMyPage
                    ? _ActionButton(
                        icon: Icons.edit,
                        text: "プロフィール編集",
                        onTap: () => _openEditScreen(context),
                      )
                    // 他の人のページ：送れるならチャットへ。送れなければ、うすく出す
                    : _MessageButton(userId: userId, data: data),
              ),

              // 他の人のページだけ「応援」（1人1日1回まで）
              if (!isMyPage) ...[
                const SizedBox(width: 14),
                Expanded(child: _CheerButton(userId: userId)),
              ],
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
                  iconColor: AppColors.red,
                  title: "学習目標",
                  value: goal,
                  colors: colors,
                  onTap: onEdit,
                ),
                _ProfileRow(
                  icon: Icons.notes_rounded,
                  iconColor: AppColors.green,
                  title: "自由項目①",
                  value: location,
                  colors: colors,
                  onTap: onEdit,
                ),
                _ProfileRow(
                  icon: Icons.notes_rounded,
                  iconColor: AppColors.orange,
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

  // 青くする（「応援済み」など）
  final bool highlighted;

  // 文字とアイコンをうすくする（今は使えないボタン。押すと理由を出す）
  final bool dimmed;

  // highlighted のとき、青ではなく赤にする（「応援済み」）
  final bool red;

  const _ActionButton({
    required this.icon,
    required this.text,
    required this.onTap,
    this.highlighted = false,
    this.dimmed = false,
    this.red = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 暗い画面では、灰色の代わりにうすい白にする
    final background = highlighted
        ? (red
              ? AppColors.red.withValues(alpha: isDark ? 0.2 : 0.1)
              : context.pal.primarySoft)
        : (isDark ? Colors.white12 : Colors.grey.shade200);
    final foreground = highlighted
        ? (red ? AppColors.red : AppColors.primary)
        : dimmed
        ? context.pal.muted
        : (isDark ? Colors.white : Colors.black87);

    return SizedBox(
      height: 35,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
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
// 友達ボタン（他の人のページ）
// ・友達になっている       → 「友達」（青。押すと友達をやめられる）
// ・相手から申請が届いている → 「承認する」（押すと確認してから友達になる）
// ・自分が申請を送っている  → 「申請中」（押すと申請を取り消せる）
// ・どれでもない           → 「友達申請」（申請を送る確認を出す）
// ======================================================

class _FriendButton extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> data;

  const _FriendButton({required this.userId, required this.data});

  @override
  State<_FriendButton> createState() => _FriendButtonState();
}

class _FriendButtonState extends State<_FriendButton> {
  final String? _me = FirebaseAuth.instance.currentUser?.uid;

  // Stream は1回だけ作る（親が作りなおされても、読みなおさない）
  late final Stream<bool> _isFriend;
  late final Stream<bool> _sentByMe;
  late final Stream<bool> _receivedFromThem;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  @override
  void initState() {
    super.initState();

    final me = _me;

    if (me == null) {
      _isFriend = Stream.value(false);
      _sentByMe = Stream.value(false);
      _receivedFromThem = Stream.value(false);
      return;
    }

    // 読めないとき（ルールで止められたときなど）は「なし」として扱う
    Stream<bool> exists(DocumentReference<Map<String, dynamic>> doc) {
      return doc.snapshots().map((snap) => snap.exists).handleError((_) {});
    }

    _isFriend = exists(_userDoc(me).collection('friends').doc(widget.userId));
    _sentByMe = exists(
      _userDoc(widget.userId).collection('friend_requests').doc(me),
    );
    _receivedFromThem = exists(
      _userDoc(me).collection('friend_requests').doc(widget.userId),
    );
  }

  String get _name {
    return (widget.data['username'] ?? widget.data['name'] ?? 'このユーザー')
        .toString();
  }

  // 相手からの申請を承認する（できたらボタンが「友達」に変わる）
  Future<void> _accept() {
    return FriendActionDialog.show(
      context,
      data: widget.data,
      title: '友達申請',
      message: '友達申請が届いています。\n承認しますか？',
      okText: '承認する',
      errorText: '承認できませんでした',
      onOk: () => FriendRequestNotification.accept(
        senderId: widget.userId,
        requestId: widget.userId,
        fallbackName: _name,
      ),
    );
  }

  // 友達をやめる（できたらボタンが「友達申請」に戻る）
  // 自分の friends と相手の friends の両方から消す
  Future<void> _unfriend() async {
    final me = _me;

    if (me == null) return;

    await FriendActionDialog.show(
      context,
      data: widget.data,
      title: '友達をやめる',
      message: '友達をやめますか？\nおたがいの友達一覧から消えます',
      okText: 'やめる',
      danger: true,
      errorText: '友達をやめられませんでした',
      onOk: () async {
        final batch = FirebaseFirestore.instance.batch();

        batch.delete(_userDoc(me).collection('friends').doc(widget.userId));
        batch.delete(_userDoc(widget.userId).collection('friends').doc(me));

        await batch.commit();
      },
    );
  }

  // 自分が送った申請を取り消す（できたらボタンが「友達申請」に戻る）
  Future<void> _cancel() async {
    final me = _me;

    if (me == null) return;

    await FriendActionDialog.show(
      context,
      data: widget.data,
      title: '申請の取り消し',
      message: '友達申請を取り消しますか？',
      okText: '取り消す',
      danger: true,
      errorText: '取り消せませんでした',
      onOk: () => _userDoc(
        widget.userId,
      ).collection('friend_requests').doc(me).delete(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _isFriend,
      builder: (context, friendSnap) {
        return StreamBuilder<bool>(
          stream: _receivedFromThem,
          builder: (context, receivedSnap) {
            return StreamBuilder<bool>(
              stream: _sentByMe,
              builder: (context, sentSnap) {
                final isFriend = friendSnap.data ?? false;
                final received = receivedSnap.data ?? false;
                final sent = sentSnap.data ?? false;

                if (isFriend) {
                  return _ActionButton(
                    icon: Icons.people_rounded,
                    text: "友達",
                    highlighted: true,
                    onTap: _unfriend,
                  );
                }

                if (received) {
                  return _ActionButton(
                    icon: Icons.how_to_reg_rounded,
                    text: "承認する",
                    highlighted: true,
                    onTap: _accept,
                  );
                }

                if (sent) {
                  return _ActionButton(
                    icon: Icons.schedule_rounded,
                    text: "申請中",
                    onTap: _cancel,
                  );
                }

                return _ActionButton(
                  icon: Icons.person_add_alt_1,
                  text: "友達申請",
                  onTap: () {
                    FriendRequestDialog.show(
                      context,
                      userId: widget.userId,
                      data: widget.data,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

// ======================================================
// メッセージボタン（他の人のページ）
// ・送れるとき（友達、または相手が友達以外からも受け取る設定）は、
//   押すと1対1のチャット（chat_room_screen.dart）を開く
// ・送れないときは、文字をうすくして鍵のマークを出す
//   押すと「メッセージはまだ送れません」と理由を出す
// ・送れるかどうかは chat_permission.dart の CanMessageBuilder で調べる
// ======================================================

class _MessageButton extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> data;

  const _MessageButton({required this.userId, required this.data});

  String get _name {
    return (data['name'] ?? data['username'] ?? 'ユーザー').toString();
  }

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(userName: _name, userId: userId),
      ),
    );
  }

  // 送れないときの説明
  void _showCannotMessage(BuildContext context) {
    final p = context.pal;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: p.card,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: p.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'メッセージはまだ送れません',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_nameさんは、友達からのメッセージだけを\n受け取る設定にしています。\n友達になると、メッセージを送れます',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.55,
                    color: p.secondary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '閉じる',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CanMessageBuilder(
      userId: userId,
      builder: (context, canMessage, loading) {
        return _ActionButton(
          icon: canMessage || loading
              ? Icons.chat_outlined
              : Icons.lock_outline_rounded,
          text: "メッセージ",
          dimmed: !canMessage && !loading,
          onTap: loading
              ? () {}
              : canMessage
              ? () => _openChat(context)
              : () => _showCannotMessage(context),
        );
      },
    );
  }
}

// ======================================================
// 応援ボタン（他の人のページ）
// 今日まだ応援していなければ「応援する」、応援したら「応援済み」（青）
// ======================================================

class _CheerButton extends StatefulWidget {
  final String userId;

  const _CheerButton({required this.userId});

  @override
  State<_CheerButton> createState() => _CheerButtonState();
}

class _CheerButtonState extends State<_CheerButton> {
  // Stream は1回だけ作る（親が作りなおされても、読みなおさない）
  late final Stream<bool> _cheeredToday = ProfileActivity.cheeredTodayStream(
    widget.userId,
  );

  bool _sending = false;

  Future<void> _cheer() async {
    if (_sending) return;

    setState(() => _sending = true);

    try {
      await ProfileActivity.cheer(widget.userId);
    } catch (e) {
      // 失敗したときは「応援する」のまま（もう一度押せる）
      debugPrint('応援できませんでした: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _cheeredToday,
      builder: (context, snapshot) {
        final cheered = snapshot.data ?? false;

        return _ActionButton(
          icon: cheered
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          text: cheered ? "応援済み" : "応援する",
          highlighted: cheered,
          red: true,
          onTap: cheered ? () {} : _cheer,
        );
      },
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
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: ProfileActivity.cheersOf(userId).snapshots(),
                      builder: (context, cheerSnapshot) {
                        return _ProfileStatItem(
                          count: (cheerSnapshot.data?.docs.length ?? 0)
                              .toString(),
                          label: "応援",
                        );
                      },
                    ),
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

  // 左のアイコンの色（ふだんは青）
  final Color iconColor;

  const _ProfileRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.colors,
    this.onTap,
    this.showDivider = true,
    this.iconColor = AppColors.primary,
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
            Icon(icon, size: 20, color: iconColor),

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
