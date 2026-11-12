// ======================================================================
// 【画面】AIサポート（下のタブ「AIサポート」）
//
// 主なクラス: AiScreen
// 開き方: main.dart の MainNavigationScreen
// ・Gemini に質問を送り、回答を表示する新しいチャット
// ・メッセージの形は ai_chat_message.dart（AiChatMessage）
// ・会話は Firestore の users/{uid}/ai_history に保存する
// ・履歴ボタンから履歴一覧（ai_history_screen.dart）へ
// ======================================================================

import 'package:flutter/material.dart';
import 'package:study_support_app/theme/app_palette.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:study_support_app/screens/ai_support/ai_history_screen.dart';
import 'package:study_support_app/screens/ai_support/ai_chat_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_support_app/screens/ai_support/ai_chat_input_bar.dart';
import 'dart:io';
import 'package:study_support_app/screens/ai_support/ai_chat_message_list.dart';
import 'package:study_support_app/theme/app_colors.dart';

class AiScreen extends StatefulWidget {
  final String? chatId;
  final bool fromHistory;

  const AiScreen({super.key, this.chatId, this.fromHistory = false});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  bool _isLoading = false;
  bool _hasStartedChat = false;

  List<AiChatMessage> _messages = [];

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
        _messages.add(AiChatMessage(isUser: false, text: "ログインしてください。"));
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

      _messages.add(AiChatMessage(isUser: true, text: question));

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
          _messages.add(AiChatMessage(isUser: false, text: reply));

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
              AiChatMessage(
                isUser: false,
                text:
                    "現在AIが混み合っています。\n"
                    "少し時間をおいてもう一度お試しください。",
              ),
            );
          } else {
            _messages.add(
              AiChatMessage(isUser: false, text: "エラー(${response.statusCode})"),
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

        _messages.add(AiChatMessage(isUser: false, text: "通信エラー：$e"));
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

    final List<AiChatMessage> loadedMessages = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();

      loadedMessages.add(
        AiChatMessage(isUser: data['role'] == 'user', text: data['text'] ?? ''),
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
    final textColor = isDark ? Colors.white : Colors.black87;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: context.pal.page,
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
                color: _hasStartedChat ? context.pal.text : Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          centerTitle: false,
          backgroundColor: _hasStartedChat
              ? context.pal.card
              : AppColors.primary,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: IconButton(
                icon: Icon(
                  Icons.history,
                  color: _hasStartedChat ? context.pal.text : Colors.white,
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
                    // 見出しの文字の高さを、ホームの日付の高さにそろえる（チャット中は 14）
                    padding: EdgeInsets.fromLTRB(
                      17,
                      _hasStartedChat ? 14 : 9.5,
                      17,
                      24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_hasStartedChat) ...[
                          // ============================================
                          // 見出し
                          // ============================================
                          Padding(
                            padding: const EdgeInsets.only(left: 3),
                            child: const Text(
                              "学習の悩みをAIに相談しよう",
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),

                          Padding(
                            padding: const EdgeInsets.only(left: 3),
                            child: Text(
                              "勉強方法・問題解説・学習計画など\nAIがあなたの学習をサポートします",
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.6,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),

                          // ==============================================
                          // 質問例（1列の一覧。行全体を押せる）
                          // ==============================================
                          Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "質問例",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          _buildQuestionList(isDark),

                          const SizedBox(height: 10),
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

  // 質問例（アイコンと文章）
  static const List<(IconData, String)> _questionExamples = [
    (Icons.menu_book_outlined, "効率的な勉強方法を教えて"),
    (Icons.quiz_outlined, "この問題を解説して"),
    (Icons.calendar_month_outlined, "一週間の学習計画を立てて"),
    (Icons.psychology_alt_outlined, "暗記のコツを教えて"),
    (Icons.trending_up_outlined, "集中力を上げる方法は？"),
    (Icons.local_fire_department_outlined, "やる気を維持する方法は？"),
  ];

  // ==============================================================
  // 質問例の一覧（押すと入力欄に文章が入る）
  // ==============================================================
  Widget _buildQuestionList(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.grey.shade800 : AppColors.border;
    final dividerColor = isDark ? Colors.grey.shade800 : AppColors.divider;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),

      // 枠線は中身の上に描く（中の行の色で、角の枠線が隠れないように）
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < _questionExamples.length; i++) ...[
            _questionChip(_questionExamples[i].$1, _questionExamples[i].$2),
            if (i < _questionExamples.length - 1)
              Container(
                height: 1,
                margin: const EdgeInsets.only(left: 60),
                color: dividerColor,
              ),
          ],
        ],
      ),
    );
  }

  Widget _questionChip(IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _textController.text = text;
          });

          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 54),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
            child: Row(
              children: [
                // アイコン（うすい青の丸の中）
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? AppColors.primary.withValues(alpha: 0.18)
                        : AppColors.primarySoft,
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 18),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),

                // 入力欄に入ることを表す矢印
                Icon(
                  Icons.north_west_rounded,
                  size: 17,
                  color: isDark ? Colors.white38 : Colors.black26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: _messages.isEmpty
          ? Padding(
              padding: EdgeInsets.only(top: 2),
              child: Center(
                child: Text(
                  "タップすると入力欄に入ります",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.pal.muted,
                    height: 1.5,
                  ),
                ),
              ),
            )
          // 会話の表示は共通の部品（ai_chat_message_list.dart）
          : AiChatMessageList(messages: _messages, isLoading: _isLoading),
    );
  }
}
