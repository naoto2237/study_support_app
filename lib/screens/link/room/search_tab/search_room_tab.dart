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
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/data/profile_options.dart';
import 'package:study_support_app/theme/option_picker.dart';

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

  // 絞り込み：ルームの学習目標（指定しないときは null）
  String? _goal;

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF121212) : AppColors.background;

    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final textColor = isDark ? Colors.white70 : Colors.black87;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },

      child: Container(
        color: bgColor,

        child: ListView(
          padding: const EdgeInsets.fromLTRB(17, 14, 17, 24),

          children: [
            // =================================================
            // 検索欄（丸い形）と、絞り込みのボタン
            // =================================================
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,

                    style: TextStyle(color: textColor, fontSize: 15),

                    cursorColor: AppColors.primary,

                    textInputAction: TextInputAction.search,

                    onChanged: (value) {
                      setState(() {
                        _searchText = value.trim().toLowerCase();
                      });
                    },

                    decoration: InputDecoration(
                      hintText: "ルーム名・資格名で検索",
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontSize: 15,
                      ),
                      filled: true,
                      fillColor: cardColor,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 14,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 4),
                        child: Icon(
                          Icons.search_rounded,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 44),
                      suffixIcon: _searchText.isNotEmpty
                          ? IconButton(
                              tooltip: "消す",
                              icon: Icon(
                                Icons.cancel_rounded,
                                size: 20,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              onPressed: () {
                                _searchController.clear();

                                setState(() {
                                  _searchText = "";
                                });
                              },
                            )
                          : null,
                      // ふだんは枠線なし（白い面だけで浮かせる）。入力中は青い枠
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // 絞り込み（ルームの学習目標）。えらんでいるときは青くぬる
                Material(
                  color: _goal != null ? AppColors.primary : cardColor,
                  shape: CircleBorder(
                    side: BorderSide(
                      color: _goal != null
                          ? AppColors.primary
                          : (isDark ? Colors.grey.shade800 : AppColors.border),
                    ),
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () async {
                      final picked = await showOptionPicker(
                        context,
                        title: "学習目標で絞り込む",
                        options: ProfileOptions.goals,
                        selected: _goal ?? '',
                        allowClear: true,
                      );
                      if (picked == null) return;
                      setState(() => _goal = picked.isEmpty ? null : picked);
                    },
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: Tooltip(
                        message: "絞り込み",
                        child: Icon(
                          Icons.tune_rounded,
                          color: _goal != null
                              ? Colors.white
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // =================================================
            // 公開ルーム
            // =================================================
            Row(
              children: [
                Text(
                  "公開ルーム",

                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                // 絞り込み中は、何で絞っているかを出す（×で外せる）
                if (_goal != null) ...[
                  const SizedBox(width: 10),
                  InputChip(
                    label: Text("目標：$_goal"),
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    backgroundColor: AppColors.primarySoft,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    visualDensity: VisualDensity.compact,
                    deleteIconColor: AppColors.primary,
                    onDeleted: () => setState(() => _goal = null),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 10),

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

                      border: Border.all(
                        color: isDark ? Colors.grey.shade800 : AppColors.border,
                      ),
                    ),

                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? AppColors.primary.withValues(alpha: 0.18)
                                : AppColors.primarySoft,
                          ),
                          child: Icon(
                            Icons.meeting_room_outlined,
                            size: 28,
                            color: AppColors.primary,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          _searchText.isNotEmpty
                              ? "検索結果がありません"
                              : "公開されているルームはありません",

                          style: TextStyle(fontSize: 15, color: textColor),
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

                  // 学習目標で絞り込んでいるときは、同じ目標のルームだけ
                  if (_goal != null && data["goal"] != _goal) {
                    return false;
                  }

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

                      border: Border.all(
                        color: isDark ? Colors.grey.shade800 : AppColors.border,
                      ),
                    ),

                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? AppColors.primary.withValues(alpha: 0.18)
                                : AppColors.primarySoft,
                          ),
                          child: Icon(
                            Icons.search_off,
                            size: 28,
                            color: AppColors.primary,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          _searchText.isEmpty
                              ? "この目標のルームはありません"
                              : "「$_searchText」に一致するルームはありません",

                          textAlign: TextAlign.center,

                          style: TextStyle(fontSize: 15, color: textColor),
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

                        ownerId: (data["ownerId"] ?? "").toString(),

                        description: (data["description"] ?? "").toString(),

                        goal: (data["goal"] ?? "").toString(),
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
