// ======================================================================
// 【画面】ホーム（下のタブ「ホーム」）
//
// 主なクラス: HomeScreen
// 開き方: main.dart の MainNavigationScreen
// ・上部：チャット・通知（未読の赤い点）のアイコン
// ・日付、学習タイマー（stopwatch_widget.dart）
// ・今日の目標：目標時間・達成率・今日の学習時間・目標まで残り
// ・曜日ごとの目標ボタン（weekday_goal_button.dart）
// ・使うデータ: users, studyRecords, friend_requests, notifications
// ======================================================================

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_support_app/main.dart' as app; // ← 'app' という名前のあだ名を付ける
import 'package:study_support_app/screens/chat/chat_list_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_support_app/screens/home/weekday_goal_button.dart';
import 'package:study_support_app/screens/notification/notification_screen.dart';
import 'package:study_support_app/screens/home/stopwatch_widget.dart';
import 'package:study_support_app/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 停止済みの学習時間
  Duration todayTotal = Duration.zero;

  String getToday() {
    final now = DateTime.now();
    const weeks = ["月", "火", "水", "木", "金", "土", "日"];

    return "${now.year}年${now.month}月${now.day}日(${weeks[now.weekday - 1]})";
  }

  @override
  void initState() {
    super.initState();

    _loadTodayStudyTime();
    _loadTodayGoal();
  }

  Future<void> _loadTodayGoal() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();

    if (data == null) return;

    final goaltime = data['goaltime'] as Map<String, dynamic>?;

    if (goaltime == null) return;

    const weekdayKeys = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    final todayKey = weekdayKeys[DateTime.now().weekday - 1];

    final minutes = (goaltime[todayKey] as num?)?.toInt() ?? 0;

    app.dailyTargetHours.value = minutes / 60.0;
  }

  Future<void> _loadTodayStudyTime() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final now = DateTime.now();

    final dateId =
        "${now.year.toString().padLeft(4, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("studyRecords")
        .doc(dateId)
        .get();

    if (!mounted) return;

    if (doc.exists) {
      final data = doc.data();

      final savedSeconds = (data?["studyTime"] as num?)?.toInt() ?? 0;

      setState(() {
        todayTotal = Duration(seconds: savedSeconds);
      });

      app.todayStudySeconds.value = savedSeconds;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF121212) : AppColors.background;

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final textColor = isDark ? Colors.white : Colors.black87;

    final divColor2 = isDark ? Colors.grey.shade800 : AppColors.border;

    final subTextColor = isDark ? Colors.white60 : Colors.black54;

    final borderColor = divColor2;

    const accentColor = AppColors.primary;

    return Scaffold(
      backgroundColor: bgColor,

      // ==========================================================
      // AppBar
      // ==========================================================
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: AppColors.primary,

        title: const Text(
          "ホーム",
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 9),
            child: IconButton(
              icon: const Icon(Icons.chat_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatListScreen(),
                  ), // ※ファイル名に合わせて変更
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .collection('friend_requests')
                  .where('status', isEqualTo: 'pending')
                  .where('isRead', isEqualTo: false)
                  .snapshots(),

              builder: (context, requestSnapshot) {
                final hasFriendRequest =
                    requestSnapshot.hasData &&
                    requestSnapshot.data!.docs.isNotEmpty;

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection('notifications')
                      .where('isRead', isEqualTo: false)
                      .snapshots(),

                  builder: (context, notificationSnapshot) {
                    final hasNotification =
                        notificationSnapshot.hasData &&
                        notificationSnapshot.data!.docs.isNotEmpty;

                    final hasUnread = hasFriendRequest || hasNotification;

                    return IconButton(
                      onPressed: () async {
                        // =========================================
                        // 先に通知画面を表示
                        // =========================================
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationScreen(),
                          ),
                        );

                        // =========================================
                        // その後、未読を既読にする
                        // =========================================
                        final user = FirebaseAuth.instance.currentUser;

                        if (user != null) {
                          final firestore = FirebaseFirestore.instance;

                          // 未読の友達申請を既読にする
                          final friendRequests = await firestore
                              .collection('users')
                              .doc(user.uid)
                              .collection('friend_requests')
                              .where('isRead', isEqualTo: false)
                              .get();

                          for (final doc in friendRequests.docs) {
                            await doc.reference.update({'isRead': true});
                          }

                          // 未読の通知を既読にする
                          final notifications = await firestore
                              .collection('users')
                              .doc(user.uid)
                              .collection('notifications')
                              .where('isRead', isEqualTo: false)
                              .get();

                          for (final doc in notifications.docs) {
                            await doc.reference.update({'isRead': true});
                          }
                        }
                      },

                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications_none),

                          // =========================================
                          // 赤い点
                          // =========================================
                          if (hasUnread)
                            Positioned(
                              right: -1,
                              top: -1,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],

        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // ==========================================================
      // Body
      // ==========================================================
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(17, 14, 17, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ====================================================
              // 日付
              // ====================================================
              Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      getToday(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ====================================================
              // タイマー
              // ====================================================
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: double.infinity,
                  child: StopwatchWidget(
                    onSaveStudyTime: saveTodayStudyTime,

                    // タイマー動作中の画面表示だけ更新
                    onTick: (sessionTime) {
                      app.todayStudySeconds.value =
                          todayTotal.inSeconds + sessionTime.inSeconds;
                    },

                    // 停止・リセットしたときに確定
                    onStop: (sessionTime) {
                      setState(() {
                        todayTotal += sessionTime;
                      });

                      app.todayStudySeconds.value = todayTotal.inSeconds;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ====================================================
              // 今日の目標
              // ====================================================
              ValueListenableBuilder<double>(
                valueListenable: app.dailyTargetHours,

                builder: (context, targetHoursValue, child) {
                  final goalTime = Duration(
                    hours: targetHoursValue.floor(),
                    minutes:
                        ((targetHoursValue - targetHoursValue.floor()) * 60)
                            .round(),
                  );

                  // ------------------------------------------------
                  // 今日の学習時間をリアルタイム監視
                  // ------------------------------------------------
                  return ValueListenableBuilder<int>(
                    valueListenable: app.todayStudySeconds,

                    builder: (context, studySeconds, child) {
                      final studyTime = Duration(seconds: studySeconds);

                      // 達成率
                      final progress = goalTime.inSeconds > 0
                          ? studySeconds / goalTime.inSeconds
                          : 0.0;

                      // 残り時間
                      final hasGoal = goalTime.inSeconds > 0;

                      final remainingTime = goalTime - studyTime;

                      return _buildGoalCard(
                        goalTime: goalTime,
                        studyTime: studyTime,
                        progress: progress,
                        hasGoal: hasGoal,
                        remainingTime: remainingTime,
                        isDark: isDark,
                        cardColor: cardColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        borderColor: borderColor,
                        accentColor: accentColor,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 14),

              const WeekdayGoalButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // 今日の目標カード（左：達成率の円、右：目標時間、下：2つのタイル）
  // ==============================================================
  Widget _buildGoalCard({
    required Duration goalTime,
    required Duration studyTime,
    required double progress,
    required bool hasGoal,
    required Duration remainingTime,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
    required Color accentColor,
  }) {
    final achieved = hasGoal && remainingTime.isNegative;
    final ringColor = accentColor;
    final tileColor = isDark
        ? const Color(0xFF2D2D2D)
        : const Color(0xFFF3F7FC);

    final goalText = goalTime.inHours == 0
        ? "${goalTime.inMinutes}分"
        : "${goalTime.inHours}時間${goalTime.inMinutes % 60}分";

    final studyText = studyTime.inHours == 0
        ? "${studyTime.inMinutes}分"
        : "${studyTime.inHours}時間${studyTime.inMinutes % 60}分";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // ------------------------------------------------
              // 達成率の円
              // ------------------------------------------------
              SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      color: ringColor,
                      backgroundColor: isDark
                          ? Colors.grey.shade800
                          : AppColors.primaryTrack,
                    ),
                    // 文字が大きい設定でも円からはみ出さないよう、入りきらないときだけ縮める
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${(progress * 100).toStringAsFixed(0)}%",
                              style: GoogleFonts.roboto(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            Text(
                              "達成率",
                              style: TextStyle(
                                fontSize: 11,
                                color: subTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // ------------------------------------------------
              // 目標時間
              // ------------------------------------------------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.flag_rounded,
                          size: 17,
                          color: Color(0xFFFF2D55),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "今日の目標",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    !hasGoal
                        ? Text(
                            "未設定",
                            style: TextStyle(
                              color: textColor,
                              // 漢字は数字より大きく見えるので、数字と見た目の高さがそろう 18 にする
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : Text.rich(
                            TextSpan(
                              children: _buildTimeSpans(
                                goalText,
                                accentColor,
                                numberSize: 26,
                                unitSize: 14,
                              ),
                            ),
                          ),
                    const SizedBox(height: 6),
                    Text(
                      !hasGoal
                          ? "下のボタンから設定できます"
                          : achieved
                          ? "今日の目標を達成しました"
                          : "一歩ずつ積み上げよう",
                      style: TextStyle(
                        fontSize: 13,
                        color: achieved ? accentColor : subTextColor,
                        fontWeight: achieved ? FontWeight.w700 : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ------------------------------------------------
          // 今日の学習時間 ／ 目標まで残り
          // ------------------------------------------------
          // IntrinsicHeight で、2つのタイルの高さを中身に合わせてそろえる
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildStatTile(
                    icon: Icons.timer_outlined,
                    label: "今日の学習時間",
                    value: Text.rich(
                      TextSpan(children: _buildTimeSpans(studyText, textColor)),
                    ),
                    tileColor: tileColor,
                    iconColor: accentColor,
                    subTextColor: subTextColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatTile(
                    icon: Icons.hourglass_empty_rounded,
                    label: "目標まで残り",
                    value: !hasGoal
                        ? Text(
                            "未設定",
                            style: TextStyle(
                              fontSize: 16,
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : remainingTime.isNegative
                        ? Text(
                            "達成済み！",
                            style: TextStyle(
                              fontSize: 16,
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : Text.rich(
                            TextSpan(
                              children: _buildTimeSpans(
                                formatRemainingTime(remainingTime.inSeconds),
                                textColor,
                              ),
                            ),
                          ),
                    tileColor: tileColor,
                    iconColor: accentColor,
                    subTextColor: subTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required Widget value,
    required Color tileColor,
    required Color iconColor,
    required Color subTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: iconColor),
              const SizedBox(width: 5),
              Flexible(
                // 文字が大きい設定でも1行に収まるよう、入りきらないときだけ縮める
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 13, color: subTextColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          value,
        ],
      ),
    );
  }

  List<TextSpan> _buildTimeSpans(
    String value,
    Color color, {
    double numberSize = 20,
    double unitSize = 12,
  }) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'(\d+(?:\.\d+)?)(時間|分|秒)');
    final matches = regex.allMatches(value);

    if (matches.isNotEmpty) {
      for (final match in matches) {
        final number = match.group(1)!;
        final unit = match.group(2)!;

        // 数字 → Roboto・25px
        spans.add(
          TextSpan(
            text: number,
            style: GoogleFonts.roboto(
              color: color,
              fontSize: numberSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

        // 単位 → 14px
        spans.add(
          TextSpan(
            text: unit,
            style: TextStyle(
              color: color,
              fontSize: unitSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }

      return spans;
    }

    return [
      TextSpan(
        text: value,
        style: GoogleFonts.roboto(
          color: color,
          fontSize: numberSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    ];
  }

  String formatStudyTime(int totalSeconds) {
    // 100時間以上 → 「123.8時間」
    if (totalSeconds >= 100 * 3600) {
      final tenthsOfHour = (totalSeconds * 10) ~/ 3600;

      final wholeHours = tenthsOfHour ~/ 10;
      final decimal = tenthsOfHour % 10;

      return "$wholeHours.$decimal時間";
    }

    // 1時間未満 → 「30分45秒」
    if (totalSeconds < 3600) {
      final minutes = totalSeconds ~/ 60;
      final seconds = totalSeconds % 60;

      return "$minutes分$seconds秒";
    }

    // 1時間以上100時間未満 → 「2時間30分」
    final wholeHours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    return "$wholeHours時間$minutes分";
  }

  String formatRemainingTime(int remainingSeconds) {
    final hours = remainingSeconds ~/ 3600;
    final minutes = (remainingSeconds % 3600) ~/ 60;
    final seconds = remainingSeconds % 60;

    // 10分未満になったら秒まで表示
    if (remainingSeconds < 600) {
      return "$minutes分$seconds秒";
    }

    // 10分以上
    if (hours > 0) {
      return "$hours時間$minutes分";
    }

    return "$minutes分";
  }

  Future<void> saveTodayStudyTime(int seconds) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || seconds <= 0) return;

    // 今日の日付
    final now = DateTime.now();

    final dateId =
        "${now.year.toString().padLeft(4, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";

    final studyRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("studyRecords")
        .doc(dateId);

    // その日の学習時間に加算
    // その日の学習時間に加算
    await studyRef.set({
      "studyTime": FieldValue.increment(seconds),
      "date": dateId,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
