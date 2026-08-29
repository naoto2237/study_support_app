import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_support_app/notification_screen_folder/notification_screen.dart';

// アプリの動作確認用 main（必要に応じて既存のmainと統合してください）
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3D96E8)),
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
  String userId;

  Reply({required this.userName, required this.text, required this.userId});

  Map<String, dynamic> toMap() => {
    "userName": userName,
    "text": text,
    "userId": userId,
  };

  factory Reply.fromMap(Map<String, dynamic> map) {
    return Reply(
      userName: map["userName"] ?? "名無し",
      text: map["text"] ?? "",
      userId: map["userId"] ?? "",
    );
  }
}

class Answer {
  String id;
  String userName;
  String text;
  String userId;
  List<Reply> replies;

  Answer({
    required this.id,
    required this.userName,
    required this.text,
    required this.userId,
    List<Reply>? replies,
  }) : replies = replies ?? [];

  factory Answer.fromMap(String id, Map<String, dynamic> map) {
    var rawReplies = map["replies"] as List? ?? [];
    List<Reply> parsedReplies = rawReplies
        .map((r) => Reply.fromMap(r as Map<String, dynamic>))
        .toList();

    return Answer(
      id: id,
      userName: map["userName"] ?? "名無し",
      text: map["text"] ?? "",
      userId: map["userId"] ?? "",
      replies: parsedReplies,
    );
  }
}

class Question {
  String id;
  String content;
  String userName;
  String userId;
  List<Answer> answers;

  Question({
    required this.id,
    required this.content,
    required this.userName,
    required this.userId,
    List<Answer>? answers,
  }) : answers = answers ?? [];

  factory Question.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    var rawAnswers = data["answers"] as List? ?? [];
    List<Answer> parsedAnswers = rawAnswers.map((a) {
      final map = a as Map<String, dynamic>;
      return Answer.fromMap(map["id"] ?? "", map);
    }).toList();

    return Question(
      id: doc.id,
      content: data["content"] ?? "",
      userName: data["userName"] ?? "名無し",
      userId: data["userId"] ?? "",
      answers: parsedAnswers,
    );
  }
}

// =========================
// 一覧画面
// =========================

class QnAListPage extends StatefulWidget {
  const QnAListPage({super.key});

  @override
  State<QnAListPage> createState() => _QnAListPageState();
}

class _QnAListPageState extends State<QnAListPage> {
  final Color primaryColor = const Color(0xFF3D96E8);
  final TextEditingController searchController = TextEditingController();
  String keyword = "";

