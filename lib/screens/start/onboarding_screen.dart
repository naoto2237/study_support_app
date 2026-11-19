// ======================================================================
// 【画面】初回登録画面（ユーザーネーム・学年・学習目標・ユーザーID）
// ・学年・職種と学習目標は、自由入力ではなく一覧からえらぶ（絞り込みに使うため）
//
// 主なクラス: OnboardingScreen
// 開き方: はじめの画面（welcome_screen.dart）で「ゲスト」か「Google」をえらんだあと
// ・上に「プロフィールを入力」、その下の白いカードに4つの入力欄、いちばん下に「保存してはじめる」
// ・入力内容を Firestore の users に保存し、使い方の画面（tutorial_screen.dart）へ進む
// ・Google と連携してきた人には、上に「Google と連携しました」を出し、名前を入れておく
// ・うまくいかなかったことは、赤い文字で出す（ユーザーIDのことは、その欄の下に出す）
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_support_app/theme/app_palette.dart';
import 'package:study_support_app/screens/start/tutorial_screen.dart';
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/services/google_account.dart';
import 'package:study_support_app/data/profile_options.dart';
import 'package:study_support_app/theme/option_picker.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const Color _blue = AppColors.primary;

  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  // 学年・職種と学習目標は、一覧からえらぶ（profile_options.dart）
  String? _grade;
  String? _goal;
  final userIdController = TextEditingController();

  // 保存中（ボタンを2回押せないようにする）
  bool _isSaving = false;

  // 保存できなかったときに、ボタンの上に赤い文字で出す文（なければ出さない）
  String? _errorText;

  // ユーザーIDの欄の下に出す文（すでに使われているときなど）
  String? _userIdError;

  // はじめの画面で Google と連携してきたか（連携していたら、上に出す）
  final bool _googleLinked = GoogleAccount.isLinked;

  @override
  void initState() {
    super.initState();

    // Google と連携してきた人は、Google の名前を入れておく（あとで書きかえられる）
    final googleName =
        FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
    if (_googleLinked && googleName.isNotEmpty) {
      nameController.text = googleName.length > 20
          ? googleName.substring(0, 20)
          : googleName;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    userIdController.dispose();
    super.dispose();
  }

  // 入れたユーザーIDを、保存する形（@から始まる）にそろえる
  String get _userId {
    final text = userIdController.text.trim();
    if (text.isEmpty) return '';
    return text.startsWith('@') ? text : '@$text';
  }

  // ======================================================
  // 保存してはじめる
  // ======================================================

  Future<void> save() async {
    if (_isSaving) return;

    setState(() {
      _errorText = null;
      _userIdError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // ログインしていなければ、名前のないアカウント（匿名ログイン）で始める
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        final credential = await FirebaseAuth.instance.signInAnonymously();
        user = credential.user;
      }

      if (user == null) {
        throw Exception("ユーザーを用意できませんでした");
      }

      final userId = _userId;

      // ユーザーIDが、ほかの人と同じでないか
      final existingUser = await FirebaseFirestore.instance
          .collection("users")
          .where("userId", isEqualTo: userId)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        if (!mounted) return;

        setState(() => _userIdError = "このユーザーIDは、すでに使われています");
        return;
      }

      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "name": nameController.text.trim(),
        "grade": _grade,
        "goal": _goal,
        "userId": userId,
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // はじめの画面（ゲストか Google か）も閉じてから進む
      // （下に残ると、ホームなどの上の帯に「←」が出てしまうため）
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const TutorialScreen()),
        (_) => false,
      );
    } catch (e) {
      debugPrint("プロフィールの保存に失敗しました: $e");

      if (!mounted) return;

      setState(() => _errorText = "保存できませんでした。通信の状態を確かめて、もう一度お試しください");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ======================================================
  // 見た目
  // ======================================================

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Scaffold(
      backgroundColor: p.page,
      // 左上の「←」で、はじめの画面（ゲストか Google か）に戻れる
      appBar: Navigator.of(context).canPop()
          ? AppBar(
              backgroundColor: p.page,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: p.text),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: SafeArea(
        child: GestureDetector(
          // 入力欄の外を押したら、キーボードを閉じる
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Center(
            child: ConstrainedBox(
              // パソコンの広い画面でも、横に広がりすぎないようにする
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildWelcome(p),

                      const SizedBox(height: 24),

                      if (_googleLinked) ...[
                        _buildLinkedNote(p),
                        const SizedBox(height: 16),
                      ],

                      _buildFormCard(p),

                      const SizedBox(height: 8),

                      Text(
                        "※ あとから、マイページでいつでも変えられます",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: p.secondary, fontSize: 12),
                      ),

                      const SizedBox(height: 20),

                      if (_errorText != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            _errorText!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: AppColors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 上の「ようこそ」
  Widget _buildWelcome(AppPalette p) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_rounded, color: _blue, size: 36),
        ),
        const SizedBox(height: 14),
        Text(
          "プロフィールを入力",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: p.text,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "はじめに、あなたのことを教えてください",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: p.secondary),
        ),
      ],
    );
  }

  // Google と連携してきた人に出す「連携ずみ」
  Widget _buildLinkedNote(AppPalette p) {
    final email = GoogleAccount.email;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: _blue, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Google と連携しました",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: p.text,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: p.secondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4つの入力欄をまとめた白いカード
  Widget _buildFormCard(AppPalette p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildField(
            p,
            icon: Icons.person_outline_rounded,
            title: "ユーザーネーム",
            hint: "例）たろう",
            controller: nameController,
            maxLength: 20,
            validator: (value) => (value == null || value.trim().isEmpty)
                ? "ユーザーネームを入れてください"
                : null,
          ),
          _buildSelect(
            p,
            icon: Icons.school_outlined,
            title: "学年・職種",
            options: ProfileOptions.grades,
            value: _grade,
            onChanged: (v) => setState(() => _grade = v),
          ),
          _buildSelect(
            p,
            icon: Icons.flag_outlined,
            title: "学習目標",
            options: ProfileOptions.goals,
            value: _goal,
            onChanged: (v) => setState(() => _goal = v),
          ),
          _buildField(
            p,
            icon: Icons.alternate_email_rounded,
            title: "ユーザーID",
            hint: "例）study1234",
            controller: userIdController,
            maxLength: 20,
            isLast: true,
            prefixText: "@",
            note: "友達があなたを探すときに使います。ほかの人と同じIDは使えません",
            errorText: _userIdError,
            onChanged: (_) {
              if (_userIdError != null) setState(() => _userIdError = null);
            },
            validator: (value) {
              final text = (value ?? '').trim().replaceFirst('@', '');
              if (text.isEmpty) return "ユーザーIDを入れてください";
              if (text.length < 3) return "3文字以上にしてください";
              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(text)) {
                return "英字・数字・_（アンダーバー）だけ使えます";
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // 一覧からえらぶ欄1つ分（見出し・えらぶ欄）
  Widget _buildSelect(
    AppPalette p, {
    required IconData icon,
    required String title,
    required List<String> options,
    required String? value,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _blue, size: 20),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: p.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OptionField(
            title: title,
            options: options,
            value: value,
            onChanged: onChanged,
            validator: (v) =>
                (v == null || v.isEmpty) ? "$titleをえらんでください" : null,
          ),
        ],
      ),
    );
  }

  // 入力欄1つ分（見出し・入力・説明）
  Widget _buildField(
    AppPalette p, {
    required IconData icon,
    required String title,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required int maxLength,
    bool isLast = false,
    String? prefixText,
    String? note,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _blue, size: 20),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: p.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            validator: validator,
            onChanged: onChanged,
            maxLength: maxLength,
            textInputAction: isLast
                ? TextInputAction.done
                : TextInputAction.next,
            onFieldSubmitted: isLast ? (_) => save() : null,
            style: TextStyle(fontSize: 15, color: p.text),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: p.muted, fontSize: 14),
              prefixText: prefixText,
              prefixStyle: TextStyle(
                color: p.secondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              errorText: errorText,
              errorMaxLines: 2,
              errorStyle: const TextStyle(color: AppColors.red, fontSize: 12),
              helperText: note,
              helperMaxLines: 2,
              helperStyle: TextStyle(color: p.secondary, fontSize: 11.5),
              // 文字数（0/20）は出さない（上限だけかける）
              counterText: "",
              filled: true,
              fillColor: p.field,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              enabledBorder: border(p.border),
              focusedBorder: border(_blue, 2),
              errorBorder: border(AppColors.red),
              focusedErrorBorder: border(AppColors.red, 2),
            ),
          ),
        ],
      ),
    );
  }

  // 保存してはじめる
  Widget _buildSaveButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : save,
        style: ElevatedButton.styleFrom(
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _blue,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                "保存してはじめる",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
