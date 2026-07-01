import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}
git
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: QnAListPage(),
    );
  }
}

class Answer {
  final String userName;
  final String text;

  Answer({required this.userName, required this.text});
}

class Question {
  final String content;
  final String userName;
  final List<Answer> answers;

  Question({
    required this.content,
    required this.userName,
    List<Answer>? answers,
  }) : answers = answers ?? [];
}

class QnAListPage extends StatefulWidget {
  const QnAListPage({super.key});

  @override
  State<QnAListPage> createState() => _QnAListPageState();
}

class _QnAListPageState extends State<QnAListPage> {
  final Color primaryColor = const Color(0xFF4A90E2);

  final TextEditingController searchController = TextEditingController();

  final Map<String, String> kanaToEnglish = {
    "ふらった": "flutter",
    "ふらったー": "flutter",
    "だーと": "dart",
    "ふぁいやーべーす": "firebase",
  };

  List<Question> questions = [
    Question(content: "Flutterとは？", userName: "Taro"),
    Question(content: "Dartとは？", userName: "Hanako"),
    Question(content: "Firebaseの使い方", userName: "Jiro"),
  ];

  String keyword = "";

  String normalize(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll('ー', '')
        .replaceAll('ぁ', 'あ')
        .replaceAll('ぃ', 'い')
        .replaceAll('ぅ', 'う')
        .replaceAll('ぇ', 'え')
        .replaceAll('ぉ', 'お')
        .replaceAll('ゃ', 'や')
        .replaceAll('ゅ', 'ゆ')
        .replaceAll('ょ', 'よ')
        .replaceAll('っ', 'つ')
        .replaceAll('ァ', 'あ')
        .replaceAll('ィ', 'い')
        .replaceAll('ゥ', 'う')
        .replaceAll('ェ', 'え')
        .replaceAll('ォ', 'お')
        .replaceAll('ャ', 'や')
        .replaceAll('ュ', 'ゆ')
        .replaceAll('ョ', 'よ')
        .replaceAll('ッ', 'つ');
  }

  String convert(String text) {
    String result = text;

    kanaToEnglish.forEach((key, value) {
      if (result.contains(key)) {
        result = result.replaceAll(key, value);
      }
    });

    return result;
  }

  List<Question> get filteredQuestions {
    if (keyword.isEmpty) return questions;

    final k = normalize(convert(keyword));

    return questions.where((q) {
      final target = normalize(q.content + q.userName);
      return target.contains(k);
    }).toList();
  }

  Future<void> goPost() async {
    final result = await Navigator.push<Question>(
      context,
      MaterialPageRoute(
        builder: (_) => PostPage(primaryColor: primaryColor),
      ),
    );

    if (result != null) {
      setState(() => questions.add(result));
    }
  }

  void goDetail(Question q) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPage(
          question: q,
          primaryColor: primaryColor,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          "Q&Aアプリ",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: primaryColor),
                  hintText: "検索",
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
                onChanged: (v) => setState(() => keyword = v),
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: filteredQuestions.length,
              itemBuilder: (context, index) {
                final q = filteredQuestions[index];

                return Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primaryColor,
                        child: Text(
                          q.userName[0],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        q.content,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle:
                      Text("${q.userName} ・ 回答 ${q.answers.length}件"),
                      trailing: Icon(Icons.arrow_forward_ios,
                          size: 16, color: primaryColor),
                      onTap: () => goDetail(q),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: goPost,
      ),
    );
  }
}

class PostPage extends StatefulWidget {
  final Color primaryColor;

  const PostPage({super.key, required this.primaryColor});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final name = TextEditingController();
  final content = TextEditingController();

  void submit() {
    if (name.text.isEmpty || content.text.isEmpty) return;

    Navigator.pop(
      context,
      Question(content: content.text, userName: name.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.primaryColor,
        title: const Text("質問投稿",
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: "名前"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: content,
              decoration: const InputDecoration(labelText: "質問"),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                ),
                onPressed: submit,
                child: const Text("投稿",
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailPage extends StatefulWidget {
  final Question question;
  final Color primaryColor;

  const DetailPage({
    super.key,
    required this.question,
    required this.primaryColor,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final answerName = TextEditingController();
  final answerText = TextEditingController();

  void addAnswer() {
    if (answerName.text.isEmpty || answerText.text.isEmpty) return;

    setState(() {
      widget.question.answers.add(
        Answer(
          userName: answerName.text,
          text: answerText.text,
        ),
      );
    });

    answerText.clear();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.primaryColor,
        title: const Text("詳細",
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text("質問者",
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              q.content,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const Divider(),

            Expanded(
              child: q.answers.isEmpty
                  ? const Center(child: Text("まだ回答なし"))
                  : ListView(
                children: q.answers.map((a) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: widget.primaryColor,
                        child: const Icon(Icons.person,
                            color: Colors.white),
                      ),
                      title: Text(a.text),
                      subtitle: Text(a.userName),
                    ),
                  );
                }).toList(),
              ),
            ),

            TextField(
              controller: answerName,
              decoration: const InputDecoration(labelText: "名前"),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: answerText,
              decoration: const InputDecoration(labelText: "回答を書く"),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                ),
                onPressed: addAnswer,
                child: const Text("回答",
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}