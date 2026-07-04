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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ユーザー検索"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [

            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "ユーザー名を入力",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: (){
                    setState(() {
                      searchText = searchController.text;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: UserList(searchText: searchText),
            )

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

    if(searchText.isEmpty){
      return const Center(
        child: Text("検索してください"),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .where("name", isGreaterThanOrEqualTo: searchText)
          .where("name", isLessThan: "${searchText}z")
          .snapshots(),

      builder: (context, snapshot) {

        if(snapshot.hasError){
          return const Text("エラー");
        }

        if(!snapshot.hasData){
          return const CircularProgressIndicator();
        }

        final users = snapshot.data!.docs;

        if(users.isEmpty){
          return const Center(
            child: Text("ユーザーが見つかりません"),
          );
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context,index){

            final data = users[index];

            return ListTile(
              leading: CircleAvatar(
                backgroundImage:
                NetworkImage(data["icon"]),
              ),
              title: Text(data["name"]),
              subtitle: Text(data["email"]),
            );
          },
        );
      },
    );
  }
}
