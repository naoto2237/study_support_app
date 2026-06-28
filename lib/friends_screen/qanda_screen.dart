import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: QnAListPage(),
    );
  }
}

class Question {
  final String title;
  final String content;

  const Question({required this.title, required this.content});
}

class QnAListPage extends StatefulWidget {
  const QnAListPage({super.key});

  @override
  State<QnAListPage> createState() => _QnAListPageState();
}

class _QnAListPageState extends State<QnAListPage> {
  List<Question> questions = const [
    Question(title: "Flutterとは？", content: "UIフレームワーク"),
    Question(title: "Dartとは？", content: "プログラミング言語"),
  ];

  Future<void> _goPostPage() async {
    final result = await Navigator.push<Question>(
      context,
      MaterialPageRoute(builder: (context) => const PostPage()),
    );

    if (result != null) {
      setState(() {
        questions = [...questions, result];
      });
    }
  }

  void _goDetailPage(Question q) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPage(question: q),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Q&A一覧")),

      body: ListView.builder(
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final q = questions[index];

          return ListTile(
            title: Text(q.title),
            subtitle: Text(q.content),
            onTap: () => _goDetailPage(q),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _goPostPage,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("質問投稿")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "タイトル"),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: "内容"),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                if (titleController.text.isEmpty || contentController.text.isEmpty) {
                  return;
                }

                Navigator.pop(
                  context,
                  Question(
                    title: titleController.text,
                    content: contentController.text,
                  ),
                );
              },
              child: const Text("投稿"),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  final Question question;

  const DetailPage({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("質問詳細")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(question.content),
          ],
        ),
      ),
    );
  }
}