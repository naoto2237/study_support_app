// ======================================================================
// 【部品】比較グラフ（週／月／年）
//
// 主なクラス: ComparisonChartSection
// ・「あなた」と「全体平均」の学習時間を、棒を2本ならべて比べる
// ・週：月曜～日曜の日ごと／月：カレンダーの週ごと／年：月ごと
// ・「<」「>」で前・次の週（月・年）へ動かせる（学習記録の推移と同じ。_offset）
// ・全体平均 ＝ その日（週・月）の全員の学習時間の合計 ÷ 全体のユーザー数
//   （勉強しなかった人も0時間として平均に入れる。上の「学習時間の比較」と同じ考え方）
// ・特定のユーザーでは、全体平均の代わりに選んだ相手（partner）の棒を出す
//   （相手の今日の分は、相手のアプリが保存した値）
// ・あなたの今日の分は、タイマーの今の値（todayStudySeconds）を使う
// ・見た目は「自分の記録」のグラフ（study_time_chart_section.dart）とそろえる
// ・使うデータ: users, users/{uid}/studyRecords
// ・旧ファイル名: comparison_screen3.dart
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:study_support_app/main.dart' show todayStudySeconds;
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/screens/record/chart_tooltip_layout.dart';
import 'package:study_support_app/screens/record/comparison/compare_user_picker.dart';

class ComparisonChartSection extends StatefulWidget {
  final int totalSeconds;
  final String comparisonTarget;

  // 特定のユーザーで比べる相手（まだ選んでいないときは null）
  final ComparePartner? partner;

  // 「比較する」を押したか（押すまでは、グラフの代わりに案内を出す）
  final bool isCompared;

  const ComparisonChartSection({
    super.key,
    required this.totalSeconds,
    required this.comparisonTarget,
    required this.isCompared,
    this.partner,
  });

  @override
  State<ComparisonChartSection> createState() => _ComparisonChartSectionState();
}

// グラフの棒1本ぶん（1日・1週・1か月）
class _Bucket {
  final String label;
  final List<DateTime> days;

  const _Bucket(this.label, this.days);
}

class _ComparisonChartSectionState extends State<ComparisonChartSection> {
  // 0:週、1:月、2:年
  int selectedPeriod = 0;

  // タップしている棒の組の番号（タップしていないときは -1）
  int _touchedIndex = -1;

  // 押している位置（グラフの中の座標）。指を離すと null
  Offset? _touchPosition;

  // 左の目盛り（数字と単位）の幅
  // グラフの部品が教えてくる「押した位置」は、この幅を除いた場所から数えた値なので、
  // 吹き出しを置くときはこの幅を足す
  static const double _leftAxisWidth = 36;

  bool isLoading = true;
  bool hasError = false;

  // 自分の記録（"2026-11-12" → 秒）
  final Map<String, int> myRecords = {};

  // 全員の記録の合計（"2026-11-12" → 全員ぶんの秒の合計）
  final Map<String, int> allUsersTotals = {};

  // ユーザーごとの記録（uid → "2026-11-12" → 秒）。選んだ相手の棒に使う
  final Map<String, Map<String, int>> recordsByUser = {};

  // 全体のユーザー数（平均の割る数）
  int userCount = 0;

  static const _weekdays = ["月", "火", "水", "木", "金", "土", "日"];

  // 全体平均の棒の色
  static const _averageColor = Color(0xFFBDBDBD);

  bool get _showAverage => widget.comparisonTarget == "全体のユーザー";

  // あなたの横に並べる相手（全体平均か、選んだ相手）がいるか
  bool get _showOther => _showAverage || widget.partner != null;

  // 相手の呼び名（凡例・吹き出しに出す）
  String get _otherLabel => _showAverage ? "全体平均" : widget.partner!.name;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  // ==============================================================
  // 記録の読み込み（全員ぶん。グラフの期間を変えても読み直さない）
  // ==============================================================

