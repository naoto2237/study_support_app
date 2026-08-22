// home_screen2.dart

import 'package:flutter/material.dart';
import 'goaltime_setting_screen.dart';

class WeekdayGoalButton extends StatelessWidget {
  const WeekdayGoalButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 18),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GoaltimeSettingScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF258EDB), width: 1.2),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFF258EDB),
                size: 25,
              ),

              SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '曜日ごとの目標を設定',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '曜日ごとに目標時間をカスタマイズできます',
                      style: TextStyle(fontSize: 11.5, color: Colors.black54),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF258EDB),
                size: 27,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
