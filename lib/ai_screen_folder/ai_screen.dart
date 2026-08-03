import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jumping_dot/jumping_dot.dart';
import 'package:flutter/services.dart';

class ChatMessage {
  final bool isUser;
  final String text;

  ChatMessage({required this.isUser, required this.text});
}

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiTestScreenState();
}

class _AiTestScreenState extends State<AiScreen> {
  String _aiResponse = "ここにAIの返答が表示されます";
  bool _isLoading = false;
  bool _hasStartedChat = false;

  List<ChatMessage> _messages = [];

  final TextEditingController _textController = TextEditingController();

  // Groqに質問を送る関数
  Future<void> askGemini() async {
    if (_textController.text.trim().isEmpty) return;

    final question = _textController.text;

    setState(() {
      _isLoading = true;
      _messages.add(ChatMessage(isUser: true, text: question));
      _textController.clear();
      _hasStartedChat = true;
    });

    final apiKey = dotenv.get('GEMINI_API_KEY');

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key=$apiKey',
    );

    try {
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
        });
      } else {
        setState(() {
          _messages.add(
            ChatMessage(
              isUser: false,
              text: "エラー(${response.statusCode})\n${response.body}",
            ),
          );
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(isUser: false, text: "通信エラー：$e"));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        title: const Text(
          "AIサポート",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 19,
            fontWeight: FontWeight.bold,
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
              icon: const Icon(Icons.history),
              onPressed: () {},
            ),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.black87),
      ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
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
                              color: Color(0xFF2196F3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        Padding(
                          padding: const EdgeInsets.only(left: 3),
                          child: const Text(
                            "勉強方法・問題解説・学習計画など、\nAIがあなたの学習をサポートします。",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 23),

                        Card(
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      color: Color(0xFF2196F3),
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "質問例",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 13),

                                SizedBox(
                                  height: 240,
                                  child: GridView.count(
                                    crossAxisCount: 2,
                                    // 2列
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: 2.3,
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
                        ),

                        const SizedBox(height: 13),
                      ],

                      _buildAnswerCard(),
                    ],
                  ),
                ),
              ),
            ),

            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _questionChip(IconData icon, String text) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() {
          _textController.text = text;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2196F3), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
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
              padding: const EdgeInsets.only(top: 67),
              child: Center(
                child: Text(
                  "質問例をタップするか、\n下の入力欄から質問してみよう！",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
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
                          margin: const EdgeInsets.only(top: 2, bottom: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3),
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
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: message.text),
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("コピーしました"),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 7),
                                child: Icon(
                                  Icons.content_copy_outlined,
                                  size: 18,
                                  color: Colors.grey,
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
                          color: Color(0xFF2196F3),
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

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        color: const Color(0xFFF7F7F7),
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "質問を入力してください",
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) {
                          if (!_isLoading) {
                            askGemini();
                          }
                        },
                      ),
                    ),

                    IconButton(
                      icon: const Icon(
                        Icons.image_outlined,
                        color: Color(0xFF9E9E9E),
                      ),
                      onPressed: () {
                        // 今後、画像選択機能を追加
                      },
                    ),

                    GestureDetector(
                      onTap: _isLoading ? null : askGemini,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2196F3),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
