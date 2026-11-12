// ======================================================================
// 【画面】ユーザー検索
//
// 主なクラス: UserSearchScreen / UserList
// 開き方: Link 画面の「ユーザー検索」
// ・ユーザーを検索し、タップで相手のプロフィール（user_profile_screen.dart）へ
// ======================================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_support_app/screens/link/user_profile_screen.dart';
import 'dart:async';
import 'package:study_support_app/screens/notification/notification_screen.dart';
import 'package:study_support_app/theme/app_colors.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController searchController = TextEditingController();

  String searchText = "";

  Timer? _searchTimer;

  @override
  void dispose() {
    searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void searchUsers() {
    setState(() {
      searchText = searchController.text.trim();
    });
  }

  // リアルタイム検索
  void onSearchChanged(String value) {
    _searchTimer?.cancel();

    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      setState(() {
        searchText = value.trim();
      });
    });
  }

  // 入力欄の×で、文字と検索結果を消す
  void _clearSearch() {
    _searchTimer?.cancel();
    searchController.clear();
    setState(() {
      searchText = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : AppColors.background;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final fieldColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final hintColor = isDark ? Colors.white38 : Colors.black38;

    // 丸い入力欄の枠（ふだんは薄い線、入力中は青い線）
    OutlineInputBorder pill(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: width == 0
          ? BorderSide.none
          : BorderSide(color: color, width: width),
    );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textColor),
        titleSpacing: 0,
        title: Text(
          "ユーザー検索",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: IconButton(
              icon: Icon(Icons.notifications_none, color: textColor),
              // 通知画面へ
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(17, 14, 17, 0),
        child: Column(
          children: [
            // ==========================================
            // 検索欄（丸い形。文字があるときは右に×）
            // ==========================================
            TextField(
              controller: searchController,
              style: TextStyle(color: textColor, fontSize: 15),
              cursorColor: AppColors.primary,
              textInputAction: TextInputAction.search,

              decoration: InputDecoration(
                hintText: "ユーザー名 または ユーザーID",
                hintStyle: TextStyle(color: hintColor, fontSize: 15),
                filled: true,
                fillColor: fieldColor,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 14,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 4),
                  child: Icon(Icons.search_rounded, color: hintColor),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 44),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: "消す",
                        onPressed: _clearSearch,
                        icon: Icon(
                          Icons.cancel_rounded,
                          size: 20,
                          color: hintColor,
                        ),
                      ),
                // ふだんは枠線なし（白い面だけで浮かせる）。入力中は青い枠
                border: pill(Colors.transparent, 0),
                enabledBorder: pill(Colors.transparent, 0),
                focusedBorder: pill(AppColors.primary, 1.5),
              ),

              // 入力と同時に検索（×を出し入れするため、入力のたびに画面も更新）
              onChanged: (value) {
                setState(() {});
                onSearchChanged(value);
              },
            ),

            const SizedBox(height: 16),

            // ==========================================
            // 検索結果
            // ==========================================
            Expanded(child: UserList(searchText: searchText)),
          ],
        ),
      ),
    );
  }
}

class UserList extends StatelessWidget {
  final String searchText;

  const UserList({super.key, required this.searchText});

  static const Color _blue = AppColors.primary;

  // ==========================================
  // ユーザー検索
  // ==========================================
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  searchUsers() async {
    final firestore = FirebaseFirestore.instance;

    // ------------------------------------------
    // 名前で検索
    // ------------------------------------------
    final nameSnapshot = await firestore
        .collection("users")
        .where("name", isGreaterThanOrEqualTo: searchText)
        .where("name", isLessThan: "$searchText\uf8ff")
        .get();

    // ------------------------------------------
    // ユーザーIDで検索
    // ------------------------------------------
    final userIdSnapshot = await firestore
        .collection("users")
        .where("userId", isGreaterThanOrEqualTo: searchText)
        .where("userId", isLessThan: "$searchText\uf8ff")
        .get();

    // ------------------------------------------
    // 検索結果を結合
    // ------------------------------------------
    final Map<String, QueryDocumentSnapshot<Map<String, dynamic>>> resultMap =
        {};

    // 名前検索の結果
    for (final doc in nameSnapshot.docs) {
      resultMap[doc.id] = doc;
    }

    // ユーザーID検索の結果
    for (final doc in userIdSnapshot.docs) {
      resultMap[doc.id] = doc;
    }

    return resultMap.values.toList();
  }

