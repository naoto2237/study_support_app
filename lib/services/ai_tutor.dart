// ======================================================================
// 【しくみ】AIの先生に質問する
//
// 主な関数: AiTutor.ask
// 使う画面: ai_screen.dart（AIサポート）／ai_history_chat_screen.dart（履歴の続き）
// ・Firebase AI Logic（firebase_ai）を通して Gemini を呼ぶ
//   → AIのキーは Firebase の中にあり、アプリの中には入らない
// ・画像をえらんでいるときは、画像もいっしょに送る
// ・その会話のそれまでのやりとり（直近20件まで）も送る → 「さっきの続き」が通じる
// ・うまくいかなかったときは、画面に出す日本語の文を返す（英語のエラーは出さない）
// ======================================================================

import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:study_support_app/screens/ai_support/ai_chat_message.dart';

class AiTutor {
  AiTutor._();

  static const String _systemPrompt =
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
      '画像が送られてきたときは、画像の中の問題や内容を読み取って、同じように答えてください。'
      '回答を送信する前に、日本語として自然で読みやすい文章になっているか確認してください。';

  // 一度作ったら使い回す
  static final GenerativeModel _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3.1-flash-lite',
    systemInstruction: Content.system(_systemPrompt),
  );

  // 質問して、AIの答えを返す
  // うまくいかなかったときは AiTutorException を投げる（message に画面に出す文が入る）
  // history：この会話の、それまでのやりとり（古い順）。「さっきの続き」が通じるように送る
  static Future<String> ask(
    String question, {
    File? image,
    List<AiChatMessage> history = const [],
  }) async {
    try {
      final parts = <Part>[
        if (image != null)
          InlineDataPart(_mimeTypeOf(image.path), await image.readAsBytes()),
        TextPart(question.isEmpty ? 'この画像について教えてください。' : question),
      ];

      final response = await _model.generateContent([
        ..._historyContents(history),
        Content.multi(parts),
      ]);

      final text = response.text?.trim() ?? '';

      if (text.isEmpty) {
        throw const AiTutorException(
          'うまく答えられませんでした。\n質問のしかたを少し変えて、もう一度お試しください。',
        );
      }

      return text;
    } on AiTutorException {
      rethrow;
    } on QuotaExceeded catch (e) {
      debugPrint('AIの使える回数をこえました: $e');
      throw const AiTutorException('今日はAIを使える回数をこえました。\n時間をおいてから、もう一度お試しください。');
    } on ServerException catch (e) {
      debugPrint('AIのサーバーのエラー: $e');

      // 混み合っているときだけ「混み合っています」と出す。それ以外は、つながらなかったと出す
      final text = e.toString().toLowerCase();
      if (!text.contains('overloaded') &&
          !text.contains('unavailable') &&
          !text.contains('503')) {
        throw const AiTutorException('AIにつながりませんでした。\n時間をおいてから、もう一度お試しください。');
      }

      throw const AiTutorException('現在AIが混み合っています。\n少し時間をおいてもう一度お試しください。');
    } catch (e, stackTrace) {
      debugPrint('AIへの質問に失敗しました: $e');
      debugPrint(stackTrace.toString());
      throw const AiTutorException('AIにつながりませんでした。\n通信の状態を確かめて、もう一度お試しください。');
    }
  }

  // 送るのは、直近のやりとりだけ（長くなりすぎて、AIの使える量を使いすぎないように）
  static const int _maxHistory = 20;

  // それまでのやりとりを、AI に送る形にする
  // ・失敗の知らせ（isError）は、AIの答えではないので送らない
  // ・答えが返ってこなかった質問も送らない（質問と答えが、交互にそろうように）
  static List<Content> _historyContents(List<AiChatMessage> history) {
    final pairs = <Content>[];

    for (int i = 0; i < history.length; i++) {
      final message = history[i];
      if (message.isError || message.text.trim().isEmpty) continue;

      if (message.isUser) {
        // すぐ後ろに、ちゃんとした答えがあるときだけ送る
        final next = i + 1 < history.length ? history[i + 1] : null;
        if (next == null || next.isUser || next.isError) continue;
        pairs.add(Content.text(message.text));
      } else {
        // 答えは、前に質問を送ったときだけ（質問と答えを交互にする）
        if (pairs.isEmpty || pairs.last.role != 'user') continue;
        pairs.add(Content.model([TextPart(message.text)]));
      }
    }

    // 直近の分だけにする（質問から始まるように、偶数で切る）
    if (pairs.length > _maxHistory) {
      return pairs.sublist(pairs.length - _maxHistory);
    }
    return pairs;
  }

  static String _mimeTypeOf(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}

// AIに質問できなかったとき。message は、そのまま画面に出せる日本語の文
class AiTutorException implements Exception {
  final String message;

  const AiTutorException(this.message);

  @override
  String toString() => message;
}
