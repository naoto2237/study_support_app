import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90E2),
        ),
      ),
      home: const QnAListPage(),
    );
  }
}

// =========================
// モデル
// =========================

class Reply {
  String userName;
  String text;

  Reply({required this.userName, required this.text});
}

class Answer {
  String userName;
  String text;
  List<Reply> replies;

  Answer({
    required this.userName,
    required this.text,
    List<Reply>? replies,
  }) : replies = replies ?? [];
}

class Question {
  String content;
  String userName;
  List<Answer> answers;

  Question({
    required this.content,
    required this.userName,
    List<Answer>? answers,
  }) : answers = answers ?? [];
}

// =========================
// 一覧
// =========================

class QnAListPage extends StatefulWidget {
  const QnAListPage({super.key});

  @override
  State<QnAListPage> createState() => _QnAListPageState();
}

class _QnAListPageState extends State<QnAListPage> {
  final Color primaryColor = const Color(0xFF4A90E2);
  final TextEditingController searchController = TextEditingController();

  List<Question> questions = [];
  String keyword = "";

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();

    final data = questions.map((q) {
      return {
        "content": q.content,
        "userName": q.userName,
        "answers": q.answers.map((a) {
          return {
            "userName": a.userName,
            "text": a.text,
            "replies": a.replies
                .map((r) => {
              "userName": r.userName,
              "text": r.text,
            })
                .toList(),
          };
        }).toList(),
      };
    }).toList();

    await prefs.setString("qna_data", jsonEncode(data));
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString("qna_data");
    if (data == null) return;

    final List decoded = jsonDecode(data);

    setState(() {
      questions = decoded.map((q) {
        return Question(
          content: q["content"],
          userName: q["userName"],
          answers: (q["answers"] as List).map((a) {
            return Answer(
              userName: a["userName"],
              text: a["text"],
              replies: (a["replies"] as List? ?? [])
                  .map((r) => Reply(
                userName: r["userName"],
                text: r["text"],
              ))
                  .toList(),
            );
          }).toList(),
        );
      }).toList();
    });
  }

  List<Question> get filteredQuestions {
    if (keyword.isEmpty) return questions;

    return questions
        .where((q) =>
    q.content.contains(keyword) || q.userName.contains(keyword))
        .toList();
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
      saveData();
    }
  }

  void goDetail(Question q) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPage(
          question: q,
          primaryColor: primaryColor,
          onChanged: saveData,
          onDeleteQuestion: () {
            setState(() => questions.remove(q));
            saveData();
            Navigator.pop(context);
          },
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void editQuestion(Question q) {
    final c = TextEditingController(text: q.content);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("質問編集"),
        content: TextField(controller: c),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("キャンセル")),
          ElevatedButton(
            onPressed: () {
              setState(() => q.content = c.text);
              saveData();
              Navigator.pop(context);
            },
            child: const Text("保存"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text("Q&Aアプリ"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: (v) => setState(() => keyword = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "検索",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredQuestions.length,
              itemBuilder: (_, i) {
                final q = filteredQuestions[i];

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryColor,
                      child: Text(
                        q.userName.isNotEmpty ? q.userName[0] : "?",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(q.content),
                    subtitle:
                    Text("${q.userName} ・ 回答 ${q.answers.length}件"),
                    onTap: () => goDetail(q),
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

// =========================
// 投稿
// =========================

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
        foregroundColor: Colors.white,
        title: const Text("質問投稿"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: "名前")),
            TextField(controller: content, decoration: const InputDecoration(labelText: "質問")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: submit, child: const Text("投稿")),
          ],
        ),
      ),
    );
  }
}

// =========================
// 詳細（質問も⋯対応）
// =========================

class DetailPage extends StatefulWidget {
  final Question question;
  final Color primaryColor;
  final VoidCallback onChanged;
  final VoidCallback onDeleteQuestion;

  const DetailPage({
    super.key,
    required this.question,
    required this.primaryColor,
    required this.onChanged,
    required this.onDeleteQuestion,
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
        Answer(userName: answerName.text, text: answerText.text),
      );
    });

    widget.onChanged();
    answerText.clear();
  }

  void editAnswer(Answer a) {
    final c = TextEditingController(text: a.text);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("回答編集"),
        content: TextField(controller: c),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("キャンセル")),
          ElevatedButton(
            onPressed: () {
              setState(() => a.text = c.text);
              widget.onChanged();
              Navigator.pop(context);
            },
            child: const Text("保存"),
          ),
        ],
      ),
    );
  }

  void deleteAnswer(Answer a) {
    setState(() => widget.question.answers.remove(a));
    widget.onChanged();
  }

  void addReply(Answer a) {
    final name = TextEditingController();
    final text = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("返信"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: "名前")),
            TextField(controller: text, decoration: const InputDecoration(labelText: "返信")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("キャンセル")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                a.replies.add(Reply(userName: name.text, text: text.text));
              });

              widget.onChanged();
              Navigator.pop(context);
            },
            child: const Text("送信"),
          ),
        ],
      ),
    );
  }

  void editQuestion() {
    final c = TextEditingController(text: widget.question.content);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("質問編集"),
        content: TextField(controller: c),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("キャンセル")),
          ElevatedButton(
            onPressed: () {
              setState(() => widget.question.content = c.text);
              widget.onChanged();
              Navigator.pop(context);
            },
            child: const Text("保存"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.primaryColor,
        foregroundColor: Colors.white,
        title: const Text("詳細"),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (_) => const [
              PopupMenuItem(value: "edit", child: Text("質問を編集")),
              PopupMenuItem(value: "delete", child: Text("質問を削除")),
            ],
            onSelected: (v) {
              if (v == "edit") editQuestion();
              if (v == "delete") widget.onDeleteQuestion();
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: widget.primaryColor,
                  child: Text(
                    q.userName.isNotEmpty ? q.userName[0] : "?",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text("質問者",
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              q.content,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),

          Expanded(
            child: ListView.builder(
              itemCount: q.answers.length,
              itemBuilder: (_, i) {
                final a = q.answers[i];

                return Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: widget.primaryColor,
                          child: Text(
                            a.userName.isNotEmpty ? a.userName[0] : "?",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(a.text),
                        subtitle: Text(a.userName),
                        trailing: PopupMenuButton(
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: "edit", child: Text("編集")),
                            PopupMenuItem(value: "delete", child: Text("削除")),
                          ],
                          onSelected: (v) {
                            if (v == "edit") editAnswer(a);
                            if (v == "delete") deleteAnswer(a);
                          },
                        ),
                      ),

                      ...a.replies.map((r) => Padding(
                        padding: const EdgeInsets.only(left: 40, bottom: 6),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: widget.primaryColor,
                              child: Text(
                                r.userName.isNotEmpty ? r.userName[0] : "?",
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text("${r.userName}: ${r.text}"),
                            ),
                          ],
                        ),
                      )),

                      TextButton(
                        onPressed: () => addReply(a),
                        child: const Text("返信"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: answerName,
                  decoration: const InputDecoration(labelText: "名前"),
                ),
                TextField(
                  controller: answerText,
                  decoration: const InputDecoration(labelText: "回答"),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: addAnswer,
                    child: const Text("回答"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}