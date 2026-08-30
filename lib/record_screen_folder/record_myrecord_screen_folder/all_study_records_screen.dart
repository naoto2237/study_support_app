import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  List<Map<String, dynamic>> records = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    if (widget.userId.isEmpty) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .collection("studyRecords")
          .get();

      final loadedRecords = snapshot.docs.map((doc) {
        final data = doc.data();

        return {
          "date": doc.id,
          "studyTime": (data["studyTime"] as num?)?.toInt() ?? 0,
        };
      }).toList();

      // 新しい日付順
      loadedRecords.sort((a, b) {
        final dateA = DateTime.parse(a["date"] as String);

        final dateB = DateTime.parse(b["date"] as String);

        return dateB.compareTo(dateA);
      });

      if (!mounted) return;

      setState(() {
        records = loadedRecords;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("学習記録一覧の取得に失敗しました: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Transform.translate(
          offset: const Offset(-18, 0),
          child: const Text(
            "最近の学習記録",
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: widget.textColor,
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
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];

                final date = record["date"] as String;

                final studyTime = (record["studyTime"] as num?)?.toInt() ?? 0;

                return _recordCard(date, studyTime);
              },
            ),
    );
  }

  Widget _recordCard(String date, int studyTime) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _formatDate(date),
              style: TextStyle(
                color: widget.textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            _formatStudyTime(studyTime),
            style: TextStyle(
              color: widget.textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    final dateTime = DateTime.parse(date);

    const weekdays = ["月", "火", "水", "木", "金", "土", "日"];

    return "${dateTime.year}/${dateTime.month}/${dateTime.day}"
        "（${weekdays[dateTime.weekday - 1]}）";
  }

  String _formatStudyTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return "$hours時間$minutes分$remainingSeconds秒";
    }

    if (minutes > 0) {
      return "$minutes分$remainingSeconds秒";
    }

    return "$remainingSeconds秒";
  }
}