  // マイページのユーザー名を取得するヘルパー関数
  Future<String> _getCurrentUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "ゲスト";

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc.data()!["name"] != null) {
        return userDoc.data()!["name"];
      }
    } catch (_) {}
    return "名前未設定";
  }

  // 質問投稿画面へ遷移
  Future<void> goPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("ログインしていません")));
      return;
    }

    // マイページの名前を自動取得
    final currentUserName = await _getCurrentUserName();

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => PostPage(primaryColor: primaryColor)),
    );

    if (result != null && result.isNotEmpty) {
      // Firestoreに質問を追加（マイページの名前をそのまま保存）
      await FirebaseFirestore.instance.collection("questions").add({
        "content": result,
        "userName": currentUserName,
        "userId": user.uid,
        "answers": [],
        "createdAt": FieldValue.serverTimestamp(),
      });
    }
  }

  void goDetail(Question q) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPage(question: q, primaryColor: primaryColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.white,

        title: Transform.translate(
          offset: const Offset(-19, 0),
          child: const Text(
            "Q&A",
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: IconButton(
              icon: Icon(Icons.notifications_none, color: Colors.black87),
              // 通知画面へ
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("questions")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("データの取得に失敗しました"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("質問はまだありません"));
                }

                final questions = snapshot.data!.docs
                    .map((doc) => Question.fromFirestore(doc))
                    .toList();

                final filteredQuestions = questions.where((q) {
                  if (keyword.isEmpty) return true;
                  return q.content.contains(keyword) ||
                      q.userName.contains(keyword);
                }).toList();

                if (filteredQuestions.isEmpty) {
                  return const Center(child: Text("一致する質問が見つかりません"));
                }

                return ListView.builder(
                  itemCount: filteredQuestions.length,
                  itemBuilder: (_, i) {
                    final q = filteredQuestions[i];

                    return Card(
                      color: const Color(0xFFF1F8FF),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(
                          color: Color(0xFFE5E7EB), // ← 枠の色
                          width: 1,
                        ),
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: UserIcon(
                          userId: q.userId,
                          userName: q.userName,
                          radius: 20,
                          primaryColor: primaryColor,
                        ),
                        title: Text(q.content),
                        subtitle: Text(
                          "${q.userName} ・ 回答 ${q.answers.length}件",
                        ),
                        onTap: () => goDetail(q),
                      ),
                    );
                  },
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
// 投稿画面（名前入力なし）
// =========================

class PostPage extends StatefulWidget {
  final Color primaryColor;

  const PostPage({super.key, required this.primaryColor});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final content = TextEditingController();

  void submit() {
    if (content.text.isEmpty) return;
    Navigator.pop(context, content.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Transform.translate(
          offset: const Offset(-19, 0),
          child: const Text(
            "質問投稿",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            TextField(
              controller: content,
              decoration: const InputDecoration(
                labelText: "質問内容",
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: submit, child: const Text("投稿")),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================
// 詳細・回答・返信画面
// =========================

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
  final answerText = TextEditingController();

  // マイページのユーザー名を取得するヘルパー
  Future<String> _getCurrentUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "ゲスト";

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc.data()!["name"] != null) {
        return userDoc.data()!["name"];
      }
    } catch (_) {}
    return "名前未設定";
  }

  // 回答追加（名前入力欄なし、マイペの名前を自動使用）
  Future<void> addAnswer() async {
    if (answerText.text.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final currentUserName = await _getCurrentUserName();

    final newAnswer = Answer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userName: currentUserName,
      text: answerText.text,
      userId: user.uid,
    );

    widget.question.answers.add(newAnswer);
    await _updateFirestoreAnswers();

    answerText.clear();
    setState(() {});
  }

  // 回答削除
  Future<void> deleteAnswer(Answer a) async {
    widget.question.answers.remove(a);
    await _updateFirestoreAnswers();
    setState(() {});
  }

  // 返信追加（名前入力欄なし、マイペの名前を自動使用）
  Future<void> addReply(Answer a) async {
    final textController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final currentUserName = await _getCurrentUserName();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("返信"),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(labelText: "返信内容"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("キャンセル"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (textController.text.isNotEmpty) {
                a.replies.add(
                  Reply(
                    userName: currentUserName,
                    text: textController.text,
                    userId: user.uid,
                  ),
                );
                await _updateFirestoreAnswers();
                setState(() {});
              }
              Navigator.pop(context);
            },
            child: const Text("送信"),
          ),
        ],
      ),
    );
  }

  // 質問編集
  Future<void> editQuestion() async {
    final c = TextEditingController(text: widget.question.content);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("質問編集"),
        content: TextField(controller: c),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("キャンセル"),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() => widget.question.content = c.text);
              await FirebaseFirestore.instance
                  .collection("questions")
                  .doc(widget.question.id)
                  .update({"content": c.text});
              Navigator.pop(context);
            },
            child: const Text("保存"),
          ),
        ],
      ),
    );
  }

  // 質問削除
  Future<void> deleteQuestion() async {
    await FirebaseFirestore.instance
        .collection("questions")
        .doc(widget.question.id)
        .delete();
    Navigator.pop(context);
  }

  // Firestoreのanswers配列を更新
  Future<void> _updateFirestoreAnswers() async {
    final dataToSave = widget.question.answers.map((a) {
      return {
        "id": a.id,
        "userName": a.userName,
        "text": a.text,
        "userId": a.userId,
        "replies": a.replies
            .map(
              (r) => {
                "userName": r.userName,
                "text": r.text,
                "userId": r.userId,
              },
            )
            .toList(),
      };
    }).toList();

    await FirebaseFirestore.instance
        .collection("questions")
        .doc(widget.question.id)
        .update({"answers": dataToSave});
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isMyQuestion =
        currentUser != null && q.userId == currentUser.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.primaryColor,
        foregroundColor: Colors.white,
        title: const Text("詳細"),
        actions: [
          if (isMyQuestion)
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (_) => const [
                PopupMenuItem(value: "edit", child: Text("質問を編集")),
                PopupMenuItem(value: "delete", child: Text("質問を削除")),
              ],
              onSelected: (v) {
                if (v == "edit") editQuestion();
                if (v == "delete") deleteQuestion();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                UserIcon(
                  userId: q.userId,
                  userName: q.userName,
                  radius: 20,
                  primaryColor: widget.primaryColor,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "質問者",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
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
                final bool isMyAnswer =
                    currentUser != null && a.userId == currentUser.uid;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: UserIcon(
                          userId: a.userId,
                          userName: a.userName,
                          radius: 20,
                          primaryColor: widget.primaryColor,
                        ),
                        title: Text(a.text),
                        subtitle: Text(a.userName),
                        trailing: isMyAnswer
                            ? PopupMenuButton(
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: "delete",
                                    child: Text("削除"),
                                  ),
                                ],
                                onSelected: (v) {
                                  if (v == "delete") deleteAnswer(a);
                                },
                              )
                            : null,
                      ),
                      ...a.replies.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(
                            left: 40,
                            bottom: 6,
                            right: 12,
                          ),
                          child: Row(
                            children: [
                              UserIcon(
                                userId: r.userId,
                                userName: r.userName,
                                radius: 12,
                                primaryColor: widget.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text("${r.userName}: ${r.text}")),
                            ],
                          ),
                        ),
                      ),
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
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                TextField(
                  controller: answerText,
                  decoration: const InputDecoration(labelText: "回答を入力"),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: addAnswer,
                    child: const Text("回答する"),
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

class UserIcon extends StatelessWidget {
  final String userId;
  final String userName;
  final double radius;
  final Color primaryColor;

  const UserIcon({
    super.key,
    required this.userId,
    required this.userName,
    required this.radius,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return _defaultIcon();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        // 読み込み中
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _defaultIcon();
        }

        // データが存在しない
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _defaultIcon();
        }

        final data = snapshot.data!.data();

        // マイページで保存している「icon」を取得
        final String icon = data?["icon"]?.toString() ?? "";

        // アイコン未設定
        if (icon.isEmpty) {
          return _defaultIcon();
        }

        // マイページと同じ画像を表示
        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.white,
          backgroundImage: NetworkImage(icon),
        );
      },
    );
  }

  Widget _defaultIcon() {
    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFF258EDB).withOpacity(0.12),
      child: const Icon(Icons.person, size: 27, color: Color(0xFF258EDB)),
    );
  }
}
