// ======================================================================
// 【タブ】ルーム画面の「検索」タブ（公開ルームを探す）
//
// 主なクラス: SearchRoomTab
// ・公開ルームの検索・絞り込み（1枚ずつのカードは public_room_card.dart）
// ・旧ファイル名: room_search.dart
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:study_support_app/screens/link/room/search_tab/public_room_card.dart';

class SearchRoomTab extends StatefulWidget {
  const SearchRoomTab({super.key});

  @override
  State<SearchRoomTab> createState() => _SearchRoomTabState();
}

class _SearchRoomTabState extends State<SearchRoomTab> {
  // =========================================================
  // 検索文字
  // =========================================================

  String _searchText = "";

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF7F7F7);

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final textColor = isDark ? Colors.white70 : Colors.black87;

    final subtitleColor = isDark ? Colors.white60 : Colors.grey;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },

      child: Container(
        color: bgColor,

        child: ListView(
          padding: const EdgeInsets.all(20),

          children: [
            // =================================================
            // 検索バー
            // =================================================
            TextField(
              controller: _searchController,

              style: TextStyle(color: textColor),

              cursorColor: const Color(0xFF3D96E8),

              onChanged: (value) {
                setState(() {
                  _searchText = value.trim().toLowerCase();
                });
              },

              decoration: InputDecoration(
                hintText: "ルーム名・資格名で検索",

                hintStyle: TextStyle(color: subtitleColor),

                prefixIcon: Icon(Icons.search, color: subtitleColor),

                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: subtitleColor),

                        onPressed: () {
                          _searchController.clear();

                          setState(() {
                            _searchText = "";
                          });
                        },
                      )
                    : null,

                filled: true,

                fillColor: cardColor,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),

                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade800 : Colors.transparent,
                  ),
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),

                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade800 : Colors.transparent,
                  ),
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

            const SizedBox(height: 20),

            // =================================================
            // 絞り込み
            // =================================================
            SizedBox(
              height: 45,

              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO:
                  // 絞り込み機能
                },

                icon: const Icon(Icons.filter_list),

                label: const Text("絞り込み"),

                style: ElevatedButton.styleFrom(
                  backgroundColor: cardColor,

                  foregroundColor: const Color(0xFF3D96E8),

                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),

                    side: BorderSide(
                      color: isDark
                          ? Colors.grey.shade800
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // =================================================
            // 公開ルーム
            // =================================================
            Text(
              "公開ルーム",

              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            const SizedBox(height: 15),

            // =================================================
            // Firestoreから公開ルームを取得
            // =================================================
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("rooms")
                  .where("isPublic", isEqualTo: true)
                  .snapshots(),

              builder: (context, snapshot) {
                // =============================================
                // 読み込み中
                // =============================================

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),

                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                // =============================================
                // エラー
                // =============================================

                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(20),

                    decoration: BoxDecoration(
                      color: cardColor,

                      borderRadius: BorderRadius.circular(15),
                    ),

                    child: Text(
                      "公開ルームの取得に失敗しました\n${snapshot.error}",

                      style: TextStyle(color: textColor),
                    ),
                  );
                }

                // =============================================
                // データなし
                // =============================================

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),

                    alignment: Alignment.center,

                    decoration: BoxDecoration(
                      color: cardColor,

                      borderRadius: BorderRadius.circular(18),
                    ),

                    child: Column(
                      children: [
                        Icon(Icons.public_off, size: 50, color: subtitleColor),

                        const SizedBox(height: 12),

                        Text(
                          _searchText.isNotEmpty
                              ? "検索結果がありません"
                              : "公開されているルームはありません",

                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // =============================================
                // ルーム一覧
                // =============================================

                final rooms = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final title = (data["title"] ?? "").toString().toLowerCase();

                  final description = (data["description"] ?? "")
                      .toString()
                      .toLowerCase();

                  // 検索文字がなければ全部表示
                  if (_searchText.isEmpty) {
                    return true;
                  }

                  // タイトルまたは説明に
                  // 検索文字が含まれているか
                  return title.contains(_searchText) ||
                      description.contains(_searchText);
                }).toList();

                // =============================================
                // 検索結果0件
                // =============================================

                if (rooms.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),

                    alignment: Alignment.center,

                    decoration: BoxDecoration(
                      color: cardColor,

                      borderRadius: BorderRadius.circular(18),
                    ),

                    child: Column(
                      children: [
                        Icon(Icons.search_off, size: 50, color: subtitleColor),

                        const SizedBox(height: 12),

                        Text(
                          "「$_searchText」に一致するルームはありません",

                          textAlign: TextAlign.center,

                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // =============================================
                // 新しい順
                // =============================================

                rooms.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;

                  final bData = b.data() as Map<String, dynamic>;

                  final aTime = aData["createdAt"];

                  final bTime = bData["createdAt"];

                  if (aTime == null && bTime == null) {
                    return 0;
                  }

                  if (aTime == null) {
                    return 1;
                  }

                  if (bTime == null) {
                    return -1;
                  }

                  return bTime.compareTo(aTime);
                });

                // =============================================
                // カード表示
                // =============================================

                return Column(
                  children: rooms.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),

                      child: PublicRoomCard(
                        title: data["title"] ?? "",

                        roomId: doc.id,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
