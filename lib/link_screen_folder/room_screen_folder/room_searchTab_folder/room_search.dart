import 'package:flutter/material.dart';
import '../room_space_folder/room_space.dart';

class SearchRoomTab extends StatelessWidget {
  const SearchRoomTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF7F7F7);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final subtitleColor = isDark ? Colors.white60 : Colors.grey;

    return Container(
      color: bgColor,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 検索バー
          TextField(
            style: TextStyle(color: textColor),
            cursorColor: const Color(0xFF3D96E8),
            decoration: InputDecoration(
              hintText: "ルーム名・資格名で検索",
              hintStyle: TextStyle(color: subtitleColor),
              prefixIcon: Icon(Icons.search, color: subtitleColor),
              filled: true,
              fillColor: cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.transparent,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.transparent,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFF3D96E8),
                  width: 2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 絞り込みボタン
          SizedBox(
            height: 45,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: 絞り込み画面
              },
              icon: const Icon(Icons.filter_list),
              label: const Text("絞り込み"),
              style: ElevatedButton.styleFrom(
                backgroundColor: cardColor,
                foregroundColor: const Color(0xFF3D96E8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(
                    color: isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          Text(
            "公開ルーム",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),

          const SizedBox(height: 15),

          const PublicRoomCard(
            title: "基本情報技術者",
            members: "35人",
            roomId: "basic_info",
          ),

          const SizedBox(height: 15),

          const PublicRoomCard(
            title: "TOEIC 800点",
            members: "20人",
            roomId: "toeic_800",
          ),

          const SizedBox(height: 15),

          const PublicRoomCard(
            title: "簿記2級",
            members: "18人",
            roomId: "bookkeeping_2",
          ),

          const SizedBox(height: 15),

          const PublicRoomCard(
            title: "応用情報技術者",
            members: "41人",
            roomId: "applied_info",
          ),
        ],
      ),
    );
  }
}

class PublicRoomCard extends StatelessWidget {
  final String title;
  final String members;
  final String roomId;

  const PublicRoomCard({
    super.key,
    required this.title,
    required this.members,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor =
    isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final textColor =
    isDark ? Colors.white70 : Colors.black87;

    final subtitleColor =
    isDark ? Colors.white60 : Colors.grey;

    final borderColor =
    isDark
        ? Colors.grey.shade800
        : const Color(0xFFE5E7EB);

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: isDark
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.green.shade100,
              child: const Icon(
                Icons.groups,
                color: Colors.green,
              ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: subtitleColor,
                      ),

                      const SizedBox(width: 5),

                      Text(
                        members,
                        style: TextStyle(
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                // ============================
                // ルームに入る確認
                // ============================
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: cardColor,

                      title: Text(
                        "ルームに入る",
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      content: Text(
                        "「$title」に入りますか？",
                        style: TextStyle(
                          color: subtitleColor,
                        ),
                      ),

                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, false);
                          },
                          child: Text(
                            "キャンセル",
                            style: TextStyle(
                              color: subtitleColor,
                            ),
                          ),
                        ),

                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            const Color(0xFF3D96E8),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("入る"),
                        ),
                      ],
                    );
                  },
                );

                // ============================
                // 「入る」が押された場合
                // ============================
                if (result == true) {
                  if (!context.mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoomSpaceScreen(
                        roomTitle: title,
                        roomId: roomId,
                      ),
                    ),
                  );
                }
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D96E8),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              child: const Text("参加"),
            ),
          ],
        ),
      ),
    );
  }
}
