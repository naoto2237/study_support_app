// ======================================================================
// 【画面】Q&A（質問の一覧・投稿・詳細・回答・返信）
//
// 主なクラス: QnaListScreen（一覧）/ QnaPostScreen（投稿）/ QnaDetailScreen（詳細）
//           Question / Answer / Reply（データの形）/ UserIcon
// 開き方: Link 画面の「Q&A」
// ・使うデータ: questions, users
// ・旧ファイル名: qanda_screen.dart
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_support_app/screens/notification/notification_screen.dart';
import 'package:study_support_app/theme/app_colors.dart';

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
  // タイトル（タイトル欄を足す前の質問では空）
  String title;
  String content;
  // 投稿した日時（保存される前は null）
  DateTime? createdAt;
  String userName;
  String userId;
  List<Answer> answers;

  Question({
    required this.id,
    this.title = "",
    required this.content,
    this.createdAt,
    required this.userName,
    required this.userId,
    List<Answer>? answers,
  }) : answers = answers ?? [];

  // 一覧や詳細に出すタイトル（タイトルがない古い質問は、内容の1行目）
  String get displayTitle {
    if (title.trim().isNotEmpty) return title.trim();
    return content.trim().split("\n").first;
  }

  // 投稿日時の表示（今日：17:06、昨日：昨日、今年：11/3、去年以前：2025/11/3）
  String get postedAtText {
    final date = createdAt;
    if (date == null) return "たった今";

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;

    if (diff == 0) {
      final h = date.hour.toString().padLeft(2, "0");
      final m = date.minute.toString().padLeft(2, "0");
      return "$h:$m";
    }
    if (diff == 1) return "昨日";
    if (date.year == now.year) return "${date.month}/${date.day}";
    return "${date.year}/${date.month}/${date.day}";
  }

  // タイトルの下に出す本文（タイトルがない古い質問は、内容の2行目以降）
  String get previewBody {
    if (title.trim().isNotEmpty) return content.trim();
    final lines = content.trim().split("\n");
    return lines.skip(1).join("\n").trim();
  }

  factory Question.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    var rawAnswers = data["answers"] as List? ?? [];
    List<Answer> parsedAnswers = rawAnswers.map((a) {
      final map = a as Map<String, dynamic>;
      return Answer.fromMap(map["id"] ?? "", map);
    }).toList();

    return Question(
      id: doc.id,
      title: data["title"] ?? "",
      content: data["content"] ?? "",
      createdAt: (data["createdAt"] as Timestamp?)?.toDate(),
      userName: data["userName"] ?? "名無し",
      userId: data["userId"] ?? "",
      answers: parsedAnswers,
    );
  }
}

// =========================
// 一覧画面
// =========================

class QnaListScreen extends StatefulWidget {
  const QnaListScreen({super.key});

  @override
  State<QnaListScreen> createState() => _QnaListScreenState();
}

class _QnaListScreenState extends State<QnaListScreen> {
  final Color primaryColor = AppColors.primary;
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

    final result = await Navigator.push<({String title, String content})>(
      context,
      MaterialPageRoute(
        builder: (_) => QnaPostScreen(primaryColor: primaryColor),
      ),
    );

    if (result != null && result.content.isNotEmpty) {
      // Firestoreに質問を追加（マイページの名前をそのまま保存）
      await FirebaseFirestore.instance.collection("questions").add({
        "title": result.title,
        "content": result.content,
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
        builder: (_) =>
            QnaDetailScreen(question: q, primaryColor: primaryColor),
      ),
    );
  }

  static const Color _blue = AppColors.primary;

  // 入力欄の×で、文字と絞り込みを消す
  void _clearSearch() {
    searchController.clear();
    setState(() => keyword = "");
  }

