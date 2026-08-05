import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_support_app/home_screen_folder/home_screen.dart';
import 'package:study_support_app/main.dart';

import 'home_screen_folder/home_screen.dart';

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

    if(!_formKey.currentState!.validate()){
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .set({

      "name": nameController.text,

      "grade": gradeController.text,

      "goal": goalController.text,

      "createdAt": FieldValue.serverTimestamp(),

    });

    if(!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("プロフィール登録"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Form(

          key: _formKey,

          child: Column(

            children: [

              TextFormField(
                controller: nameController,
                decoration:
                const InputDecoration(labelText: "名前"),
                validator: (v)=>
                v!.isEmpty ? "入力してください" : null,
              ),

              TextFormField(
                controller: gradeController,
                decoration:
                const InputDecoration(
                    labelText: "学年・職種"),
                validator: (v)=>
                v!.isEmpty ? "入力してください" : null,
              ),

              TextFormField(
                controller: goalController,
                decoration:
                const InputDecoration(
                    labelText: "学習目標"),
                maxLines: 3,
                validator: (v)=>
                v!.isEmpty ? "入力してください" : null,
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