import 'package:flutter/material.dart';
import 'comparison_screen3.dart';

class ComparisonScreen2 extends StatefulWidget {
  final int totalSeconds;
  final String comparisonTarget;
  final ValueChanged<String> onComparisonTargetChanged;

  const ComparisonScreen2({
    super.key,
    required this.totalSeconds,
    required this.comparisonTarget,
    required this.onComparisonTargetChanged,
  });

  @override
  State<ComparisonScreen2> createState() => _ComparisonScreen2State();
}

class _ComparisonScreen2State extends State<ComparisonScreen2> {
  double get weeklyStudyHours {
    return widget.totalSeconds / 3600.0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final textColor = isDark ? Colors.white : const Color(0xFF202124);

    return Column(
      children: [
        _buildAverageCard(cardColor, textColor),

        const SizedBox(height: 14),

        ComparisonScreen3(
          totalSeconds: widget.totalSeconds,
          comparisonTarget: widget.comparisonTarget,
          onComparisonTargetChanged: widget.onComparisonTargetChanged,
        ),
      ],
    );
  }

  Widget _buildAverageCard(Color cardColor, Color textColor) {
    const averageHours = 8.6;

    final difference = weeklyStudyHours - averageHours;

    return _card(
      cardColor,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "平均との比較",
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(width: 7),

              Text(
                "(今週)",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: _comparisonValue(
                  "自分の学習時間",
                  weeklyStudyHours.toStringAsFixed(1),
                  "時間",
                  const Color(0xFF258EDB),
                ),
              ),

              _divider(),

              Expanded(
                child: _comparisonValue(
                  "平均学習時間",
                  averageHours.toStringAsFixed(1),
                  "時間",
                  textColor,
                ),
              ),

              _divider(),

              Expanded(
                child: _comparisonValue(
                  "差分",
                  "${difference >= 0 ? '+' : ''}"
                      "${difference.toStringAsFixed(1)}",
                  "時間",
                  const Color(0xFFE52B72),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(Color color, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }

  Widget _comparisonValue(
    String title,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11),
        ),

        const SizedBox(height: 10),

        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: " $unit",
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 65, color: Colors.grey.shade300);
  }
}