  // 結果がないときなどの案内（上のほうに出す）
  Widget _buildMessage({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Align(
      alignment: const Alignment(0, -0.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? _blue.withValues(alpha: 0.18)
                  : AppColors.primarySoft,
            ),
            child: Icon(icon, color: _blue, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: isDark ? Colors.white60 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final textColor = isDark ? Colors.white70 : Colors.black87;

    final subtitleColor = isDark ? Colors.white60 : Colors.black45;

    final borderColor = isDark ? Colors.grey.shade800 : AppColors.border;

    final dividerColor = isDark ? Colors.grey.shade800 : AppColors.divider;

    // ==========================================
    // まだ検索していない場合
    // ==========================================
    if (searchText.isEmpty) {
      return _buildMessage(
        icon: Icons.person_search_outlined,
        text: "ユーザー名またはユーザーIDを入力して\n学習仲間を探しましょう",
        isDark: isDark,
      );
    }

    // ==========================================
    // 検索実行
    // ==========================================
    return FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      future: searchUsers(),
      builder: (context, snapshot) {
        // ------------------------------------------
        // エラー
        // ------------------------------------------
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "エラーが発生しました\n${snapshot.error}",
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor),
            ),
          );
        }

        // ------------------------------------------
        // 読み込み中
        // ------------------------------------------
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // ------------------------------------------
        // 検索結果
        // ------------------------------------------
        final users = snapshot.data ?? [];

        // ------------------------------------------
        // ユーザーが見つからない
        // ------------------------------------------
        if (users.isEmpty) {
          return _buildMessage(
            icon: Icons.search_off_rounded,
            text: "「$searchText」に一致するユーザーは\n見つかりませんでした",
            isDark: isDark,
          );
        }

        // ==========================================
        // ユーザー一覧（1つのカードにまとめ、行の間を線で区切る）
        // ==========================================
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                "${users.length}件",
                style: TextStyle(fontSize: 12, color: subtitleColor),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
              ),

              // 枠線は中身の上に描く（中の行の色で、角の枠線が隠れないように）
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var index = 0; index < users.length; index++) ...[
                    _buildUserRow(
                      context: context,
                      doc: users[index],
                      isDark: isDark,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                    ),
                    if (index < users.length - 1)
                      Container(
                        height: 1,
                        margin: const EdgeInsets.only(left: 70),
                        color: dividerColor,
                      ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // ユーザー1人分の行（アイコン・名前・ID・メール・矢印。行全体を押せる）
  // ==========================================
  Widget _buildUserRow({
    required BuildContext context,
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
    required bool isDark,
    required Color textColor,
    required Color subtitleColor,
  }) {
    final data = doc.data();

    final String name = data["name"] ?? "名前なし";
    final String userId = data["userId"] ?? "";
    final String email = data["email"] ?? "";
    final String icon = data["icon"] ?? "";

    return Material(
      color: Colors.transparent,
      child: InkWell(
        // ==========================================
        // プロフィール画面へ
        // ==========================================
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileScreen(userId: doc.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              // ==========================================
              // アイコン
              // ==========================================
              icon.isNotEmpty
                  ? CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage(icon),
                    )
                  : CircleAvatar(
                      radius: 22,
                      backgroundColor: isDark
                          ? _blue.withValues(alpha: 0.2)
                          : AppColors.primarySoft,
                      child: const Icon(Icons.person, color: _blue),
                    ),

              const SizedBox(width: 12),

              // ==========================================
              // 名前・ユーザーID・メール
              // ==========================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    if (userId.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        // IDの頭に「@」が付いていないときだけ付ける
                        userId.startsWith("@") ? userId : "@$userId",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: subtitleColor),
                      ),
                    ],
                    if (email.isNotEmpty)
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: subtitleColor),
                      ),
                  ],
                ),
              ),

              // ==========================================
              // 矢印
              // ==========================================
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
