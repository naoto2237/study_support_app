import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_support_app/main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final gradeController = TextEditingController();
  final goalController = TextEditingController();
  final userIdController = TextEditingController();

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Firebase Authenticationのユーザーを取得
      User? user = FirebaseAuth.instance.currentUser;

      // ユーザーが存在しなければ匿名ログイン
      if (user == null) {
        final UserCredential credential = await FirebaseAuth.instance
            .signInAnonymously();

        user = credential.user;
      }

      // UIDを取得できなかった場合
      if (user == null) {
        return;
      }

      // ==========================================
      // ユーザーIDを取得
      // ==========================================

      final userId = userIdController.text.trim();

      // ==========================================
      // ユーザーIDの重複チェック
      // ==========================================

      final existingUser = await FirebaseFirestore.instance
          .collection("users")
          .where("userId", isEqualTo: userId)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("このユーザーIDはすでに使用されています")));

        return;
      }

      // Firestoreに保存
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "name": nameController.text.trim(),
        "grade": gradeController.text.trim(),
        "goal": goalController.text.trim(),
        "userId": userId,
        "createdAt": FieldValue.serverTimestamp(),
      });
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("保存に失敗しました: $e")));
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    gradeController.dispose();
    goalController.dispose();
    userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF258EDB);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        title: const Text(
          "プロフィール登録",
          style: TextStyle(
            fontSize: 19, // 26 → 22
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20, // 28 → 20
            vertical: 16, // 28 → 16
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildInputSection(
                  icon: Icons.person_outline,
                  title: "ユーザーネーム",
                  hint: "例）なまえ",
                  controller: nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "入力してください";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                _buildInputSection(
                  icon: Icons.school_outlined,
                  title: "学年・職種",
                  hint: "例）大学2年 / エンジニア",
                  controller: gradeController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "入力してください";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                _buildInputSection(
                  icon: Icons.track_changes_outlined,
                  title: "学習目標",
                  hint: "例）TOEICで800点を取る",
                  controller: goalController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "入力してください";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                _buildInputSection(
                  icon: Icons.badge_outlined,
                  title: "ユーザーID",
                  hint: "例）@study1234",
                  controller: userIdController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "ユーザーIDを入力してください";
                    }

                    if (!value.trim().startsWith("@")) {
                      return "@から始めてください";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 5),

                const Padding(
                  padding: EdgeInsets.only(left: 48),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "※プロフィールは後からでも変更できます",
                      style: TextStyle(color: Colors.black54, fontSize: 11),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ユーザーIDについて
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),

                      const SizedBox(width: 10),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "ユーザーIDについて",
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 5),

                            Text(
                              "他のユーザーがあなたを見つけるときに使用されます。学習記録やプロフィールを確認するときにも使われます。",
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 11,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: const Text(
                      "保存してはじめる",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection({
    required IconData icon,
    required String title,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) {
    const primaryColor = Color(0xFF258EDB);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Icon(
            icon,
            color: primaryColor,
            size: 28, // 36 → 28
          ),
        ),

        const SizedBox(width: 12), // 20 → 12

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17, // 21 → 17
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(width: 7),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: primaryColor),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      "必須",
                      style: TextStyle(color: primaryColor, fontSize: 11),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 7),

              TextFormField(
                controller: controller,
                validator: validator,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(
                    color: Colors.black45,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.white,

                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12, // 18 → 12
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),

                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
