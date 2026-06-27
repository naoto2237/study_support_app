import 'package:flutter/material.dart';

class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("学習記録"),
      ),
      body: const Center(
        child: Text("学習記録画面"),
      ),
    );
  }
}