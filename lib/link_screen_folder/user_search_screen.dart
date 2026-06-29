import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

class UserModel {
  final String uid;
  final String name;
  final String email;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json["uid"],
      name: json["name"],
      email: json["email"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "uid": uid,
      "name": name,
      "email": email,
    };
  }
}

class UserSearchScreen extends StatelessWidget {
  const UserSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ユーザー検索')),


      body: const Center(
        child: Text('ユーザー検索画面'),
      ),
    );
  }
}



class UserService {

  static Future<List<UserModel>> searchUser(String keyword) async {

    final response = await http.get(
      Uri.parse(
        "https://example.com/api/users?keyword=$keyword",
      ),
    );

    final json = jsonDecode(response.body);

    return (json as List)
        .map((e) => UserModel.fromJson(e))
        .toList();
  }
}

