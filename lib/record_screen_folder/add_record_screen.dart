import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({
    super.key,
  });

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController memoController = TextEditingController();
  bool isLoading = false;

  // Firestore保存
  Future<void> saveRecord() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      isLoading = true;
    });
    try {
      await FirebaseFirestore.instance.collection("records").add({
        "subject": subjectController.text,
        "studyTime": int.parse(
          timeController.text,
        ),
        "memo": memoController.text,
        "date": Timestamp.now(),
      });
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "保存に失敗しました $e",
          ),
        ),
      );
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    subjectController.dispose();
    timeController.dispose();
    memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF7F7F7);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final subtitleColor = isDark ? Colors.white60 : Colors.grey;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          "学習記録を追加",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: subjectController,
                style: TextStyle(color: textColor),
                cursorColor: const Color(0xFF3D96E8),
                decoration: InputDecoration(
                  labelText: "科目",
                  labelStyle: TextStyle(color: subtitleColor),
                  hintText: "例：数学、英語",
                  hintStyle: TextStyle(color: subtitleColor),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color(0xFF3D96E8),
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "科目を入力してください";
                  }
                  return null;
                },
              ),
              const SizedBox(
                height: 20,
              ),
              TextFormField(
                controller: timeController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: textColor),
                cursorColor: const Color(0xFF3D96E8),
                decoration: InputDecoration(
                  labelText: "学習時間（分）",
                  labelStyle: TextStyle(color: subtitleColor),
                  hintText: "例：60",
                  hintStyle: TextStyle(color: subtitleColor),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color(0xFF3D96E8),
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "時間を入力してください";
                  }
                  if (int.tryParse(value) == null) {
                    return "数字で入力してください";
                  }
                  return null;
                },
              ),
              const SizedBox(
                height: 20,
              ),
              TextFormField(
                controller: memoController,
                maxLines: 4,
                style: TextStyle(color: textColor),
                cursorColor: const Color(0xFF3D96E8),
                decoration: InputDecoration(
                  labelText: "メモ",
                  labelStyle: TextStyle(color: subtitleColor),
                  hintText: "学習内容を入力",
                  hintStyle: TextStyle(color: subtitleColor),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color(0xFF3D96E8),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : saveRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D96E8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                    height: 25,
                    width: 25,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                      : const Text(
                    "保存する",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}