import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController searchController = TextEditingController();

  String searchText = "";

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void searchUsers() {
    setState(() {
      searchText = searchController.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F8F8);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          "ユーザー検索",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 19),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            // 検索欄
            TextField(
              controller: searchController,
              style: TextStyle(color: textColor),
              cursorColor: const Color(0xFF2196F3),
              decoration: InputDecoration(
                hintText: "ユーザー名を入力",
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search, color: isDark ? Colors.white60 : Colors.grey),
                  onPressed: searchUsers,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2196F3), width: 2),
                ),
              ),
              // キーボードの検索ボタンでも検索
              onSubmitted: (_) {
                searchUsers();
              },
            ),

            const SizedBox(height: 20),

            // 検索結果
            Expanded(
              child: UserList(
                searchText: searchText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserList extends StatelessWidget {
  final String searchText;

  const UserList({
    super.key,
    required this.searchText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final subtitleColor = isDark ? Colors.white60 : Colors.grey;
    final borderColor = isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB);

    // まだ検索していない場合
    if (searchText.isEmpty) {
      return Center(
        child: Text(
          "ユーザー名を入力して検索してください",
          style: TextStyle(
            color: subtitleColor,
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection("users")
      // 検索文字から始まる名前
          .where(
        "name",
        isGreaterThanOrEqualTo: searchText,
      )
          .where(
        "name",
        isLessThan: "$searchText\uf8ff",
      )
          .snapshots(),
      builder: (context, snapshot) {
        // エラー
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "エラーが発生しました\n${snapshot.error}",
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor),
            ),
          );
        }

        // 読み込み中
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // データ取得
        final users = snapshot.data?.docs ?? [];

        // ユーザーがいない
        if (users.isEmpty) {
          return Center(
            child: Text(
              "ユーザーが見つかりません",
              style: TextStyle(
                color: subtitleColor,
              ),
            ),
          );
        }

        // ユーザー一覧
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final data = users[index].data();

            final String name = data["name"] ?? "名前なし";
            final String email = data["email"] ?? "";
            final String icon = data["icon"] ?? "";

            return Card(
              elevation: 0,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor, width: 1),
              ),
              margin: const EdgeInsets.only(
                bottom: 10,
              ),
              child: ListTile(
                // アイコン
                leading: icon.isNotEmpty
                    ? CircleAvatar(
                  backgroundImage: NetworkImage(icon),
                )
                    : CircleAvatar(
                  backgroundColor: isDark ? Colors.blue.withValues(alpha: 0.2) : const Color(0xFFEAF4FF),
                  child: const Icon(Icons.person, color: Color(0xFF2196F3)),
                ),

                // 名前
                title: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                // メールアドレス
                subtitle: Text(
                  email,
                  style: TextStyle(color: subtitleColor),
                ),

                // 右側の矢印
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDark ? Colors.white60 : Colors.grey,
                ),

                onTap: () {
                  // ユーザーをタップしたときの処理
                  print(
                    "選択したユーザーID：${users[index].id}",
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}