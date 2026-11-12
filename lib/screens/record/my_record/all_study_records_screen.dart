// ======================================================================
// 【画面】学習記録の全件一覧（新しい順・月ごとにまとめる）
//
// 主なクラス: AllStudyRecordsScreen
// 開き方: 最近の学習記録（recent_records_section.dart）
// ======================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_support_app/main.dart' show todayStudySeconds;
import 'package:study_support_app/screens/record/my_record/study_record_row.dart';
import 'package:study_support_app/theme/app_colors.dart';

class AllStudyRecordsScreen extends StatefulWidget {
  final String userId;
  final Color cardColor;
  final Color textColor;
  final Color secondaryColor;

  const AllStudyRecordsScreen({
    super.key,
    required this.userId,
    required this.cardColor,
    required this.textColor,
    required this.secondaryColor,
  });

  @override
  State<AllStudyRecordsScreen> createState() => _AllStudyRecordsScreenState();
}

class _AllStudyRecordsScreenState extends State<AllStudyRecordsScreen> {
  // Firestore に保存済みの記録（新しい順）
  List<Map<String, dynamic>> savedRecords = [];

  bool isLoading = true;

  // Firestore の変更を受け取り続けるための購読
  // （タイマーを止めて保存されたら、開きなおさなくても一覧が変わる）
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  @override
  void initState() {
    super.initState();
    _listenRecords();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _listenRecords() {
    if (widget.userId.isEmpty) {
      isLoading = false;
      return;
    }

    _subscription = FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .collection("studyRecords")
        .snapshots()
        .listen(
          (snapshot) {
            final loadedRecords = snapshot.docs.map((doc) {
              final data = doc.data();

              return <String, dynamic>{
                "date": doc.id,
                "studyTime": (data["studyTime"] as num?)?.toInt() ?? 0,
              };
            }).toList();

            // 文書のIDは "2026-11-12" の形なので、文字の順＝日付の順。
            // 新しい順に並べる
            loadedRecords.sort(
              (a, b) => (b["date"] as String).compareTo(a["date"] as String),
            );

            if (!mounted) return;

            setState(() {
              savedRecords = loadedRecords;
              isLoading = false;
            });
          },
          onError: (e) {
            debugPrint("学習記録一覧の取得に失敗しました: $e");

            if (!mounted) return;

            setState(() {
              isLoading = false;
            });
          },
        );
  }

  String _todayId() {
    final now = DateTime.now();

    return "${now.year.toString().padLeft(4, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";
  }

  // 表示する一覧
  // ・今日の行は、タイマーの今の値（todayStudySeconds）を使う
  // ・今日の記録がまだ保存されていなくても、勉強中なら先頭に出す
  List<Map<String, dynamic>> _records(int todaySeconds) {
    final todayId = _todayId();

    final records = <Map<String, dynamic>>[
      ...savedRecords.where((record) => record["date"] != todayId),
    ];

    final savedToday = savedRecords.any((record) => record["date"] == todayId);

    if (savedToday || todaySeconds > 0) {
      records.insert(0, <String, dynamic>{
        "date": todayId,
        "studyTime": todaySeconds,
      });
    }

    return records;
  }

  @override
  Widget build(BuildContext context) {
    // 今日の学習時間が変わるたびに描き直す
    return ValueListenableBuilder<int>(
      valueListenable: todayStudySeconds,
      builder: (context, todaySeconds, child) {
        return _buildScreen(_records(todaySeconds));
      },
    );
  }


  // 記録を月ごとに分ける（新しい月が上）
  List<MapEntry<String, List<Map<String, dynamic>>>> _groupByMonth(
    List<Map<String, dynamic>> records,
  ) {
    final groups = <String, List<Map<String, dynamic>>>{};

    for (final record in records) {
      // "2026-11-12" → "2026-11"
      final monthKey = (record["date"] as String).substring(0, 7);
      groups.putIfAbsent(monthKey, () => []).add(record);
    }

    return groups.entries.toList();
  }

  Widget _buildScreen(List<Map<String, dynamic>> records) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF121212)
        : AppColors.background;

    final months = _groupByMonth(records);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Transform.translate(
          offset: const Offset(-18, 0),
          child: const Text(
            "学習記録の一覧",
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: widget.cardColor,
        foregroundColor: widget.textColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : records.isEmpty
          ? Center(
              child: Text(
                "まだ学習記録がありません",
                style: TextStyle(color: widget.secondaryColor, fontSize: 14),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              itemCount: months.length,
              itemBuilder: (context, index) {
                final month = months[index];

                return _monthCard(month.key, month.value, isDark);
              },
            ),
    );
  }

  // 1か月分のカード（上に「2026年11月」と月の合計、下に日ごとの行）
  Widget _monthCard(
    String monthKey,
    List<Map<String, dynamic>> records,
    bool isDark,
  ) {
    final year = monthKey.substring(0, 4);
    final month = int.parse(monthKey.substring(5, 7));

    int totalSeconds = 0;
    int maxSeconds = 0;

    for (final record in records) {
      final seconds = (record["studyTime"] as num?)?.toInt() ?? 0;
      totalSeconds += seconds;
      if (seconds > maxSeconds) maxSeconds = seconds;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                "$year年$month月",
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                "合計 ",
                style: TextStyle(color: widget.secondaryColor, fontSize: 12),
              ),
              Text(
                StudyRecordRow.formatStudyTime(totalSeconds),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          ...records.asMap().entries.map((entry) {
            final record = entry.value;

            return StudyRecordRow(
              dateId: record["date"] as String,
              seconds: (record["studyTime"] as num?)?.toInt() ?? 0,
              maxSeconds: maxSeconds,
              textColor: widget.textColor,
              secondaryColor: widget.secondaryColor,
              showDivider: entry.key != records.length - 1,
            );
          }),
        ],
      ),
    );
  }
}
