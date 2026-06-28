import 'package:flutter/material.dart';

class QandaScreen extends StatelessWidget {
  const QandaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Q&A')),
      body: const Center(
        child: Text('Q&A画面'),
      ),
    );
  }
}