import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'all_study_records_screen.dart';

class RecordMyRecordScreen3 extends StatefulWidget {
  final Color cardColor;
  final Color textColor;
  final Color secondaryColor;

  const RecordMyRecordScreen3({
    super.key,
    required this.cardColor,
    required this.textColor,
    required this.secondaryColor,
  });

  @override
  State<RecordMyRecordScreen3> createState() => _RecordMyRecordScreen3State();
}

class _RecordMyRecordScreen3State extends State<RecordMyRecordScreen3> {
  List<Map<String, dynamic>> recentRecords = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentRecords();
  }

  Future<void> _loadRecentRecords() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("studyRecords")
          .get();

      final records = snapshot.docs.map((doc) {
        final data = doc.data();

        return {
          "date": doc.id,
          "studyTime": (data["studyTime"] as num?)?.toInt() ?? 0,
        };
      }).toList();

      // 日付が新しい順に並べる
      records.sort((a, b) {
        final dateA = DateTime.parse(
          a["date"] as String,
        );

        final dateB = DateTime.parse(
          b["date"] as String,
        );

        return dateB.compareTo(dateA);
      });

      // 最新3件だけ
      final latestRecords = records.take(3).toList();

      if (!mounted) return;

      setState(() {
        recentRecords = latestRecords;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("最近の学習記録の取得に失敗しました: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildRecentRecords();
  }

  Widget _buildRecentRecords() {
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

          const SizedBox(height: 10),

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

              return _recordItem(
                _formatDate(record["date"] as String),
                "未設定",
                _formatStudyTime(studyTime),
                showDivider: index != recentRecords.length - 1,
              );
            }),
        ],
      ),
    );
  }

  Widget _recordItem(
    String date,
    String subject,
    String time, {
    bool showDivider = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: showDivider
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            )
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(
              date,
              style: TextStyle(color: widget.secondaryColor, fontSize: 12),
            ),
          ),

          Expanded(
            child: Text(
              subject,
              style: TextStyle(color: widget.textColor, fontSize: 13),
            ),
          ),

          Text(time, style: TextStyle(color: widget.textColor, fontSize: 13)),

         // const SizedBox(width: 4),

        //  Icon(Icons.chevron_right, color: widget.secondaryColor, size: 20),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    final dateTime = DateTime.parse(date);

    const weekdays = [
      "月",
      "火",
      "水",
      "木",
      "金",
      "土",
      "日",
    ];

    return "${dateTime.month}/${dateTime.day}"
        "（${weekdays[dateTime.weekday - 1]}）";
  }


  String _formatStudyTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      if (minutes > 0) {
        return "$hours時間$minutes分";
      }

      return "$hours時間";
    }

    return "$minutes分";
  }

  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }
}
