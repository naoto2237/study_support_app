import 'package:flutter/material.dart';

class RecordMyRecordScreen3 extends StatelessWidget {
  final Color cardColor;
  final Color textColor;
  final Color secondaryColor;
  final double weeklyStudyHours;
  final double weeklyGoalHours;
  final int achievementRate;

  const RecordMyRecordScreen3({
    super.key,
    required this.cardColor,
    required this.textColor,
    required this.secondaryColor,
    required this.weeklyStudyHours,
    required this.weeklyGoalHours,
    required this.achievementRate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildGoalCard(),
        const SizedBox(height: 14),
        _buildReflectionCard(),
        const SizedBox(height: 14),
        _buildRecentRecords(),
      ],
    );
  }

  Widget _buildGoalCard() {
    return _card(
      Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFEDE7FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.track_changes,
              color: Color(0xFF258EDB),
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "週間目標",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "今週の目標合計",
                  style: TextStyle(color: secondaryColor, fontSize: 12),
                ),
                Text(
                  "${weeklyGoalHours.toStringAsFixed(1)} 時間",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 65, color: Colors.grey.shade300),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "達成率",
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "$achievementRate %",
                style: TextStyle(
                  color: textColor,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 105,
                child: LinearProgressIndicator(
                  value: achievementRate / 100,
                  minHeight: 7,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF258EDB)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReflectionCard() {
    return _card(
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE7FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.article_outlined, color: Color(0xFF258EDB)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "学習のふりかえり",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  "今週は合計 "
                  "${weeklyStudyHours.toStringAsFixed(1)} "
                  "時間学習しました！",
                  style: TextStyle(color: textColor, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  "目標まであと "
                  "${(weeklyGoalHours - weeklyStudyHours).clamp(0, double.infinity).toStringAsFixed(1)} "
                  "時間です。もう少しで達成できます！",
                  style: TextStyle(color: secondaryColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "すべて見る  ›",
                style: TextStyle(color: secondaryColor, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _recordItem("8/22（土）", "数学 / 微分積分", "1.5時間"),
          _recordItem("8/21（金）", "英語 / 単語暗記", "1.0時間"),
          _recordItem("8/20（木）", "物理 / 力学", "1.2時間"),
        ],
      ),
    );
  }

  Widget _recordItem(String date, String subject, String time) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(
              date,
              style: TextStyle(color: secondaryColor, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              subject,
              style: TextStyle(color: textColor, fontSize: 13),
            ),
          ),
          Text(time, style: TextStyle(color: textColor, fontSize: 13)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: secondaryColor, size: 20),
        ],
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}
