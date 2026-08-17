import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jumping_dot/jumping_dot.dart';
import 'package:flutter/services.dart';
import 'ai_history_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'aichat_inputbar.dart';
import 'dart:io';

class ChatMessage {
  final bool isUser;
  final String text;

  ChatMessage({required this.isUser, required this.text});
}

class AiHistoryChatScreen extends StatefulWidget {
  final String chatId;

  const AiHistoryChatScreen({super.key, required this.chatId});

  @override
  State<AiHistoryChatScreen> createState() => _AiHistoryChatScreenState();
}

class _AiHistoryChatScreenState extends State<AiHistoryChatScreen> {
  bool _isLoading = false;
  bool _hasStartedChat = false;
  bool _isLoadingHistory = true;

  List<ChatMessage> _messages = [];

  final TextEditingController _textController = TextEditingController();

  File? _selectedImage;
  String? _chatId;

  // Groqに質問を送る関数
  Future<void> askGemini() async {
    if (_textController.text.trim().isEmpty) return;

    final question = _textController.text;

    // キーボードを閉じる
    FocusScope.of(context).unfocus();

    if (_chatId == null) {
      _chatId = FirebaseFirestore.instance.collection('ai_history').doc().id;

      await FirebaseFirestore.instance
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
      await FirebaseFirestore.instance
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
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent?key=$apiKey',
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

        setState(() {
          _messages.add(ChatMessage(isUser: false, text: reply));
          _isLoading = false;
        });

        await FirebaseFirestore.instance
            .collection('ai_history')
            .doc(_chatId)
            .collection('messages')
            .add({
              'role': 'assistant',
              'text': reply,
              'createdAt': FieldValue.serverTimestamp(),
            });

        await FirebaseFirestore.instance
            .collection('ai_history')
            .doc(_chatId)
            .set({
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      } else {
        setState(() {
          _isLoading = false;

          if (response.statusCode == 503) {
            _messages.add(
              ChatMessage(
                isUser: false,
                text: "現在AIが混み合っています。\n少し時間をおいてもう一度お試しください。",
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

      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(isUser: false, text: "通信エラー：$e"));
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final snapshot = await FirebaseFirestore.instance
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

    setState(() {
      _chatId = widget.chatId;
      _messages = loadedMessages;
      _hasStartedChat = loadedMessages.isNotEmpty;
      _isLoadingHistory = false;
    });
  }

  @override
  void initState() {
    super.initState();

    _chatId = widget.chatId;
    _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),

        appBar: AppBar(
          leadingWidth: 56,
          // デフォルトは56
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),

          title: Transform.translate(
            offset: const Offset(-19, 0),
            child: const Text(
              "AIサポート",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          centerTitle: false,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: IconButton(
                icon: const Icon(Icons.history, color: Colors.black87),
                onPressed: () {
                  Navigator.pushReplacement(
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
                      children: [_buildAnswerCard()],
                    ),
                  ),
                ),
              ),

              AiChatInputBar(
                controller: _textController,
                onSend: askGemini,
                isLoading: _isLoading,
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

  Widget _buildAnswerCard() {
    if (_messages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 0, right: 0, left: 0, bottom: 15),
      child: Column(
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
                      color: const Color(0xFFC9E9FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message.text,
                      style: const TextStyle(
                        color: Colors.black87,
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
