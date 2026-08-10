import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

@override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController searchController =
  TextEditingController();

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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),

      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("ユーザー検索"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(15),

        child: Column(
          children: [

            // 検索欄
            TextField(
              controller: searchController,

              decoration: InputDecoration(
                hintText: "ユーザー名を入力",

                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),

                    onPressed: searchUsers,
                ),

                border: const OutlineInputBorder(),
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

    // まだ検索していない場合
    if (searchText.isEmpty) {
      return const Center(
        child: Text(
          "ユーザー名を入力して検索してください",
          style: TextStyle(
            color: Colors.grey,
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
            ),
          );
        }

        // 読み込み中
        if (snapshot.connectionState ==
        ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // データ取得
        final users = snapshot.data?.docs ?? [];

        // ユーザーがいない
        if (users.isEmpty) {
          return const Center(
            child: Text(
              "ユーザーが見つかりません",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          );
        }

        // ユーザー一覧
        return ListView.builder(
          itemCount: users.length,

          itemBuilder: (context, index) {

            final data = users[index].data();

            final String name =
            data["name"] ?? "名前なし";

            final String email =
            data["email"] ?? "";

            final String icon =
            data["icon"] ?? "";

            return Card(
              margin: const EdgeInsets.only(
                bottom: 10,
              ),

              child: ListTile(

                // アイコン
                leading: icon.isNotEmpty
                ? CircleAvatar(
                  backgroundImage:
                  NetworkImage(icon),
                )
                : const CircleAvatar(
                  child: Icon(Icons.person),
                ),

                // 名前
                title: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // メールアドレス
                subtitle: Text(email),

                // 右側の矢印
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
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
