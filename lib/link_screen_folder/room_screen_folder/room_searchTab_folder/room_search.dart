import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../room_space_folder/room_space.dart';

class SearchRoomTab extends StatefulWidget {
  const SearchRoomTab({super.key});

  @override
  State<SearchRoomTab> createState() =>
      _SearchRoomTabState();
}

class _SearchRoomTabState extends State<SearchRoomTab> {
  // =========================================================
  // 検索文字
  // =========================================================

  String _searchText = "";

  final TextEditingController _searchController =
  TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final bgColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF7F7F7);

    final cardColor = isDark
        ? const Color(0xFF1E1E1E)
        : Colors.white;

    final textColor = isDark
        ? Colors.white70
        : Colors.black87;

    final subtitleColor = isDark
        ? Colors.white60
        : Colors.grey;

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

              style: TextStyle(
                color: textColor,
              ),

              cursorColor:
              const Color(0xFF3D96E8),

              onChanged: (value) {
                setState(() {
                  _searchText =
                      value.trim().toLowerCase();
                });
              },

              decoration: InputDecoration(
                hintText:
                "ルーム名・資格名で検索",

                hintStyle: TextStyle(
                  color: subtitleColor,
                ),

                prefixIcon: Icon(
                  Icons.search,
                  color: subtitleColor,
                ),

                suffixIcon:
                _searchText.isNotEmpty
                    ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color:
                    subtitleColor,
                  ),

                  onPressed: () {
                    _searchController
                        .clear();

                    setState(() {
                      _searchText =
                      "";
                    });
                  },
                )
                    : null,

                filled: true,

                fillColor: cardColor,

                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    15,
                  ),

                  borderSide:
                  BorderSide(
                    color: isDark
                        ? Colors
                        .grey
                        .shade800
                        : Colors.transparent,
                  ),
                ),

                enabledBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    15,
                  ),

                  borderSide:
                  BorderSide(
                    color: isDark
                        ? Colors
                        .grey
                        .shade800
                        : Colors.transparent,
                  ),
                ),

                focusedBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    15,
                  ),

                  borderSide:
                  const BorderSide(
                    color:
                    Color(0xFF3D96E8),
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

                icon: const Icon(
                  Icons.filter_list,
                ),

                label:
                const Text("絞り込み"),

                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  cardColor,

                  foregroundColor:
                  const Color(
                    0xFF3D96E8,
                  ),

                  elevation: 0,

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      15,
                    ),

                    side: BorderSide(
                      color: isDark
                          ? Colors
                          .grey
                          .shade800
                          : const Color(
                        0xFFE5E7EB,
                      ),
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
                fontSize: 24,
                fontWeight:
                FontWeight.bold,
                color: textColor,
              ),
            ),

            const SizedBox(height: 15),

            // =================================================
            // Firestoreから公開ルームを取得
            // =================================================

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore
                  .instance
                  .collection("rooms")
                  .where(
                "isPublic",
                isEqualTo: true,
              )
                  .snapshots(),

              builder:
                  (context, snapshot) {
                // =============================================
                // 読み込み中
                // =============================================

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                    Padding(
                      padding:
                      EdgeInsets.all(30),

                      child:
                      CircularProgressIndicator(),
                    ),
                  );
                }

                // =============================================
                // エラー
                // =============================================

                if (snapshot.hasError) {
                  return Container(
                    padding:
                    const EdgeInsets.all(
                      20,
                    ),

                    decoration:
                    BoxDecoration(
                      color: cardColor,

                      borderRadius:
                      BorderRadius.circular(
                        15,
                      ),
                    ),

                    child: Text(
                      "公開ルームの取得に失敗しました\n${snapshot.error}",

                      style: TextStyle(
                        color: textColor,
                      ),
                    ),
                  );
                }

                // =============================================
                // データなし
                // =============================================

                if (!snapshot.hasData ||
                    snapshot
                        .data!
                        .docs
                        .isEmpty) {
                  return Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      vertical: 40,
                    ),

                    alignment:
                    Alignment.center,

                    decoration:
                    BoxDecoration(
                      color: cardColor,

                      borderRadius:
                      BorderRadius.circular(
                        18,
                      ),
                    ),

                    child: Column(
                      children: [
                        Icon(
                          Icons
                              .public_off,
                          size: 50,
                          color:
                          subtitleColor,
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        Text(
                          _searchText
                              .isNotEmpty
                              ? "検索結果がありません"
                              : "公開されているルームはありません",

                          style:
                          TextStyle(
                            fontSize: 16,
                            fontWeight:
                            FontWeight
                                .bold,
                            color:
                            textColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // =============================================
                // ルーム一覧
                // =============================================

                final rooms =
                snapshot.data!.docs
                    .where((doc) {
                  final data =
                  doc.data()
                  as Map<String,
                      dynamic>;

                  final title =
                  (data["title"] ??
                      "")
                      .toString()
                      .toLowerCase();

                  final description =
                  (data[
                  "description"] ??
                      "")
                      .toString()
                      .toLowerCase();

                  // 検索文字がなければ全部表示
                  if (_searchText
                      .isEmpty) {
                    return true;
                  }

                  // タイトルまたは説明に
                  // 検索文字が含まれているか
                  return title.contains(
                    _searchText,
                  ) ||
                      description
                          .contains(
                        _searchText,
                      );
                }).toList();

                // =============================================
                // 検索結果0件
                // =============================================

                if (rooms.isEmpty) {
                  return Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      vertical: 40,
                    ),

                    alignment:
                    Alignment.center,

                    decoration:
                    BoxDecoration(
                      color: cardColor,

                      borderRadius:
                      BorderRadius.circular(
                        18,
                      ),
                    ),

                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 50,
                          color:
                          subtitleColor,
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        Text(
                          "「$_searchText」に一致するルームはありません",

                          textAlign:
                          TextAlign.center,

                          style:
                          TextStyle(
                            fontSize: 16,
                            fontWeight:
                            FontWeight
                                .bold,
                            color:
                            textColor,
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
                  final aData =
                  a.data()
                  as Map<String,
                      dynamic>;

                  final bData =
                  b.data()
                  as Map<String,
                      dynamic>;

                  final aTime =
                  aData["createdAt"];

                  final bTime =
                  bData["createdAt"];

                  if (aTime == null &&
                      bTime == null) {
                    return 0;
                  }

                  if (aTime == null) {
                    return 1;
                  }

                  if (bTime == null) {
                    return -1;
                  }

                  return bTime.compareTo(
                    aTime,
                  );
                });

                // =============================================
                // カード表示
                // =============================================

                return Column(
                  children:
                  rooms.map((doc) {
                    final data =
                    doc.data()
                    as Map<String,
                        dynamic>;

                    return Padding(
                      padding:
                      const EdgeInsets
                          .only(
                        bottom: 15,
                      ),

                      child:
                      PublicRoomCard(
                        title:
                        data["title"] ??
                            "",

                        roomId:
                        doc.id,
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

// =============================================================
// 公開ルームカード
// =============================================================

class PublicRoomCard extends StatelessWidget {
  final String title;
  final String roomId;

  const PublicRoomCard({
    super.key,
    required this.title,
    required this.roomId,
  });

  // ===========================================================
  // ルーム参加
  // ===========================================================

  Future<void> _joinRoom(
      BuildContext context,
      ) async {
    try {
      // -------------------------------------------------------
      // ユーザー取得
      // -------------------------------------------------------

      User? user =
          FirebaseAuth.instance.currentUser;

      // ログインしていなければ匿名ログイン
      if (user == null) {
        final credential =
        await FirebaseAuth.instance
            .signInAnonymously();

        user = credential.user;
      }

      if (user == null) {
        throw Exception(
          "ユーザー情報を取得できませんでした",
        );
      }

      // -------------------------------------------------------
      // ルーム取得
      // -------------------------------------------------------

      final roomRef =
      FirebaseFirestore.instance
          .collection("rooms")
          .doc(roomId);

      final roomSnapshot =
      await roomRef.get();

      if (!roomSnapshot.exists) {
        throw Exception(
          "このルームは存在しません",
        );
      }

      final data =
      roomSnapshot.data()
      as Map<String, dynamic>;

      // -------------------------------------------------------
      // 公開ルームか確認
      // -------------------------------------------------------

      final bool isPublic =
          data["isPublic"] ?? false;

      if (!isPublic) {
        throw Exception(
          "このルームは非公開です",
        );
      }

      // -------------------------------------------------------
      // membersにユーザー追加
      // -------------------------------------------------------

      await roomRef
          .collection("members")
          .doc(user.uid)
          .set(
        {
          "joinedAt":
          FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      // -------------------------------------------------------
      // RoomSpaceScreenへ
      // -------------------------------------------------------

      if (!context.mounted) return;

      Navigator.push(
        context,

        MaterialPageRoute(
          builder: (_) =>
              RoomSpaceScreen(
                roomTitle:
                data["title"] ??
                    title,

                roomId: roomId,
              ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            "ルームへの参加に失敗しました\n$e",
          ),
        ),
      );
    }
  }

  // ===========================================================
  // Build
  // ===========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final cardColor = isDark
        ? const Color(0xFF1E1E1E)
        : Colors.white;

    final textColor = isDark
        ? Colors.white70
        : Colors.black87;

    final subtitleColor = isDark
        ? Colors.white60
        : Colors.grey;

    final borderColor = isDark
        ? Colors.grey.shade800
        : const Color(0xFFE5E7EB);

    return Card(
      elevation: 0,

      color: cardColor,

      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(18),

        side: BorderSide(
          color: borderColor,
          width: 1,
        ),
      ),

      child: Padding(
        padding:
        const EdgeInsets.all(16),

        child: Row(
          children: [
            // =================================================
            // アイコン
            // =================================================

            CircleAvatar(
              radius: 28,

              backgroundColor: isDark
                  ? Colors.green.withValues(
                alpha: 0.2,
              )
                  : Colors.green.shade100,

              child: const Icon(
                Icons.groups,
                color: Colors.green,
              ),
            ),

            const SizedBox(width: 15),

            // =================================================
            // ルーム情報
            // =================================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,

                children: [
                  Text(
                    title,

                    maxLines: 2,

                    overflow:
                    TextOverflow
                        .ellipsis,

                    style: TextStyle(
                      fontWeight:
                      FontWeight
                          .bold,

                      fontSize: 17,

                      color: textColor,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  // ===========================================
                  // 参加人数
                  // ===========================================

                  StreamBuilder<
                      QuerySnapshot>(
                    stream:
                    FirebaseFirestore
                        .instance
                        .collection(
                        "rooms")
                        .doc(
                        roomId)
                        .collection(
                        "members")
                        .snapshots(),

                    builder: (
                        context,
                        snapshot,
                        ) {
                      final count =
                          snapshot
                              .data
                              ?.docs
                              .length ??
                              0;

                      return Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 16,
                            color:
                            subtitleColor,
                          ),

                          const SizedBox(
                            width: 5,
                          ),

                          Text(
                            "$count人",

                            style:
                            TextStyle(
                              color:
                              subtitleColor,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            // =================================================
            // 参加ボタン
            // =================================================

            ElevatedButton(
              onPressed: () async {
                // =============================================
                // 確認ダイアログ
                // =============================================

                final result =
                await showDialog<bool>(
                  context: context,

                  builder:
                      (dialogContext) {
                    return AlertDialog(
                      backgroundColor:
                      cardColor,

                      title: Text(
                        "ルームに入る",

                        style: TextStyle(
                          color:
                          textColor,

                          fontWeight:
                          FontWeight
                              .bold,
                        ),
                      ),

                      content: Text(
                        "「$title」に入りますか？",

                        style:
                        TextStyle(
                          color:
                          subtitleColor,
                        ),
                      ),

                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(
                              dialogContext,
                              false,
                            );
                          },

                          child: Text(
                            "キャンセル",

                            style:
                            TextStyle(
                              color:
                              subtitleColor,
                            ),
                          ),
                        ),

                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(
                              dialogContext,
                              true,
                            );
                          },

                          style:
                          ElevatedButton
                              .styleFrom(
                            backgroundColor:
                            const Color(
                              0xFF3D96E8,
                            ),

                            foregroundColor:
                            Colors.white,
                          ),

                          child:
                          const Text(
                            "入る",
                          ),
                        ),
                      ],
                    );
                  },
                );

                // =============================================
                // 参加
                // =============================================

                if (result == true) {
                  if (!context.mounted) {
                    return;
                  }

                  await _joinRoom(
                    context,
                  );
                }
              },

              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(
                  0xFF3D96E8,
                ),

                foregroundColor:
                Colors.white,

                elevation: 0,

                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
              ),

              child:
              const Text("参加"),
            ),
          ],
        ),
      ),
    );
  }
}
