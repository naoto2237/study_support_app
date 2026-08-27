import 'package:flutter/material.dart';

class ProfileEditSection2 extends StatelessWidget {
  final TextEditingController gradeController;
  final TextEditingController goalController;

  const ProfileEditSection2({
    super.key,
    required this.gradeController,
    required this.goalController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),

        const SizedBox(height: 18),

        const Text(
          "プロフィール",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 16),

        _EditField(title: "学年・職種（任意）", controller: gradeController),

        _EditField(title: "学習目標", controller: goalController),
      ],
    );
  }
}

class _EditField extends StatelessWidget {
  final String title;
  final TextEditingController controller;

  const _EditField({required this.title, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タイトル
          Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),

          const SizedBox(height: 8),

          // テキストフィールド
          TextField(
            controller: controller,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF7F7F7),

              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),

              suffixIcon: const Icon(
                Icons.edit_outlined,
                color: Colors.grey,
                size: 19,
              ),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF3D96E8),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