  // 質問がないときなどの案内（上のほうに出す）
  Widget _buildMessage({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Align(
      alignment: const Alignment(0, -0.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySoft,
            ),
            child: Icon(icon, color: _blue, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Colors.black45),
            ),
          ],
        ],
      ),
    );
  }

  // 質問1件分のカード（質問の文・名前・回答の数。カード全体を押せる）
  Widget _buildQuestionCard(Question q) {
    final answerCount = q.answers.length;
    final hasAnswer = answerCount > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => goDetail(q),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------------------------------
                // 上：だれの質問か（アイコン・名前）と矢印
                // ------------------------------------------
                Row(
                  children: [
                    UserIcon(
                      userId: q.userId,
                      userName: q.userName,
                      radius: 14,
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(width: 8),
                    // 名前と日時は左に詰め、矢印は右端に置く
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              q.userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                          ),

                          // 投稿した日時
                          Text(
                            "  ・  ${q.postedAtText}",
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: Colors.black26,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ------------------------------------------
                // 中：タイトル（太字）と、内容の最初の2行
                // ------------------------------------------
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    q.displayTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.45,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

                if (q.previewBody.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      q.previewBody,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // ------------------------------------------
                // 下：回答の数（回答があるときは青）
                // ------------------------------------------
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: hasAnswer
                        ? AppColors.primarySoft
                        : const Color(0xFFF2F3F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 14,
                        color: hasAnswer ? _blue : Colors.black38,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "回答 $answerCount件",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: hasAnswer ? _blue : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 丸い入力欄の枠（ふだんは薄い線、入力中は青い線）
    OutlineInputBorder pill(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: width == 0
          ? BorderSide.none
          : BorderSide(color: color, width: width),
    );

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        titleSpacing: 0,

        title: const Text(
          "Q&A",
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black87),
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
          // ==========================================
          // 検索欄（ユーザー検索と同じ丸い形。文字があるときは右に×）
          // ==========================================
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 14, 17, 12),
            child: TextField(
              controller: searchController,
              onChanged: (v) => setState(() => keyword = v),
              style: const TextStyle(fontSize: 15, color: Colors.black87),
              cursorColor: _blue,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: "質問を検索",
                hintStyle: const TextStyle(fontSize: 15, color: Colors.black38),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 14,
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 12, right: 4),
                  child: Icon(Icons.search_rounded, color: Colors.black38),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 44),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: "消す",
                        onPressed: _clearSearch,
                        icon: const Icon(
                          Icons.cancel_rounded,
                          size: 20,
                          color: Colors.black38,
                        ),
                      ),
                // ふだんは枠線なし（白い面だけで浮かせる）。入力中は青い枠
                border: pill(Colors.transparent, 0),
                enabledBorder: pill(Colors.transparent, 0),
                focusedBorder: pill(_blue, 1.5),
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
                  return _buildMessage(
                    icon: Icons.forum_outlined,
                    title: "質問はまだありません",
                    subtitle: "右下の「質問する」から投稿できます",
                  );
                }

                final questions = snapshot.data!.docs
                    .map((doc) => Question.fromFirestore(doc))
                    .toList();

                final filteredQuestions = questions.where((q) {
                  if (keyword.isEmpty) return true;
                  return q.title.contains(keyword) ||
                      q.content.contains(keyword) ||
                      q.userName.contains(keyword);
                }).toList();

                if (filteredQuestions.isEmpty) {
                  return _buildMessage(
                    icon: Icons.search_off_rounded,
                    title: "一致する質問が見つかりません",
                  );
                }

                // 右下のボタンに隠れないよう、下を広めにあける
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(17, 0, 17, 96),
                  itemCount: filteredQuestions.length,
                  itemBuilder: (_, i) =>
                      _buildQuestionCard(filteredQuestions[i]),
                );
              },
            ),
          ),
        ],
      ),

      // 質問する（文字付きの丸いボタン）
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: const StadiumBorder(),
        onPressed: goPost,
        icon: const Icon(Icons.edit_outlined),
        label: const Text(
          "質問する",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// =========================
// 投稿画面（名前入力なし）
// =========================

class QnaPostScreen extends StatefulWidget {
  final Color primaryColor;

  const QnaPostScreen({super.key, required this.primaryColor});

  @override
  State<QnaPostScreen> createState() => _QnaPostScreenState();
}

class _QnaPostScreenState extends State<QnaPostScreen> {
  static const Color _blue = AppColors.primary;

  final title = TextEditingController();
  final content = TextEditingController();

  @override
  void initState() {
    super.initState();

    // 文字数の表示と、ボタンの押せる・押せないを入力に合わせて変える
    title.addListener(() {
      if (mounted) setState(() {});
    });
    content.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    title.dispose();
    content.dispose();
    super.dispose();
  }

  // タイトルと内容の両方が入っているときだけ投稿できる
  void submit() {
    if (title.text.trim().isEmpty || content.text.isEmpty) return;
    Navigator.pop(context, (title: title.text.trim(), content: content.text));
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = title.text.trim().isNotEmpty && content.text.isNotEmpty;

    // 白い角丸の入力欄（タイトルと内容で共通）
    InputDecoration fieldDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 14,
        height: 1.6,
        color: Colors.black38,
      ),
      hintMaxLines: 3,
      filled: true,
      fillColor: Colors.white,
      counterText: "",
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _blue, width: 1.5),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: const Text(
          "質問投稿",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            // ==========================================
            // 入力欄（スクロールできる）
            // ==========================================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(17, 14, 17, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 2, bottom: 8),
                      child: Text(
                        "タイトル",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    TextField(
                      controller: title,
                      autofocus: true,
                      maxLength: 40,
                      textInputAction: TextInputAction.next,
                      cursorColor: _blue,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      decoration: fieldDecoration("例：英単語を効率よく覚えるコツは？"),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 2),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "${title.text.characters.length}/40",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black45,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Padding(
                      padding: EdgeInsets.only(left: 2, bottom: 8),
                      child: Text(
                        "質問の内容",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    TextField(
                      controller: content,
                      minLines: 6,
                      maxLines: 12,
                      keyboardType: TextInputType.multiline,
                      cursorColor: _blue,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                      decoration: fieldDecoration(
                        "くわしい内容を書いてください\n例：毎日100個覚えても、すぐ忘れてしまいます",
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 公開されることの案内と、文字数
                    Row(
                      children: [
                        const Icon(
                          Icons.public_rounded,
                          size: 14,
                          color: Colors.black38,
                        ),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            "投稿した質問は、ほかのユーザーにも公開されます",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                          ),
                        ),
                        Text(
                          "${content.text.characters.length}文字",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ==========================================
            // 投稿するボタン（下に固定。キーボードが出たらその上に来る）
            // ==========================================
            Container(
              padding: const EdgeInsets.fromLTRB(17, 10, 17, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: canSubmit ? submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE3E7EC),
                    disabledForegroundColor: Colors.black38,
                    elevation: 0,
                    // 両端が丸いボタン
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    "投稿する",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
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

class QnaDetailScreen extends StatefulWidget {
  final Question question;
  final Color primaryColor;

  const QnaDetailScreen({
    super.key,
    required this.question,
    required this.primaryColor,
  });

  @override
  State<QnaDetailScreen> createState() => _QnaDetailScreenState();
}

class _QnaDetailScreenState extends State<QnaDetailScreen> {
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
    final t = TextEditingController(text: widget.question.title);
    final c = TextEditingController(text: widget.question.content);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("質問編集"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: t,
              maxLength: 40,
              decoration: const InputDecoration(labelText: "タイトル"),
            ),
            TextField(
              controller: c,
              minLines: 2,
              maxLines: 6,
              decoration: const InputDecoration(labelText: "質問の内容"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("キャンセル"),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                widget.question.title = t.text;
                widget.question.content = c.text;
              });
              await FirebaseFirestore.instance
                  .collection("questions")
                  .doc(widget.question.id)
                  .update({"title": t.text, "content": c.text});
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

  static const Color _blue = AppColors.primary;

  @override
  void initState() {
    super.initState();

    // 送信ボタンの押せる・押せないを、入力に合わせて変える
    answerText.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    answerText.dispose();
    super.dispose();
  }

  // 「質問者」の小さな札
  Widget _askerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        "質問者",
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: _blue,
        ),
      ),
    );
  }

  // 白い角丸のカード
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    );
  }

  // ==============================================================
  // 質問のカード（だれが・いつ・タイトル・内容）
  // ==============================================================
  Widget _buildQuestionCard(Question q) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserIcon(
                userId: q.userId,
                userName: q.userName,
                radius: 16,
                primaryColor: widget.primaryColor,
              ),
              const SizedBox(width: 8),
              // 名前と札は左に詰め、日時は右端に置く
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        q.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _askerBadge(),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                q.postedAtText,
                style: const TextStyle(fontSize: 12, color: Colors.black38),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            q.displayTitle,
            style: const TextStyle(
              fontSize: 18,
              height: 1.45,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          if (q.previewBody.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              q.previewBody,
              style: const TextStyle(
                fontSize: 15,
                height: 1.65,
                color: Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==============================================================
  // 回答1件分のカード（だれが・回答・返信・返信するボタン）
  // ==============================================================
  Widget _buildAnswerCard(Question q, Answer a, User? currentUser) {
    final bool isMyAnswer = currentUser != null && a.userId == currentUser.uid;
    final bool isAsker = a.userId.isNotEmpty && a.userId == q.userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 12, 6, 6),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserIcon(
                userId: a.userId,
                userName: a.userName,
                radius: 14,
                primaryColor: widget.primaryColor,
              ),
              const SizedBox(width: 8),
              // 名前と札は左に詰め、メニューは右端に置く
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        a.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (isAsker) ...[const SizedBox(width: 6), _askerBadge()],
                  ],
                ),
              ),

              // 自分の回答だけ、削除のメニューを出す
              if (isMyAnswer)
                PopupMenuButton(
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: Colors.black38,
                  ),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: "delete", child: Text("削除")),
                  ],
                  onSelected: (v) {
                    if (v == "delete") deleteAnswer(a);
                  },
                )
              else
                const SizedBox(height: 40),
            ],
          ),

          Padding(
            padding: const EdgeInsets.only(right: 10, top: 2),
            child: Text(
              a.text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ),

          // 返信（うすい灰色の面にまとめ、少し右に下げる）
          if (a.replies.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 10, 10, 0),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final r in a.replies)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UserIcon(
                            userId: r.userId,
                            userName: r.userName,
                            radius: 11,
                            primaryColor: widget.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: "${r.userName}  ",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(text: r.text),
                                ],
                              ),
                              style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.5,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => addReply(a),
              style: TextButton.styleFrom(
                foregroundColor: _blue,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(0, 36),
              ),
              icon: const Icon(Icons.reply_rounded, size: 18),
              label: const Text(
                "返信する",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isMyQuestion =
        currentUser != null && q.userId == currentUser.uid;
    final canSend = answerText.text.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: const Text(
          "詳細",
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
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

      body: SafeArea(
        child: Column(
          children: [
            // ==========================================
            // 質問と回答（スクロールできる）
            // ==========================================
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(17, 14, 17, 16),
                children: [
                  _buildQuestionCard(q),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 8),
                    child: Text(
                      "回答 ${q.answers.length}件",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  if (q.answers.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: _cardDecoration(),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Colors.black26,
                            size: 28,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "まだ回答はありません",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "下の入力欄から、最初の回答を書いてみよう",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final a in q.answers)
                      _buildAnswerCard(q, a, currentUser),
                ],
              ),
            ),

            // ==========================================
            // 回答の入力欄（下に固定。チャットの入力欄と同じ形）
            // ==========================================
            Container(
              padding: const EdgeInsets.fromLTRB(17, 8, 12, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: answerText,
                      minLines: 1,
                      maxLines: 4,
                      keyboardType: TextInputType.multiline,
                      cursorColor: _blue,
                      style: const TextStyle(fontSize: 15, height: 1.4),
                      decoration: InputDecoration(
                        hintText: "回答を入力",
                        hintStyle: const TextStyle(color: Colors.black38),
                        filled: true,
                        fillColor: AppColors.background,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: _blue,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 送信ボタン（文字がないときは灰色で押せない）
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Material(
                      color: canSend ? _blue : const Color(0xFFE3E7EC),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: canSend ? addAnswer : null,
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: Icon(
                            Icons.arrow_upward_rounded,
                            size: 22,
                            color: canSend ? Colors.white : Colors.black26,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  // 写真がない人のアイコン（指定された大きさで出す）
  Widget _defaultIcon() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withOpacity(0.12),
      child: Icon(Icons.person, size: radius * 1.15, color: AppColors.primary),
    );
  }
}
