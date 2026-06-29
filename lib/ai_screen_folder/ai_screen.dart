import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiTestScreenState();
}

class _AiTestScreenState extends State<AiScreen> {
  String _aiResponse = "ここにAIの返答が表示されます";
  bool _isLoading = false;
  final TextEditingController _textController = TextEditingController();

  // Groqに質問を送る関数
  Future<void> askGroq() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _aiResponse = "AIが考えています...";
    });

    final apiKey = dotenv.get('GROQ_API_KEY', fallback: '');

    try {
      // GroqのAPIを呼び出すための設定
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          // Meta社が開発した、無料枠で使える高性能AIモデルを指定します
          'model': 'llama-3.1-8b-instant',
          'messages': [
            // 💡 ここで「学習支援専用AI」としての役割（システムプロンプト）を設定しています
            {
              'role': 'system',
              'content': 'あなたを受験生や学生を支える「AI学習支援アシスタント」です。'
                  'ユーザーから勉強の方法、計画、各科目の疑問、モチベーション維持などの「学習に関する相談」を受けた場合は、親身になって優しくアドバイスをしてください。'
                  'ただし、勉強や学習に全く関係のない雑談、エンタメ、ゲームなどの質問をされた場合は、'
                  '「私は学習支援AIですので、勉強に関する質問や相談をしてくださいね！」という風に、学習に関係ないことは答えられない旨を優しく伝えて断ってください。'
            },
            // ユーザーがTextFieldに入力した文字を送ります
            {
              'role': 'user',
              'content': _textController.text,
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        // 返ってきたデータ（JSON）から、AIの文章だけを抜き出す処理
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final reply = data['choices'][0]['message']['content'];

        setState(() {
          _aiResponse = reply;
        });
        _textController.clear(); // 終わったら入力欄を空にする
      } else {
        setState(() {
          _aiResponse = "エラーが発生しました (コード: ${response.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        _aiResponse = "通信エラーが発生しました: $e";
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
backgroundColor: const Color(0xFFF5F7FA),

appBar: AppBar(
title: const Text("AIサポート"),
centerTitle: true,
backgroundColor: Colors.white,
elevation: 0,
),

body: Padding(
padding: const EdgeInsets.all(16),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [

const Text(
"勉強についてAIに相談しましょう",
style: TextStyle(
fontSize: 22,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 8),

Text(
"勉強方法・問題解説・学習計画などを相談できます。",
style: TextStyle(
color: Colors.grey.shade600,
),
),

const SizedBox(height: 20),

Card(
elevation: 2,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(15),
),
child: Padding(
padding: const EdgeInsets.all(15),
child: TextField(
controller: _textController,
maxLines: 4,
decoration: const InputDecoration(
border: InputBorder.none,
hintText: "例）数学の勉強方法を教えて",
),
),
),
),

const SizedBox(height: 15),

SizedBox(
width: double.infinity,
height: 50,
child: ElevatedButton.icon(
onPressed: _isLoading ? null : askGroq,
icon: const Icon(Icons.auto_awesome),
label: const Text(
"AIに質問する",
style: TextStyle(fontSize: 18),
),
),
),

const SizedBox(height: 25),

const Text(
"AIの回答",
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: 20,
),
),

const SizedBox(height: 10),

Expanded(
child: Card(
elevation: 2,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(15),
),
child: Padding(
padding: const EdgeInsets.all(16),
child: _isLoading
? const Center(
child: CircularProgressIndicator(),
)
: SingleChildScrollView(
child: Text(
_aiResponse,
style: const TextStyle(fontSize: 16),
),
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