  Future<void> _loadRecords() async {
    try {
      final myUid = FirebaseAuth.instance.currentUser?.uid;

      final usersSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .get();

      // ユーザーごとの記録を、まとめて読み込む
      final recordSnapshots = await Future.wait(
        usersSnapshot.docs.map((userDoc) {
          return FirebaseFirestore.instance
              .collection("users")
              .doc(userDoc.id)
              .collection("studyRecords")
              .get();
        }),
      );

      myRecords.clear();
      allUsersTotals.clear();
      recordsByUser.clear();

      for (int i = 0; i < usersSnapshot.docs.length; i++) {
        final uid = usersSnapshot.docs[i].id;

        for (final recordDoc in recordSnapshots[i].docs) {
          final seconds = (recordDoc.data()["studyTime"] as num?)?.toInt() ?? 0;

          allUsersTotals[recordDoc.id] =
              (allUsersTotals[recordDoc.id] ?? 0) + seconds;

          recordsByUser.putIfAbsent(uid, () => {})[recordDoc.id] = seconds;

          if (uid == myUid) {
            myRecords[recordDoc.id] = seconds;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        userCount = usersSnapshot.docs.length;
        isLoading = false;
        hasError = false;
      });
    } catch (e) {
      debugPrint("比較グラフの記録の取得に失敗しました: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  // ==============================================================
  // 期間と棒の分け方
  // ==============================================================

  // 矢印で動かした数（0：今の期間、-1：1つ前、1：1つ後）
  int _offset = 0;

  // 表示している期間の基準の日（週は今日から _offset 週ずらした日、月・年はその月・年の1日）
  DateTime get _anchor {
    final today = _today;

    if (selectedPeriod == 0) {
      return DateTime(today.year, today.month, today.day + 7 * _offset);
    }

    if (selectedPeriod == 1) {
      return DateTime(today.year, today.month + _offset, 1);
    }

    return DateTime(today.year + _offset, 1, 1);
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String _dateId(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  List<DateTime> _daysBetween(DateTime start, DateTime end) {
    final days = <DateTime>[];

    for (
      DateTime d = start;
      !d.isAfter(end);
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      days.add(d);
    }

    return days;
  }

  List<_Bucket> _buckets() {
    // 表示している期間の基準の日（矢印で前後に動かす。今の期間は今日）
    final today = _anchor;

    // 週：今週の月曜～日曜を1日ずつ
    if (selectedPeriod == 0) {
      final monday = today.subtract(Duration(days: today.weekday - 1));

      return List.generate(7, (i) {
        final date = DateTime(monday.year, monday.month, monday.day + i);

        return _Bucket(
          "${_weekdays[date.weekday - 1]}\n${date.month}/${date.day}",
          [date],
        );
      });
    }

    // 月：今月をカレンダーの週（月曜はじまり）ごと
    if (selectedPeriod == 1) {
      final firstDay = DateTime(today.year, today.month, 1);
      final lastDay = DateTime(today.year, today.month + 1, 0);

      DateTime weekStart = firstDay.subtract(
        Duration(days: firstDay.weekday - 1),
      );

      final buckets = <_Bucket>[];
      int weekNumber = 1;

      while (!weekStart.isAfter(lastDay)) {
        final weekEnd = DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 6,
        );

        // 今月の日だけ
        final days = _daysBetween(
          weekStart.isBefore(firstDay) ? firstDay : weekStart,
          weekEnd.isAfter(lastDay) ? lastDay : weekEnd,
        );

        buckets.add(_Bucket("$weekNumber週目", days));

        weekNumber++;
        weekStart = DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + 7,
        );
      }

      return buckets;
    }

    // 年：今年を月ごと
    return List.generate(12, (i) {
      final month = i + 1;

      return _Bucket(
        "$month月",
        _daysBetween(
          DateTime(today.year, month, 1),
          DateTime(today.year, month + 1, 0),
        ),
      );
    });
  }

  // 今日をふくむ棒の番号
  int _currentIndex(List<_Bucket> buckets) {
    final today = _today;

    for (int i = 0; i < buckets.length; i++) {
      if (buckets[i].days.any((d) => d == today)) return i;
    }

    return -1;
  }

  String _periodDateText() {
    final today = _anchor;

    if (selectedPeriod == 0) {
      final monday = today.subtract(Duration(days: today.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));

      return "${monday.month}/${monday.day} - ${sunday.month}/${sunday.day}";
    }

    if (selectedPeriod == 1) {
      return "${today.year}年${today.month}月";
    }

    return "${today.year}年";
  }

  // ==============================================================
  // 秒の集計
  // ==============================================================

  // あなたの秒（今日の分は、タイマーの今の値）
  int _mySeconds(List<DateTime> days, int todaySeconds) {
    final today = _today;
    int total = 0;

    for (final day in days) {
      total += day == today ? todaySeconds : (myRecords[_dateId(day)] ?? 0);
    }

    return total;
  }

  // 全体平均の秒
  int _averageSeconds(List<DateTime> days) {
    if (userCount == 0) return 0;

    int total = 0;

    for (final day in days) {
      total += allUsersTotals[_dateId(day)] ?? 0;
    }

    return total ~/ userCount;
  }

  // 相手の秒（全体平均か、選んだ相手の保存ずみの記録）
  int _otherSeconds(List<DateTime> days) {
    if (_showAverage) return _averageSeconds(days);

    final records = recordsByUser[widget.partner?.uid] ?? const {};
    int total = 0;

    for (final day in days) {
      total += records[_dateId(day)] ?? 0;
    }

    return total;
  }

  // 吹き出し用：1時間未満は秒まで（「15分27秒」）、1時間以上は分まで（「1時間5分」）
  String _formatTooltipTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return minutes > 0 ? "$hours時間$minutes分" : "$hours時間";
    }

    if (minutes > 0) {
      return "$minutes分$remainingSeconds秒";
    }

    return "$remainingSeconds秒";
  }

  // 吹き出し用：相手との差（「平均より 10分12秒 多い」「相手より 5分 少ない」など）
  String _differenceText(int mine, int average) {
    final diff = mine - average;
    final who = _showAverage ? "平均" : "相手";

    if (diff == 0) return "$whoと同じ";

    final text = _formatTooltipTime(diff.abs());

    return diff > 0 ? "$whoより $text 多い" : "$whoより $text 少ない";
  }

  // 期間の合計：上の「学習時間の比較」や学習記録のサマリーと同じ書き方
  // 1時間未満は秒まで（「9分35秒」）、100時間未満は「3時間12分」、100時間以上は「120.5時間」
  String _formatSeconds(int seconds) {
    if (seconds >= 100 * 3600) {
      final tenthsOfHour = (seconds * 10) ~/ 3600;
      return "${tenthsOfHour ~/ 10}.${tenthsOfHour % 10}時間";
    }

    if (seconds < 3600) {
      return "${seconds ~/ 60}分${seconds % 60}秒";
    }

    return "${seconds ~/ 3600}時間${(seconds % 3600) ~/ 60}分";
  }

  // ==============================================================
  // build
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final textColor = isDark ? Colors.white : const Color(0xFF202124);

    final secondaryColor = isDark ? Colors.white70 : const Color(0xFF666666);

    // 「比較する」を押すまでは、グラフの代わりに案内を出す（上の「学習時間の比較」と同じ）
    if (!widget.isCompared) {
      return _card(
        cardColor,
        isDark,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "学習時間の比較グラフ",
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildNotCompared(secondaryColor, isDark),
          ],
        ),
      );
    }

