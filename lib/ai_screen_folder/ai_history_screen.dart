import 'package:flutter/material.dart';
import 'aihistory_chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AiHistoryScreen extends StatelessWidget {
  const AiHistoryScreen({super.key});

  Future<void> _deleteAllHistory() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('ai_history')
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF7F7F7);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final borderColor = isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bgColor,

      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        title: Transform.translate(
          offset: const Offset(-19, 0),
          child: Text(
            "履歴",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: textColor),
          ),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: IconButton(
              icon: Icon(Icons.delete_outline, color: textColor),
              onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: cardColor,
                    title: Text("履歴を削除", style: TextStyle(color: textColor)),
                    content: Text("すべての履歴を削除しますか？", style: TextStyle(color: textColor)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("キャンセル"),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("削除"),
                      ),
                    ],
                  ),
                );

                if (result == true) {
                  await _deleteAllHistory();
                }
              },
            ),
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ai_history')
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("履歴を読み込めませんでした", style: TextStyle(color: textColor)));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Text("履歴はありません", style: TextStyle(fontSize: 16, color: textColor)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              return Card(
                elevation: 0,
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: borderColor),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isDark ? Colors.blue.withValues(alpha: 0.2) : const Color(0xFFEAF4FF),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: Color(0xFF258EDB),
                    ),
                  ),
                  title: Text(
                    data['title'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textColor),
                  ),
                  trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white60 : Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AiHistoryChatScreen(chatId: docs[index].id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}