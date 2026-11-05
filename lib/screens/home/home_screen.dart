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

    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final textColor = isDark ? Colors.white : Colors.black87;

    final divColor1 = isDark ? Colors.grey.shade800 : const Color(0xFFB5BDC7);

    final divColor2 = isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bgColor,

      // ==========================================================
      // AppBar
      // ==========================================================
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: const Color(0xFF258EDB),

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
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
                      color: Color(0xFF258EDB),
                      size: 20,
                    ),

                    const SizedBox(width: 8),

                    Text(
                      getToday(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

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

              const SizedBox(height: 4),

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

                      return Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: double.infinity,
                          child: Card(
                            elevation: 0,
                            color: cardColor,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: divColor2, width: 1),
                            ),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ==================================
                                // タイトル
                                // ==================================
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 20,
                                    right: 20,
                                    top: 13,
                                    bottom: 10,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.flag_rounded,
                                        size: 24,
                                        color: Color(0xFFFF2D55),
                                      ),

                                      const SizedBox(width: 6),

                                      Text(
                                        "今日の目標",
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Container(
                                  height: 1,
                                  width: double.infinity,
                                  color: divColor1,
                                ),

                                // ==================================
                                // 目標時間・達成率
                                // ==================================
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 19,
                                    vertical: 7,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      !hasGoal
                                          ? Text(
                                              "未設定",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: textColor,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : RichText(
                                              textAlign: TextAlign.center,
                                              text: TextSpan(
                                                children: goalTime.inHours == 0
                                                    ? [
                                                        TextSpan(
                                                          text:
                                                              "${goalTime.inMinutes}",
                                                          style:
                                                              GoogleFonts.roboto(
                                                                color:
                                                                    const Color(
                                                                      0xFF258EDB,
                                                                    ),
                                                                // 数字
                                                                fontSize: 25,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                        TextSpan(
                                                          text: "分",
                                                          style:
                                                              const TextStyle(
                                                                color: Color(
                                                                  0xFF258EDB,
                                                                ), // 単位
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ]
                                                    : [
                                                        TextSpan(
                                                          text:
                                                              "${goalTime.inHours}",
                                                          style:
                                                              GoogleFonts.roboto(
                                                                color:
                                                                    const Color(
                                                                      0xFF258EDB,
                                                                    ),
                                                                // 数字
                                                                fontSize: 25,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                        TextSpan(
                                                          text: "時間",
                                                          style:
                                                              const TextStyle(
                                                                color: Color(
                                                                  0xFF258EDB,
                                                                ), // 単位
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              "${goalTime.inMinutes % 60}",
                                                          style:
                                                              GoogleFonts.roboto(
                                                                color:
                                                                    const Color(
                                                                      0xFF258EDB,
                                                                    ),
                                                                // 数字
                                                                fontSize: 25,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                        TextSpan(
                                                          text: "分",
                                                          style:
                                                              const TextStyle(
                                                                color: Color(
                                                                  0xFF258EDB,
                                                                ), // 単位
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ],
                                              ),
                                            ),

                                      const SizedBox(height: 6),

                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.trending_up_rounded,
                                            size: 19,
                                            color: Color(0xFF258EDB),
                                          ),

                                          const SizedBox(width: 6),

                                          Text(
                                            "達成率",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: textColor,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 2),

                                      Row(
                                        children: [
                                          Expanded(
                                            child: LinearProgressIndicator(
                                              value: progress.clamp(0.0, 1.0),
                                              minHeight: 7,
                                              borderRadius:
                                                  BorderRadius.circular(9),
                                              color: const Color(0xFF258EDB),
                                              backgroundColor: const Color(
                                                0xFFBBDEFB,
                                              ),
                                            ),
                                          ),

                                          const SizedBox(width: 10),

                                          Text(
                                            "${(progress * 100).toStringAsFixed(0)}%",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: textColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 0),

                                Container(
                                  height: 1,
                                  width: double.infinity,
                                  color: divColor2,
                                ),

                                const SizedBox(height: 4),

                                // ==================================
                                // 今日の学習時間
                                // ==================================
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 19,
                                    vertical: 10,
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.timer_outlined,
                                            size: 19,
                                            color: Color(0xFF258EDB),
                                          ),

                                          const SizedBox(width: 6),

                                          Text(
                                            "今日の学習時間",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: textColor,
                                            ),
                                          ),

                                          const Spacer(),

                                          RichText(
                                            textAlign: TextAlign.right,
                                            text: TextSpan(
                                              children: _buildTimeSpans(
                                                studyTime.inHours == 0
                                                    ? "${studyTime.inMinutes}分"
                                                    : "${studyTime.inHours}時間"
                                                          "${studyTime.inMinutes % 60}分",
                                                textColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Container(
                                  height: 1,
                                  width: double.infinity,
                                  color: divColor2,
                                ),

                                const SizedBox(height: 4),

                                // ==================================
                                // 目標まで残り
                                // ==================================
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 19,
                                    vertical: 10,
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.hourglass_empty,
                                            size: 19,
                                            color: Color(0xFF258EDB),
                                          ),

                                          const SizedBox(width: 6),

                                          Text(
                                            "目標まで残り",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: textColor,
                                            ),
                                          ),

                                          const Spacer(),

                                          !hasGoal
                                              ? Text(
                                                  "未設定",
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: textColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                              : remainingTime.isNegative
                                              ? Text(
                                                  "達成済み！",
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: textColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                              : RichText(
                                                  textAlign: TextAlign.right,
                                                  text: TextSpan(
                                                    children: _buildTimeSpans(
                                                      formatRemainingTime(
                                                        remainingTime.inSeconds,
                                                      ),
                                                      textColor,
                                                    ),
                                                  ),
                                                ),
                                        ],
                                      ),

                                      const SizedBox(height: 4),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 10),

              const WeekdayGoalButton(),
            ],
          ),
        ),
      ),
    );
  }

  List<TextSpan> _buildTimeSpans(String value, Color color) {
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
              fontSize: 22,
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
              fontSize: 11,
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
          fontSize: 22,
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
