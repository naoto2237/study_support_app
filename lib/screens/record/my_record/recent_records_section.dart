// ======================================================================
// 【部品】最近の学習記録（新しい順に3件）
//
// 主なクラス: RecentRecordsSection
// 表示される場所: 学習時間グラフの下／マイページ
// ・「すべて見る」で全件の一覧（all_study_records_screen.dart）へ
// ・旧ファイル名: record_myrecord_screen3.dart
// ======================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:study_support_app/theme/app_palette.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_support_app/main.dart' show todayStudySeconds;
import 'package:study_support_app/screens/record/my_record/all_study_records_screen.dart';
import 'package:study_support_app/screens/record/my_record/study_record_row.dart';

class RecentRecordsSection extends StatefulWidget {
  final Color cardColor;
  final Color textColor;
  final Color secondaryColor;
  final String userId;

  const RecentRecordsSection({
    super.key,
    required this.cardColor,
    required this.textColor,
    required this.secondaryColor,
    required this.userId,
  });

  @override
  State<RecentRecordsSection> createState() => _RecentRecordsSectionState();
}

class _RecentRecordsSectionState extends State<RecentRecordsSection> {
  // Firestore に保存済みの記録（新しい順）
  List<Map<String, dynamic>> savedRecords = [];

  bool isLoading = true;

  // Firestore の変更を受け取り続けるための購読
  // （タイマーを止めて保存されたら、開きなおさなくても一覧が変わる）
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  @override
  void initState() {
    super.initState();
    _listenRecentRecords();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _listenRecentRecords() {
    if (widget.userId.isEmpty) {
      isLoading = false;
      return;
    }

    // 並べかえはアプリの中で行う。
    // （Firestore に「新しい順」で頼むと、索引（インデックス）が必要になるため）
    _subscription = FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .collection("studyRecords")
        .snapshots()
        .listen(
          (snapshot) {
            final records = snapshot.docs.map((doc) {
              final data = doc.data();

              return <String, dynamic>{
                "date": doc.id,
                "studyTime": (data["studyTime"] as num?)?.toInt() ?? 0,
              };
            }).toList();

            // 文書のIDは "2026-11-12" の形なので、文字の順＝日付の順。
            // 新しい順に並べる
            records.sort(
              (a, b) => (b["date"] as String).compareTo(a["date"] as String),
            );

            if (!mounted) return;

            setState(() {
              savedRecords = records;
              isLoading = false;
            });
          },
          onError: (e) {
            debugPrint("最近の学習記録の取得に失敗しました: $e");

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

  // 表示する3件
  // ・今日の行は、タイマーの今の値（todayStudySeconds）を使う
  // ・今日の記録がまだ保存されていなくても、勉強中なら先頭に出す
  List<Map<String, dynamic>> _recentRecords(int todaySeconds) {
    final todayId = _todayId();

    // 今日の行は下で入れなおすので、ここでは除く（多くても4件あれば足りる）
    final records = <Map<String, dynamic>>[
      ...savedRecords.where((record) => record["date"] != todayId).take(3),
    ];

    final savedToday = savedRecords.any((record) => record["date"] == todayId);

    if (savedToday || todaySeconds > 0) {
      records.insert(0, <String, dynamic>{
        "date": todayId,
        "studyTime": todaySeconds,
      });
    }

    return records.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    // 今日の学習時間が変わるたびに描き直す
    return ValueListenableBuilder<int>(
      valueListenable: todayStudySeconds,
      builder: (context, todaySeconds, child) {
        return _buildRecentRecords(_recentRecords(todaySeconds));
      },
    );
  }

  Widget _buildRecentRecords(List<Map<String, dynamic>> recentRecords) {
    // バーの長さの基準（並んでいる中でいちばん長い日）
    final maxSeconds = recentRecords.fold<int>(0, (max, record) {
      final seconds = (record["studyTime"] as num?)?.toInt() ?? 0;
      return seconds > max ? seconds : max;
    });

    return _card(
      Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "最近の学習記録",
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllStudyRecordsScreen(
                        cardColor: widget.cardColor,
                        textColor: widget.textColor,
                        secondaryColor: widget.secondaryColor,
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "すべて見る",
                      style: TextStyle(
                        color: widget.secondaryColor,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 1),
                    Icon(
                      Icons.chevron_right,
                      color: widget.secondaryColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (recentRecords.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "まだ学習記録がありません",
                style: TextStyle(color: widget.secondaryColor, fontSize: 13),
              ),
            )
          else
            ...recentRecords.asMap().entries.map((entry) {
              final index = entry.key;
              final record = entry.value;
              final studyTime = (record["studyTime"] as num?)?.toInt() ?? 0;

              return StudyRecordRow(
                dateId: record["date"] as String,
                seconds: studyTime,
                maxSeconds: maxSeconds,
                textColor: widget.textColor,
                secondaryColor: widget.secondaryColor,
                showDivider: index != recentRecords.length - 1,
              );
            }),
        ],
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        18, // 左
        18, // 上
        18, // 右
        10, // 下
      ),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.pal.border),
      ),
      child: child,
    );
  }
}
