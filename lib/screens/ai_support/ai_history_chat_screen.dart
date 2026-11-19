// ======================================================================
// 【画面】過去のAIチャットの続き
//
// 主なクラス: AiHistoryChatScreen
// 開き方: 履歴一覧（ai_history_screen.dart）で会話をタップ
// ・過去のメッセージを読み込み、続けて Gemini に質問できる
// ・旧ファイル名: aihistory_chat_screen.dart
// ======================================================================

import 'package:flutter/material.dart';
import 'package:study_support_app/theme/app_palette.dart';
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/services/ai_tutor.dart';
import 'package:study_support_app/screens/ai_support/ai_history_screen.dart';
import 'package:study_support_app/screens/ai_support/ai_chat_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_support_app/screens/ai_support/ai_chat_input_bar.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_support_app/screens/ai_support/ai_chat_message_list.dart';

class AiHistoryChatScreen extends StatefulWidget {
  final String chatId;
  final String userId;

  const AiHistoryChatScreen({
    super.key,
    required this.chatId,
    required this.userId,
  });

  @override
  State<AiHistoryChatScreen> createState() => _AiHistoryChatScreenState();
}

class _AiHistoryChatScreenState extends State<AiHistoryChatScreen> {
  bool _isLoading = false;
  bool _hasStartedChat = false;
  bool _isLoadingHistory = true;

  List<AiChatMessage> _messages = [];

  final TextEditingController _textController = TextEditingController();

  File? _selectedImage;
  String? _chatId;

  // Groqに質問を送る関数
  Future<void> askGemini() async {
    if (_textController.text.trim().isEmpty) return;

    // 現在ログインしているユーザー
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _messages.add(
          AiChatMessage(isUser: false, text: "ログインしてください。", isError: true),
        );
      });
      return;
    }

    final question = _textController.text.trim();

    // えらんだ画像は、この質問で一度だけ送る
    final image = _selectedImage;
    _selectedImage = null;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _messages.add(AiChatMessage(isUser: true, text: question));
      _textController.clear();
      _hasStartedChat = true;
    });

    try {
      // ユーザーのメッセージを保存
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

      // AIに質問する（キーは Firebase の中にあり、アプリには入っていない）
      // それまでのやりとりも送る（「さっきの続き」が通じるように）
      // いま足した自分の質問は、いちばん後ろにあるので外す
      final reply = await AiTutor.ask(
        question,
        image: image,
        history: _messages.sublist(0, _messages.length - 1),
      );

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
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());

      if (!mounted) return;

      setState(() {
        _isLoading = false;

        // AIの失敗は、日本語の文がそのまま入っている。それ以外は通信の失敗
        _messages.add(
          AiChatMessage(
            isUser: false,
            isError: true,
            text: e is AiTutorException
                ? e.message
                : "うまく送れませんでした。\n通信の状態を確かめて、もう一度お試しください。",
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _isLoadingHistory = false;
      });

      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('ai_history')
        .doc(widget.chatId)
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
        backgroundColor: context.pal.page,

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
            child: Text(
              "AIサポート",
              style: TextStyle(
                color: context.pal.text,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          centerTitle: false,
          backgroundColor: context.pal.card,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: IconButton(
                icon: Icon(Icons.history, color: context.pal.text),
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
                    padding: const EdgeInsets.fromLTRB(17, 14, 17, 24),
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

  Widget _buildAnswerCard() {
    // 前の会話を読みこんでいる間は、くるくるを出す
    if (_isLoadingHistory) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_messages.isEmpty) {
      return const SizedBox.shrink();
    }

    // 会話の表示は共通の部品（ai_chat_message_list.dart）
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: AiChatMessageList(messages: _messages, isLoading: _isLoading),
    );
  }
}
