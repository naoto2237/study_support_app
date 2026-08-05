import 'package:flutter/material.dart';
import 'aihistory_chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ai_screen.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        title: Transform.translate(
          offset: const Offset(-19, 0),
          child: const Text(
            "履歴",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("履歴を削除"),
                    content: const Text("すべての履歴を削除しますか？"),
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
            return const Center(child: Text("履歴を読み込めませんでした"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("履歴はありません", style: TextStyle(fontSize: 16)),
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
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEAF4FF),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                  title: Text(
                    data['title'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AiHistoryChatScreen(chatId: docs[index].id),
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
