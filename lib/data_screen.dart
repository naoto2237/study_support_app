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


  Future<void> save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Firebase Authenticationのユーザーを取得
      User? user = FirebaseAuth.instance.currentUser;

      // ユーザーが存在しなければ匿名ログイン
      if (user == null) {
        final UserCredential credential =
        await FirebaseAuth.instance.signInAnonymously();

        user = credential.user;
      }

      // UIDを取得できなかった場合
      if (user == null) {
        return;
      }


      // Firestoreに保存
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set({
        "uid": user.uid,
        "name": nameController.text.trim(),
        "grade": gradeController.text.trim(),
        "goal": goalController.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("保存に失敗しました: $e"),
        ),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    gradeController.dispose();
    goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("プロフィール登録"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const MainNavigationScreen(),
                ),
              );
            },
            child: const Text("スキップ"),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "名前",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "入力してください";
                  }
                  return null;
                },
              ),

              TextFormField(
                controller: gradeController,
                decoration: const InputDecoration(
                  labelText: "学年・職種",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "入力してください";
                  }
                  return null;
                },
              ),

              TextFormField(
                controller: goalController,
                decoration: const InputDecoration(
                  labelText: "学習目標",
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "入力してください";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: save,
                  child: const Text("保存"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}