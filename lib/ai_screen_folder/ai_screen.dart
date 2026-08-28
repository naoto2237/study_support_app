import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jumping_dot/jumping_dot.dart';
import 'package:flutter/services.dart';
import 'ai_history_screen.dart';
import 'aihistory_chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/rendering.dart';
import 'aichat_inputbar.dart';
import 'dart:io';

class ChatMessage {
  final bool isUser;
  final String text;

  ChatMessage({required this.isUser, required this.text});
}

class AiScreen extends StatefulWidget {
  final String? chatId;
  final bool fromHistory;

  const AiScreen({super.key, this.chatId, this.fromHistory = false});

  @override
  State<AiScreen> createState() => _AiTestScreenState();
}

class _AiTestScreenState extends State<AiScreen> {
  bool _isLoading = false;
  bool _hasStartedChat = false;

  List<ChatMessage> _messages = [];

  final TextEditingController _textController = TextEditingController();

  File? _selectedImage;
  String? _chatId;

  // =========================================================
  // AIに質問を送る
  // =========================================================

  Future<void> askGemini() async {
    if (_textController.text.trim().isEmpty) return;

    // 現在ログインしているユーザー
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _messages.add(ChatMessage(isUser: false, text: "ログインしてください。"));
      });
      return;
    }

    final question = _textController.text.trim();

    // キーボードを閉じる
    FocusScope.of(context).unfocus();

    // =====================================================
    // 新しいチャットの場合
    // =====================================================

    if (_chatId == null) {
      _chatId = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('ai_history')
          .doc()
          .id;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('ai_history')
          .doc(_chatId)
          .set({
            'title': question,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    }

    setState(() {
      _isLoading = true;

      _messages.add(ChatMessage(isUser: true, text: question));

      _textController.clear();
      _hasStartedChat = true;
    });

    try {
      // =====================================================
      // ユーザーのメッセージを保存
      // =====================================================

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('ai_history')
          .doc(_chatId)
          .collection('messages')
          .add({
            'role': 'user',
            'text': question,
            'createdAt': FieldValue.serverTimestamp(),
          });

      final apiKey = dotenv.get('GEMINI_API_KEY');

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/'
        'v1beta/models/gemini-3.1-flash-lite:generateContent'
        '?key=$apiKey',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "system_instruction": {
            "parts": [
              {
                "text":
                    'あなたは学生向けのAI学習サポートアシスタントです。'
                    '漢数字は使わないで、1,2,3などのちゃんとした数字を使ってください。'
                    '学生が勉強を前向きに続けられるようにサポートしてください。'
                    '勉強方法、問題解説、学習計画、モチベーション維持など、学習に関する相談に答えてください。'
                    '学習に関係ない質問には、「私は学習支援AIです。勉強に関する質問や相談をしてください。」と答えてください。'
                    '回答は2〜4文を基本とし、長くても5文以内にしてください。'
                    '最初の1文で結論を伝え、その後に理由や具体例を1〜2文で説明してください。'
                    '最後は「まずは○○してみよう」「○○がおすすめだよ」のように、すぐ実践できる一言で締めてください。'
                    '日本人の先生や先輩が話しかけるような、自然で親しみやすい日本語を使ってください。'
                    '教科書のような説明や、機械的な文章、不自然な翻訳調の文章は避けてください。'
                    '専門用語はできるだけ使わず、中学生や高校生でも理解できる言葉で説明してください。'
                    '「*」「-」「①」などの箇条書きは使わないでください。'
                    'ユーザーを否定したり説教したりせず、前向きで優しい表現を使ってください。'
                    '根拠のないことは断定せず、「〜がおすすめだよ！」「〜してみよう！」のように提案する表現を使ってください。'
                    '回答を送信する前に、日本語として自然で読みやすい文章になっているか確認してください。',
              },
            ],
          },
          "contents": [
            {
              "parts": [
                {"text": question},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        final reply = data["candidates"][0]["content"]["parts"][0]["text"];

        if (!mounted) return;

        setState(() {
          _messages.add(ChatMessage(isUser: false, text: reply));

          _isLoading = false;
        });

        // =================================================
        // AIの回答を保存
        // =================================================

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('ai_history')
            .doc(_chatId)
            .collection('messages')
            .add({
              'role': 'assistant',
              'text': reply,
              'createdAt': FieldValue.serverTimestamp(),
            });

        // =================================================
        // 最終更新日時を更新
        // =================================================

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('ai_history')
            .doc(_chatId)
            .set({
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      } else {
        if (!mounted) return;

        setState(() {
          _isLoading = false;

          if (response.statusCode == 503) {
            _messages.add(
              ChatMessage(
                isUser: false,
                text:
                    "現在AIが混み合っています。\n"
                    "少し時間をおいてもう一度お試しください。",
              ),
            );
          } else {
            _messages.add(
              ChatMessage(isUser: false, text: "エラー(${response.statusCode})"),
            );
          }
        });
      }
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());

      if (!mounted) return;

      setState(() {
        _isLoading = false;

        _messages.add(ChatMessage(isUser: false, text: "通信エラー：$e"));
      });
    }
  }

  // =========================================================
  // 過去のメッセージを読み込む
  // =========================================================

  Future<void> _loadMessages() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || _chatId == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('ai_history')
        .doc(_chatId)
        .collection('messages')
        .orderBy('createdAt')
        .get();

    final List<ChatMessage> loadedMessages = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();

      loadedMessages.add(
        ChatMessage(isUser: data['role'] == 'user', text: data['text'] ?? ''),
      );
    }

    if (!mounted) return;

    setState(() {
      _messages = loadedMessages;
      _hasStartedChat = loadedMessages.isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();

    if (widget.chatId != null) {
      _chatId = widget.chatId;
      _loadMessages();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final borderColor = isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: _hasStartedChat ? Color(0xFFF7F7F7) : Colors.white,
        appBar: AppBar(
          leadingWidth: 56,
          // デフォルトは56
          leading: _hasStartedChat
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (widget.fromHistory) {
                      Navigator.pop(context);

                      Future.microtask(() {
                        _messages.clear();
                        _chatId = null;
                        _hasStartedChat = false;
                        _selectedImage = null;
                        _textController.clear();
                      });

                      return;
                    } else {
                      setState(() {
                        _messages.clear();
                        _chatId = null;
                        _hasStartedChat = false;
                        _isLoading = false;
                        _textController.clear();
                        _selectedImage = null;
                      });
                    }
                  },
                )
              : null,

          title: Transform.translate(
            offset: Offset(_hasStartedChat ? -19 : 0, 0),
            child: Text(
              "AIサポート",
              style: TextStyle(
                color: _hasStartedChat ? Colors.black87 : Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          centerTitle: false,
          backgroundColor: _hasStartedChat
              ? Colors.white
              : const Color(0xFF258EDB),
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: IconButton(
                icon: Icon(
                  Icons.history,
                  color: _hasStartedChat ? Colors.black87 : Colors.white,
                ),
                onPressed: () {
                  // キーボードを閉じる
                  FocusScope.of(context).unfocus();

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AiHistoryScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_hasStartedChat) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 3),
                            child: const Text(
                              "学習の悩みをAIに相談しよう",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF258EDB),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),

                          Padding(
                            padding: const EdgeInsets.only(left: 3),
                            child: Text(
                              "勉強方法・問題解説・学習計画など\nAIがあなたの学習をサポートします",
                              style: TextStyle(fontSize: 15, color: textColor),
                            ),
                          ),
                          const SizedBox(height: 11),

                          Padding(
                            padding: const EdgeInsets.only(
                              left: 4,
                              right: 4,
                              top: 11,
                              bottom: 11,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      color: Color(0xFF258EDB),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "質問例",
                                      style: TextStyle(
                                        fontSize: 15.6,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 9),

                                SizedBox(
                                  height: 240,
                                  child: GridView.count(
                                    crossAxisCount: 2,
                                    // 2列
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: 2.6,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    children: [
                                      _questionChip(
                                        Icons.menu_book_outlined,
                                        "効率的な勉強方法を教えて",
                                      ),
                                      _questionChip(
                                        Icons.quiz_outlined,
                                        "この問題を解説して",
                                      ),
                                      _questionChip(
                                        Icons.calendar_month_outlined,
                                        "一週間の学習計画を立てて",
                                      ),
                                      _questionChip(
                                        Icons.psychology_alt_outlined,
                                        "暗記のコツを教えて",
                                      ),
                                      _questionChip(
                                        Icons.trending_up_outlined,
                                        "集中力を上げる方法は？",
                                      ),
                                      _questionChip(
                                        Icons.local_fire_department_outlined,
                                        "やる気を維持する方法は？",
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 13),
                        ],

                        _buildAnswerCard(),
                      ],
                    ),
                  ),
                ),
              ),

              AiChatInputBar(
                controller: _textController,
                onSend: askGemini,
                isLoading: _isLoading,
                hasStartedChat: _hasStartedChat,
                onImageSelected: (image) {
                  setState(() {
                    _selectedImage = image;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _questionChip(IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() {
          _textController.text = text;
        });

        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Container(
        padding: const EdgeInsets.only(left: 14, right: 14, top: 0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF258EDB), size: 23),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerCard() {
    return Padding(
      padding: const EdgeInsets.only(top: 0, right: 0, left: 0, bottom: 15),
      child: _messages.isEmpty
          ? Padding(
              padding: const EdgeInsets.only(top: 73),
              child: Center(
                child: Text(
                  "質問例をタップするか、\n下の入力欄から質問してみよう！",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.black54,
                    height: 1.7,
                  ),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ..._messages.map((message) {
                  if (message.isUser) {
                    // ユーザーの質問
                    return Align(
                      alignment: Alignment.centerRight,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 277),
                        child: Container(
                          margin: const EdgeInsets.only(top: 6, bottom: 17),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF258EDB),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            message.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  // AIの回答
                  return SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),

                        Row(
                          children: [
                            Transform.translate(
                              offset: const Offset(-9, 2),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  splashColor: Colors.grey.withOpacity(0.15),
                                  highlightColor: Colors.grey.withOpacity(0.08),
                                  onTap: () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: message.text),
                                    );
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.content_copy_outlined,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),

                if (_isLoading)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        JumpingDots(
                          color: Color(0xFF258EDB),
                          radius: 5,
                          numberOfDots: 3,
                          animationDuration: Duration(milliseconds: 250),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
