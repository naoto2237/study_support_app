// ======================================================================
// 【画面】ルームの中
//
// 主なクラス: RoomSpaceScreen / _MemberSummaryUser（メンバー1人分の表示）
//            _ActivityRow（アクティビティ1行分）
// 開き方: 「作成」タブ・「検索」タブ・ルーム作成後
// ・学習タイマー：ホームのタイマーと同じもの（services/study_timer_remote.dart）
//   ルームで始めても止めても、ホームと同じように学習記録に保存される
// ・今日の目標・今日の学習時間・目標まで残り（ホームと同じ値。アイコンの色もホームとそろえる）
// ・タイマーの下で、今から勉強する教科をえらべる（ホームと同じ subject_picker.dart）
// ・メンバー／チャット／共有ノートを開く（共通の画面は room_feature_screen.dart）
// ・メンバーの一覧、アクティビティ（参加・メッセージ。画面の下の残りに収め、カードの中でスクロール）
// ・右上のメニュー：ルームの情報、ルームから退出
// ・左上の矢印（スマホの戻る操作も）を押すと、ルームから退出するか確かめる
// ・旧ファイル名: room_space.dart
// ======================================================================

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_support_app/main.dart'
    show dailyTargetHours, todayStudySeconds;
import 'package:study_support_app/screens/link/room/space/room_chat_screen.dart';
import 'package:study_support_app/screens/link/room/space/room_feature_screen.dart';
import 'package:study_support_app/screens/link/room/space/room_member_screen.dart';
import 'package:study_support_app/screens/link/room/space/room_share_note_screen.dart';
import 'package:study_support_app/screens/record/comparison/compare_user_picker.dart'
    show PartnerAvatar;
import 'package:study_support_app/services/study_timer_remote.dart';
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/screens/home/subject_picker.dart';
import 'package:study_support_app/theme/app_palette.dart';

class RoomSpaceScreen extends StatefulWidget {
  final String roomTitle;
  final String roomId;
  final String backgroundImage;

  const RoomSpaceScreen({
    super.key,
    required this.roomTitle,
    required this.roomId,
    this.backgroundImage = 'assets/images/haikei5.png',
  });

  @override
  State<RoomSpaceScreen> createState() => _RoomSpaceScreenState();
}

class _RoomSpaceScreenState extends State<RoomSpaceScreen> {
  // 中身の幅のいちばん大きい値（パソコンなど広い画面でも、これより広げない）
  static const double _maxWidth = 600;

  // タイマーの丸のいちばん大きい大きさ
  static const double _maxTimerSize = 220;