    return Column(
      children: [
        _card(
          cardColor,
          isDark,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "学習時間の比較グラフ",
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              _buildPeriodSelector(textColor, isDark),

              const SizedBox(height: 4),

              // ------------------------------------------------------
              // 前・次の期間へ（「学習記録の推移」と同じ形）
              // ------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => setState(() {
                      _offset--;
                      _touchedIndex = -1;
                    }),
                    icon: Icon(Icons.chevron_left, color: textColor),
                  ),
                  Text(
                    _periodDateText(),
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      _offset++;
                      _touchedIndex = -1;
                    }),
                    icon: Icon(Icons.chevron_right, color: textColor),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              if (isLoading)
                const SizedBox(
                  height: 300,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (hasError)
                SizedBox(
                  height: 300,
                  child: Center(
                    child: Text(
                      "記録を読み込めませんでした",
                      style: TextStyle(color: secondaryColor, fontSize: 13),
                    ),
                  ),
                )
              else
                // 今日の学習時間が変わるたびに描き直す
                ValueListenableBuilder<int>(
                  valueListenable: todayStudySeconds,
                  builder: (context, todaySeconds, child) {
                    return _buildChartArea(
                      todaySeconds,
                      textColor,
                      secondaryColor,
                      isDark,
                    );
                  },
                ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
          child: Text(
            "グラフの表示には時間がかかる場合があります",
            textAlign: TextAlign.center,
            style: TextStyle(color: secondaryColor, fontSize: 11),
          ),
        ),
      ],
    );
  }

  // 「比較する」を押す前の案内（comparison_result_section.dart と同じ形）
  Widget _buildNotCompared(Color secondaryColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : AppColors.primarySoft,
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              "上の「比較する」を押すと、ここにグラフが出ます",
              style: TextStyle(color: secondaryColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartArea(
    int todaySeconds,
    Color textColor,
    Color secondaryColor,
    bool isDark,
  ) {
    final buckets = _buckets();

    final mySeconds = buckets
        .map((b) => _mySeconds(b.days, todaySeconds))
        .toList();

    final averageSeconds = buckets.map((b) => _otherSeconds(b.days)).toList();

    final myTotal = mySeconds.fold<int>(0, (total, s) => total + s);
    final averageTotal = averageSeconds.fold<int>(0, (total, s) => total + s);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ------------------------------------------------------
        // 期間の合計（あなた／全体平均）
        // ------------------------------------------------------
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _summaryItem(
                "あなた",
                _formatSeconds(myTotal),
                // あなたの合計の数字と単位は緑（棒と凡例は青のまま）
                AppColors.green,
                secondaryColor,
                numberSize: 25,
              ),
            ),
            // 右半分をいっぱいに使って、右はしにそろえる（名前が長いときは「…」）
            if (_showOther)
              Expanded(
                child: _summaryItem(
                  _showAverage ? "全体平均（$userCount人）" : _otherLabel,
                  _formatSeconds(averageTotal),
                  textColor,
                  secondaryColor,
                  numberSize: 18,
                  alignEnd: true,
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // ------------------------------------------------------
        // 凡例
        // ------------------------------------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _legend(AppColors.primary, "あなた", secondaryColor),
            if (_showOther) ...[
              const SizedBox(width: 14),
              Flexible(
                child: _legend(
                  isDark ? Colors.white38 : _averageColor,
                  _otherLabel,
                  secondaryColor,
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 10),

        SizedBox(
          height: 240,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              BarChart(
                _createChart(buckets, mySeconds, averageSeconds, isDark),
              ),

              // 押している間だけ、押した位置の少し上に吹き出しを出す
              if (_touchedIndex >= 0 &&
                  _touchedIndex < buckets.length &&
                  _touchPosition != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomSingleChildLayout(
                      delegate: ChartTooltipLayoutDelegate(
                        _touchPosition! + const Offset(_leftAxisWidth, 0),
                      ),
                      child: _buildTouchTooltip(
                        _touchedIndex,
                        buckets,
                        mySeconds,
                        averageSeconds,
                        isDark,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        if (!_showOther) ...[
          const SizedBox(height: 10),
          Text(
            "上の「相手を選ぶ」から相手を選ぶと、その人の棒も並びます",
            style: TextStyle(color: secondaryColor, fontSize: 11.5),
          ),
        ],
      ],
    );
  }

  // ==============================================================
  // 週 / 月 / 年
  // ==============================================================

  Widget _buildPeriodSelector(Color textColor, bool isDark) {
    return Container(
      height: 33,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _periodButton("週", 0, textColor),
          _periodButton("月", 1, textColor),
          _periodButton("年", 2, textColor),
        ],
      ),
    );
  }

  Widget _periodButton(String title, int index, Color textColor) {
    final selected = selectedPeriod == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedPeriod = index;
            // 週・月・年を切りかえたら、今の期間にもどす
            _offset = 0;
          });
        },
        child: Container(
          margin: const EdgeInsets.all(2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: selected ? Colors.white : textColor,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // 吹き出し（押している組の期間・あなた・全体平均・平均との差）
  // 見た目は前のグラフの部品の吹き出しと同じ（うすい青。色は app_colors.dart の tooltip〜）
  // ==============================================================
  Widget _buildTouchTooltip(
    int groupIndex,
    List<_Bucket> buckets,
    List<int> mySeconds,
    List<int> averageSeconds,
    bool isDark,
  ) {
    final label = buckets[groupIndex].label.replaceAll("\n", " ");

    final textColor = isDark
        ? AppColors.tooltipTextDark
        : AppColors.tooltipText;
    final subColor = isDark
        ? AppColors.tooltipSubTextDark
        : AppColors.tooltipSubText;

    final mine = mySeconds[groupIndex];
    final average = averageSeconds[groupIndex];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.tooltipBackgroundDark
            : AppColors.tooltipBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.tooltipBorderDark : AppColors.tooltipBorder,
        ),
      ),
      child: Text.rich(
        TextSpan(
          text: "$label\n",
          style: TextStyle(color: subColor, fontSize: 11, height: 1.5),
          children: [
            TextSpan(
              text: "あなた  ${_formatTooltipTime(mine)}",
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
            ),
            if (_showOther) ...[
              TextSpan(
                text: "\n$_otherLabel  ${_formatTooltipTime(average)}",
                style: TextStyle(color: subColor, fontSize: 12, height: 1.5),
              ),
              TextSpan(
                text: "\n${_differenceText(mine, average)}",
                style: TextStyle(
                  // 平均より多いときは濃い青、少ないときはうすめの青
                  color: mine >= average ? textColor : subColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ==============================================================
  // グラフ
  // ==============================================================

  BarChartData _createChart(
    List<_Bucket> buckets,
    List<int> mySeconds,
    List<int> averageSeconds,
    bool isDark,
  ) {
    final allSeconds = [...mySeconds, if (_showOther) ...averageSeconds];

    final maxSeconds = allSeconds.isEmpty
        ? 0
        : allSeconds.reduce((a, b) => a > b ? a : b);

    // いちばん長い棒が1時間未満なら「分」、それ以外は「時間」の目盛り
    final useMinutes = maxSeconds < 3600;
    final secondsPerUnit = useMinutes ? 60 : 3600;
    final maxValue = maxSeconds / secondsPerUnit;

    double maxY;

    if (useMinutes) {
      maxY = [
        5.0,
        10.0,
        15.0,
        30.0,
        60.0,
      ].firstWhere((candidate) => maxValue <= candidate, orElse: () => 60.0);
    } else {
      maxY = maxValue <= 5 ? 5.0 : (maxValue / 5).ceil() * 5.0;
    }

    final interval = maxY / 5;
    final unitLabel = useMinutes ? "分" : "時間";

    final currentIndex = _currentIndex(buckets);

    final gridColor = isDark ? Colors.white12 : AppColors.divider;
    final secondaryColor = isDark ? Colors.white70 : const Color(0xFF666666);

    // 年は棒が12組あるので細くする
    final rodWidth = selectedPeriod == 2 ? 7.0 : (_showOther ? 11.0 : 18.0);

    return BarChartData(
      maxY: maxY,
      minY: 0,

      barTouchData: BarTouchData(
        enabled: true,

        // 押している組と位置を覚える
        // （その組の「あなた」の棒を濃くし、押した位置の少し上に吹き出しを出す。指を離すと消える）
        touchCallback: (event, response) {
          final index = event.isInterestedForInteractions
              ? (response?.spot?.touchedBarGroupIndex ?? -1)
              : -1;

          final position = index >= 0 ? event.localPosition : null;

          if (index != _touchedIndex || position != _touchPosition) {
            setState(() {
              _touchedIndex = index;
              _touchPosition = position;
            });
          }
        },

        // 吹き出しは、グラフの部品のものではなく、押した位置の少し上に自分で出す
        // （_buildTouchTooltip。グラフの部品の吹き出しは棒のてっぺんにしか出せないため）
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) => null,
        ),
      ),

      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: gridColor, strokeWidth: 1),
      ),

      borderData: FlBorderData(show: false),

      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: _leftAxisWidth,
            interval: interval,
            getTitlesWidget: (value, meta) {
              final number = value == value.roundToDouble()
                  ? value.toInt().toString()
                  : value.toStringAsFixed(1);

              // いちばん上の目盛りには単位（分・時間）を出す
              final text = value == meta.max ? unitLabel : number;

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  text,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 10, color: secondaryColor),
                ),
              );
            },
          ),
        ),

        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();

              if (index < 0 || index >= buckets.length) {
                return const SizedBox();
              }

              // 週のグラフだけ、土曜は青・日曜は赤にする（月曜はじまり）
              Color labelColor = secondaryColor;
              if (selectedPeriod == 0 && index == 5) {
                labelColor = AppColors.primary;
              } else if (selectedPeriod == 0 && index == 6) {
                labelColor = const Color(0xFFE5534B);
              }

              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  buckets[index].label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: labelColor),
                ),
              );
            },
          ),
        ),

        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),

        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),

      barGroups: List.generate(buckets.length, (index) {
        // 今の日・週・月の「あなた」の棒だけ濃い青
        final isCurrent = index == currentIndex || index == _touchedIndex;

        return BarChartGroupData(
          x: index,
          barsSpace: 3,
          barRods: [
            BarChartRodData(
              toY: mySeconds[index] / secondsPerUnit,
              width: rodWidth,
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: isCurrent
                    ? const [AppColors.primaryDeep, AppColors.primaryLight]
                    : const [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            if (_showOther)
              BarChartRodData(
                toY: averageSeconds[index] / secondsPerUnit,
                width: rodWidth,
                color: isDark ? Colors.white38 : _averageColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
          ],
        );
      }),
    );
  }

  // ==============================================================
  // 共通
  // ==============================================================

  Widget _summaryItem(
    String title,
    String value,
    Color valueColor,
    Color secondaryColor, {
    required double numberSize,
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: secondaryColor, fontSize: 12),
        ),
        const SizedBox(height: 2),
        _timeText(value, valueColor, numberSize),
      ],
    );
  }

  // 「23分」「1時間5分」を、数字は Roboto で大きく、単位は小さく出す
  Widget _timeText(String value, Color color, double numberSize) {
    // 「120.5時間」のような小数も、ひとかたまりの数字として出す
    final spans = RegExp(r'(\d+(?:\.\d+)?)(時間|分|秒)').allMatches(value).expand((
      m,
    ) {
      return [
        TextSpan(
          text: m.group(1),
          style: GoogleFonts.roboto(
            color: color,
            fontSize: numberSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: m.group(2),
          style: TextStyle(
            color: color,
            fontSize: numberSize * 0.56,
            fontWeight: FontWeight.bold,
          ),
        ),
      ];
    }).toList();

    return RichText(text: TextSpan(children: spans));
  }

  Widget _card(Color color, bool isDark, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : AppColors.border),
      ),
      child: child,
    );
  }

  Widget _legend(Color color, String text, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: textColor),
          ),
        ),
      ],
    );
  }
}
