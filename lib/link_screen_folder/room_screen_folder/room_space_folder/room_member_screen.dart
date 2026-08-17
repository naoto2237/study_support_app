import 'package:flutter/material.dart';

class RoomMemberScreen extends StatelessWidget {
  const RoomMemberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: const [
          MemberTile(name: "A", time: "00:15:32", studying: true),

          SizedBox(height: 10),

          MemberTile(name: "B", time: "01:05:18", studying: true),

          SizedBox(height: 10),

          MemberTile(name: "C", time: "01:42:18", studying: true),

          SizedBox(height: 10),

          MemberTile(name: "D", time: "休憩中", studying: false),
        ],
      ),
    );
  }
}

class MemberTile extends StatelessWidget {
  final String name;
  final String time;
  final bool studying;

  const MemberTile({
    super.key,
    required this.name,
    required this.time,
    required this.studying,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFFEAF4FF),
              child: Icon(Icons.person, color: Color(0xFF258EDB)),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "今日 $time",
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: studying
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                studying ? "勉強中" : "休憩中",
                style: TextStyle(
                  color: studying ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