  // 描き直すたびに作り直さないよう、最初に1回だけ作る
  late final DocumentReference<Map<String, dynamic>> _roomRef;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _roomStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _memberStream;
  // 最近のメッセージ（アクティビティに出す）
  // 画面を開いたときに1回だけ受け取りはじめ、届いた中身をここに取っておく。
  // （描き直しで受け取り口を作り直すと、最初の分を受け取りそこねて
  //   メッセージが出ないことがあったため）
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _messageSubscription;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _recentMessages = [];

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId);

    _roomStream = _roomRef.snapshots();

    _memberStream = _roomRef
        .collection('members')
        .orderBy('joinedAt')
        .snapshots();

    _messageSubscription = _roomRef
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .listen(
          (snapshot) {
            if (!mounted) return;
            setState(() => _recentMessages = snapshot.docs);
          },
          onError: (Object e) {
            debugPrint('最近のメッセージを読み込めませんでした: $e');
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _roomStream,
      builder: (context, roomSnapshot) {
        final roomData = roomSnapshot.data?.data();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _memberStream,
          builder: (context, memberSnapshot) {
            final memberDocs = memberSnapshot.data?.docs ?? [];

            // 左上の矢印（とスマホの戻る操作）を押したら、退出するか確かめる
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) _showExitDialog();
              },
              child: Scaffold(
                backgroundColor: p.page,
                appBar: _buildAppBar(roomData, memberDocs.length),
                // 「アクティビティ」は、画面の下の残りの高さに収める
                // （できごとが増えても画面が下に伸びず、カードの中でスクロールする）
                body: LayoutBuilder(
                  builder: (context, constraints) {
                    final topParts = [
                      _buildStudyCard(),

                      const SizedBox(height: 12),

                      _buildRoomFeatureButtons(),

                      const SizedBox(height: 12),

                      _buildMembersCard(
                        memberDocs,
                        ownerId: (roomData?['ownerId'] ?? '').toString(),
                        isLoading:
                            memberSnapshot.connectionState ==
                            ConnectionState.waiting,
                      ),

                      const SizedBox(height: 12),
                    ];

                    const padding = EdgeInsets.fromLTRB(17, 14, 17, 16);

                    // 広い画面（パソコンなど）でも、スマホと同じくらいの幅でまん中に出す
                    // （広がりすぎると、タイマーの丸が大きくなって縦に入りきらない）
                    final width = constraints.maxWidth.clamp(0.0, _maxWidth);

                    // 上の部分（タイマー〜メンバー）のおおよその高さ。
                    // タイマーの丸は、カードの幅で大きさが決まる（いちばん大きくて _maxTimerSize）
                    final timerSize = ((width - 34 - 36) * 11 / 20).clamp(
                      0.0,
                      _maxTimerSize,
                    );
                    // （教科をえらぶボタンの分も入れる）
                    final topHeight = timerSize + 384;

                    // アクティビティが少なくとも 160 の高さで入るか
                    final fits =
                        constraints.maxHeight >=
                        topHeight + padding.vertical + 160;

                    Widget content;

                    if (fits) {
                      // ふつうの高さの画面：残りの高さいっぱいに広げる
                      content = Padding(
                        padding: padding,
                        child: Column(
                          children: [
                            ...topParts,
                            Expanded(child: _buildActivityCard(memberDocs)),
                          ],
                        ),
                      );
                    } else {
                      // 低い画面（横向き・パソコンの低いウインドウなど）：
                      // 画面ごとスクロールし、カードは決まった高さ
                      content = SingleChildScrollView(
                        padding: padding,
                        child: Column(
                          children: [
                            ...topParts,
                            SizedBox(
                              height: 260,
                              child: _buildActivityCard(memberDocs),
                            ),
                          ],
                        ),
                      );
                    }

                    return Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(width: width, child: content),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // 上の帯：ルーム名と「公開・〇人参加中」、右上のメニュー
  // ============================================================

  PreferredSizeWidget _buildAppBar(
    Map<String, dynamic>? roomData,
    int memberCount,
  ) {
    final p = context.pal;

    final title = (roomData?['title'] ?? widget.roomTitle).toString();
    final isPublic = roomData?['isPublic'] ?? true;

    return AppBar(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      iconTheme: IconThemeData(color: p.text),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: p.divider),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: p.text,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 1),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPublic ? Icons.public : Icons.lock_outline_rounded,
                size: 13,
                color: p.secondary,
              ),
              const SizedBox(width: 3),
              Text(
                "${isPublic ? "公開" : "非公開"}・$memberCount人参加中",
                style: TextStyle(color: p.secondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert, color: p.text),
          onPressed: () => _showMenu(roomData, memberCount),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ============================================================
  // 学習タイマーと今日の様子
  // ============================================================

  Widget _buildStudyCard() {
    final p = context.pal;

    return _card(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: ValueListenableBuilder<double>(
        valueListenable: dailyTargetHours,
        builder: (context, targetHours, _) {
          return ValueListenableBuilder<int>(
            valueListenable: todayStudySeconds,
            builder: (context, studySeconds, _) {
              final goalSeconds = (targetHours * 3600).round();
              final remaining = goalSeconds - studySeconds;
              final progress = goalSeconds > 0
                  ? (studySeconds / goalSeconds).clamp(0.0, 1.0)
                  : 0.0;

              return Column(
                children: [
                  Row(
                    children: [
                      // 左：まるいバー（今日の目標までの進み具合）とタイマー
                      Expanded(flex: 11, child: _buildTimer(progress)),

                      const SizedBox(width: 8),

                      // 右：今日の目標・残り・学習時間
                      Expanded(
                        flex: 9,
                        child: Column(
                          children: [
                            // アイコンと色はホーム画面とそろえる
                            // （旗は赤、時計は青、砂時計は緑）
                            _infoRow(
                              icon: Icons.flag_rounded,
                              iconColor: AppColors.red,
                              title: "今日の目標",
                              value: goalSeconds > 0
                                  ? _durationLabel(goalSeconds)
                                  : "未設定",
                            ),
                            Divider(height: 22, color: p.divider),
                            _infoRow(
                              icon: Icons.timer_outlined,
                              iconColor: AppColors.primary,
                              title: "今日の学習時間",
                              value: _studyTimeLabel(studySeconds),
                            ),
                            Divider(height: 22, color: p.divider),
                            _infoRow(
                              icon: Icons.hourglass_empty_rounded,
                              iconColor: AppColors.green,
                              title: "目標まで残り",
                              // 目標を決めていないときは「--」（ホームと同じ）
                              value: goalSeconds <= 0
                                  ? "--"
                                  : (remaining <= 0
                                        ? "達成済み！"
                                        : _durationLabel(remaining)),
                              // 達成したときは、ホームと同じ青い文字
                              valueColor: goalSeconds > 0 && remaining <= 0
                                  ? AppColors.primary
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 左：今から勉強する教科（ホームと同じ。えらぶとホームも変わる）
                  // 右：ひとこと
                  Row(
                    children: [
                      const SubjectPicker(),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "ホームのタイマーと同じです。\n止めると学習記録に残ります",
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: p.muted,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTimer(double progress) {
    // 丸は _maxTimerSize より大きくしない（広い画面で大きくなりすぎないように）
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxTimerSize),
        child: _buildTimerCircle(progress),
      ),
    );
  }

  Widget _buildTimerCircle(double progress) {
    final p = context.pal;

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 7,
              strokeCap: StrokeCap.round,
              backgroundColor: p.isDark
                  ? Colors.white12
                  : AppColors.primaryTrack,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),

          ValueListenableBuilder<bool>(
            valueListenable: StudyTimerRemote.isRunning,
            builder: (context, isRunning, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: StudyTimerRemote.isCountdown,
                    builder: (context, isCountdown, _) => Text(
                      isCountdown ? "残りの時間" : "学習タイマー",
                      style: TextStyle(
                        color: p.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 2),

                  // 時間（ホームのタイマーと同じ表示）
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ValueListenableBuilder<String>(
                      valueListenable: StudyTimerRemote.timeText,
                      builder: (context, time, _) => Text(
                        time,
                        style: GoogleFonts.roboto(
                          color: AppColors.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _roundButton(
                        icon: isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        filled: true,
                        onTap: isRunning
                            ? StudyTimerRemote.stop
                            : StudyTimerRemote.start,
                      ),
                      const SizedBox(width: 16),
                      _roundButton(
                        icon: Icons.refresh_rounded,
                        filled: false,
                        onTap: StudyTimerRemote.reset,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // 開始・停止（青い丸）とリセット（白い丸）
  Widget _roundButton({
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    final p = context.pal;

    return ValueListenableBuilder<bool>(
      // ホームのタイマーがまだ準備できていないときは押せない
      valueListenable: StudyTimerRemote.isAttached,
      builder: (context, isAttached, _) {
        return Material(
          color: filled ? AppColors.primary : p.card,
          shape: CircleBorder(
            side: filled ? BorderSide.none : BorderSide(color: p.border),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: isAttached ? onTap : null,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                icon,
                size: 26,
                color: filled ? Colors.white : AppColors.primary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    final p = context.pal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: p.secondary, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.only(left: 21),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor ?? p.text,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 「2時間15分」「45分」のような書き方（1分未満は「0分」）
  String _durationLabel(int seconds) {
    final h = seconds ~/ 3600;
    final m = seconds ~/ 60 % 60;

    if (h == 0) return "$m分";
    if (m == 0) return "$h時間";
    return "$h時間$m分";
  }

  // 今日の学習時間の書き方（ホームとそろえる）
  // 1時間未満は秒まで「30分45秒」、1時間以上は秒を出さない「2時間30分」
  String _studyTimeLabel(int seconds) {
    final h = seconds ~/ 3600;
    final m = seconds ~/ 60 % 60;
    final s = seconds % 60;

    if (h == 0) return "$m分$s秒";
    return "$h時間$m分";
  }

  // ============================================================
  // メンバー・チャット・共有ノートの3つのボタン
  // ============================================================

  Widget _buildRoomFeatureButtons() {
    return Row(
      children: [
        Expanded(
          child: _featureButton(
            icon: Icons.groups_rounded,
            title: "メンバー",
            // メンバーは青、チャットはオレンジ、共有ノートは緑（アイコンだけに使う色）
            color: AppColors.primary,
            onTap: _openMembers,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _featureButton(
            // ルームのチャットは大勢で話すので、吹き出しが2つのアイコン
            icon: Icons.forum_rounded,
            title: "チャット",
            color: AppColors.orange,
            onTap: _openChat,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _featureButton(
            icon: Icons.description_rounded,
            title: "共有ノート",
            color: AppColors.green,
            onTap: () => _openFeatureScreen(
              title: "共有ノート",
              icon: Icons.description_rounded,
              child: RoomShareNoteScreen(roomId: widget.roomId),
            ),
          ),
        ),
      ],
    );
  }

  Widget _featureButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final p = context.pal;

    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        // アイコンを大きめの丸にのせ、その下に名前（文字は少し細め・字間を詰める）
        child: SizedBox(
          height: 88,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  // アイコンの色をうすくした丸（暗い画面では少し濃いめ）
                  color: color.withValues(alpha: p.isDark ? 0.22 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  maxLines: 1,
                  style: TextStyle(
                    color: p.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMembers() {
    _openFeatureScreen(
      title: "メンバー",
      icon: Icons.groups_rounded,
      child: RoomMemberScreen(roomId: widget.roomId),
    );
  }

  void _openChat() {
    _openFeatureScreen(
      title: "チャット",
      icon: Icons.forum_rounded,
      child: RoomChatScreen(roomId: widget.roomId),
    );
  }

  // ============================================================
  // メンバー
  // ============================================================

  Widget _buildMembersCard(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> memberDocs, {
    required String ownerId,
    required bool isLoading,
  }) {
    final p = context.pal;

    // オーナーを先頭にする
    final sorted = [...memberDocs]
      ..sort((a, b) {
        if (a.id == ownerId) return -1;
        if (b.id == ownerId) return 1;
        return 0;
      });

    return _card(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            title: "メンバー",
            count: "${memberDocs.length}人",
            actionText: "すべて見る",
            onAction: _openMembers,
          ),

          const SizedBox(height: 12),

          if (isLoading)
            const SizedBox(
              height: 96,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            )
          else if (sorted.isEmpty)
            SizedBox(
              height: 40,
              child: Center(
                child: Text(
                  "まだメンバーがいません",
                  style: TextStyle(color: p.muted, fontSize: 13),
                ),
              ),
            )
          else
            SizedBox(
              // アイコン48＋名前＋オーナーの札が入る高さ
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: sorted.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final uid = sorted[index].id;

                  return _MemberSummaryUser(
                    key: ValueKey(uid),
                    uid: uid,
                    isOwner: uid == ownerId,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // アクティビティ（ルームへの参加・メッセージ）
  // ============================================================

  Widget _buildActivityCard(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> memberDocs,
  ) {
    final p = context.pal;

    return Builder(
      builder: (context) {
        final activities = <_Activity>[];

        // 参加
        for (final doc in memberDocs) {
          final joinedAt = doc.data()['joinedAt'];
          if (joinedAt is! Timestamp) continue;

          activities.add(
            _Activity(
              uid: doc.id,
              time: joinedAt.toDate(),
              icon: Icons.login_rounded,
              iconColor: AppColors.primary,
              text: "ルームに参加しました",
            ),
          );
        }

        // メッセージ（1つずつ、すべて出す）
        for (final doc in _recentMessages) {
          final data = doc.data();
          final createdAt = data['createdAt'];
          if (createdAt is! Timestamp) continue;

          final uid = (data['uid'] ?? '').toString();

          activities.add(
            _Activity(
              uid: uid,
              name: (data['name'] ?? '').toString(),
              time: createdAt.toDate(),
              icon: Icons.forum_rounded,
              // チャットのボタンと同じオレンジ（アイコンだけに使う色）
              iconColor: AppColors.orange,
              // メッセージの中身は出さず、送ったことだけを出す
              text: "メッセージを送りました",
              onTap: _openChat,
            ),
          );
        }

        // 新しい順に20件まで（カードの中でスクロールして見る）
        activities.sort((a, b) => b.time.compareTo(a.time));
        final shown = activities.take(20).toList();

        // カードの高さは外から決まる（残りの高さ）。中身はその中でスクロールする
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(16),
          ),
          // 枠線は中身の上に描く（中の行の色で、角の枠線が隠れないように）
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: _cardHeader(title: "アクティビティ"),
              ),

              Expanded(
                child: shown.isEmpty
                    ? Center(
                        child: Text(
                          "まだアクティビティはありません",
                          style: TextStyle(color: p.muted, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        itemCount: shown.length,
                        itemBuilder: (context, index) {
                          final activity = shown[index];

                          return _ActivityRow(
                            key: ValueKey(
                              '${activity.uid}_${activity.time.millisecondsSinceEpoch}',
                            ),
                            activity: activity,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // 共通の部品
  // ============================================================

  // 白いカード（枠つき・角丸16。ほかの画面と同じ形）
  Widget _card({required Widget child, required EdgeInsets padding}) {
    final p = context.pal;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: child,
    );
  }

  // カードの見出し（右に「すべて見る」などを出せる）
  Widget _cardHeader({
    required String title,
    String? count,
    String? actionText,
    VoidCallback? onAction,
  }) {
    final p = context.pal;

    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: p.text,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 6),
          Text(count, style: TextStyle(color: p.secondary, fontSize: 13)),
        ],
        const Spacer(),
        if (actionText != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionText,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // 各機能を専用画面として開く
  // ============================================================

  void _openFeatureScreen({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomFeatureScreen(
          title: title,
          icon: icon,
          backgroundImage: widget.backgroundImage,
          roomId: widget.roomId,
          child: child,
        ),
      ),
    );
  }

  // ============================================================
  // 右上のメニュー
  // ============================================================

  void _showMenu(Map<String, dynamic>? roomData, int memberCount) {
    final p = context.pal;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: p.card,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                ),
                title: Text("ルームの情報", style: TextStyle(color: p.text)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showRoomInfo(roomData, memberCount);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.red),
                title: const Text(
                  "ルームから退出",
                  style: TextStyle(color: AppColors.red),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showExitDialog();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showRoomInfo(Map<String, dynamic>? roomData, int memberCount) {
    final p = context.pal;

    final title = (roomData?['title'] ?? widget.roomTitle).toString();
    final description = (roomData?['description'] ?? '').toString().trim();
    final isPublic = roomData?['isPublic'] ?? true;
    final createdAt = roomData?['createdAt'];

    Widget infoLine(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              child: Text(
                label,
                style: TextStyle(color: p.secondary, fontSize: 13),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(color: p.text, fontSize: 13, height: 1.5),
              ),
            ),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: p.card,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: p.text,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              infoLine("説明", description.isEmpty ? "なし" : description),
              infoLine("公開", isPublic ? "公開ルーム" : "非公開ルーム"),
              infoLine("メンバー", "$memberCount人"),
              if (createdAt is Timestamp)
                infoLine("作成日", _dateLabel(createdAt.toDate())),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                "閉じる",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _dateLabel(DateTime date) {
    return "${date.year}年${date.month}月${date.day}日";
  }

  // ============================================================
  // ルームから退出
  // ============================================================

  void _showExitDialog() {
    final p = context.pal;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: p.card,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "ルームから退出",
            style: TextStyle(
              color: p.text,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "このルームから退出しますか？",
            style: TextStyle(color: p.text, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("キャンセル", style: TextStyle(color: p.secondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _leaveRoom();
              },
              child: const Text(
                "退出する",
                style: TextStyle(
                  color: AppColors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _leaveRoom() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _roomRef.collection('members').doc(user.uid).delete();

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint("ルームの退出に失敗しました: $e");

      if (!mounted) return;

      final p = context.pal;

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: p.card,
          surfaceTintColor: Colors.transparent,
          content: Text(
            "ルームから退出できませんでした。\n通信の状態を確かめて、もう一度お試しください。",
            style: TextStyle(color: p.text, fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                "閉じる",
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }
  }
}

// ======================================================================
// メンバー1人分（アイコン・名前・オーナーの札）
// ======================================================================

class _MemberSummaryUser extends StatefulWidget {
  final String uid;
  final bool isOwner;

  const _MemberSummaryUser({
    super.key,
    required this.uid,
    required this.isOwner,
  });

  @override
  State<_MemberSummaryUser> createState() => _MemberSummaryUserState();
}

class _MemberSummaryUserState extends State<_MemberSummaryUser> {
  // 描き直すたびに読み直さないよう、最初に1回だけ読む
  late final Future<DocumentSnapshot<Map<String, dynamic>>> _user =
      FirebaseFirestore.instance.collection('users').doc(widget.uid).get();

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _user,
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final name = (data?['name'] ?? '').toString();
        final icon = (data?['icon'] ?? '').toString();

        return SizedBox(
          width: 64,
          child: Column(
            children: [
              PartnerAvatar(icon: icon, radius: 24),
              const SizedBox(height: 5),
              Text(
                name.isEmpty ? "…" : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: p.text,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.isOwner) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: p.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "オーナー",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ======================================================================
// アクティビティ1行分
// ======================================================================

class _Activity {
  final String uid;
  final String name;
  final DateTime time;
  final IconData icon;
  // アイコンの色（参加は青、メッセージは緑）
  final Color iconColor;
  // 名前の下に出す文（「ルームに参加しました」か、メッセージの中身）
  final String text;
  final VoidCallback? onTap;

  const _Activity({
    required this.uid,
    this.name = '',
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.text,
    this.onTap,
  });
}

class _ActivityRow extends StatefulWidget {
  final _Activity activity;

  const _ActivityRow({super.key, required this.activity});

  @override
  State<_ActivityRow> createState() => _ActivityRowState();
}

class _ActivityRowState extends State<_ActivityRow> {
  // 名前が分からないとき（参加のできごと）だけ、users から読む
  Future<DocumentSnapshot<Map<String, dynamic>>>? _user;

  @override
  void initState() {
    super.initState();

    if (widget.activity.name.isEmpty && widget.activity.uid.isNotEmpty) {
      _user = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.activity.uid)
          .get();
    }
  }

  // 今日なら「10:32」、それより前なら「11/18」
  String _timeLabel(DateTime time) {
    final now = DateTime.now();
    final isToday =
        time.year == now.year && time.month == now.month && time.day == now.day;

    if (isToday) {
      return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
    }
    return "${time.month}/${time.day}";
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final activity = widget.activity;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _user,
      builder: (context, snapshot) {
        final name = activity.name.isNotEmpty
            ? activity.name
            : (snapshot.data?.data()?['name'] ?? '').toString();

        return InkWell(
          onTap: activity.onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    // アイコンの色をうすくした丸（暗い画面では少し濃いめ）
                    color: activity.iconColor.withValues(
                      alpha: p.isDark ? 0.22 : 0.12,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    activity.icon,
                    color: activity.iconColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                // 上：名前（太字）と時刻／下：できごと（「ルームに参加しました」「メッセージを送りました」）
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name.isEmpty ? "だれか" : name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: p.text,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _timeLabel(activity.time),
                            style: TextStyle(color: p.muted, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activity.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: p.secondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
