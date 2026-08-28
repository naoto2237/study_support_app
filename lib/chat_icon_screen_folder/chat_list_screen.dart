import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  String _searchText = "";

  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    // ユーザータブから移動したら検索をリセット
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _tabController.index == 0) {
        _searchController.clear();

        setState(() {
          _searchText = "";
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Scaffold(body: Center(child: Text('ログインが必要です')));
    }

    final backgroundColor = isDark
        ? const Color(0xFF121212)
        : Color(0xFFF7F7F7);

    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        centerTitle: false,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,

        elevation: 0,
        surfaceTintColor: Colors.transparent,

        title: Transform.translate(
          offset: const Offset(-19, 0),
          child: const Text(
            "チャット",
            style: TextStyle(
              color: Colors.black87,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),

        // ======================================================
        // タブ
        // ======================================================
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,

            child: TabBar(
              controller: _tabController,

              indicatorSize: TabBarIndicatorSize.tab,

              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(color: Color(0xFF258EDB), width: 3),
              ),

              labelColor: const Color(0xFF258EDB),

              unselectedLabelColor: isDark ? Colors.grey : Colors.grey,

              tabs: const [
                Tab(
                  child: Text(
                    "友達",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),

                Tab(
                  child: Text(
                    "探す",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      body: TabBarView(
        controller: _tabController,

        children: [
          // ==========================================
          // 左タブ：友達一覧
          // ==========================================
          _buildFriendsList(currentUserId, isDark),

          // ==========================================
          // 右タブ：ユーザー検索
          // ==========================================
          Column(
            children: [
              _buildSearchBar(isDark),

              Expanded(
                child: _searchText.isEmpty
                    ? const Center(
                        child: Text(
                          'ユーザー名を検索してください',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : _buildUserSearchResultList(
                        currentUserId,
                        _searchText,
                        isDark,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // 検索バー
  // =====================================================
  Widget _buildSearchBar(bool isDark) {
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      padding: const EdgeInsets.all(12),

      child: TextField(
        controller: _searchController,

        style: TextStyle(color: textColor),

        onChanged: (value) {
          setState(() {
            _searchText = value.trim();
          });
        },

        decoration: InputDecoration(
          hintText: 'ユーザー名で検索...',

          hintStyle: TextStyle(
            color: isDark ? Colors.grey[500] : Colors.grey[500],
          ),

          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.grey[400] : Colors.grey,
          ),

          suffixIcon: _searchText.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: isDark ? Colors.grey[400] : Colors.grey,
                  ),

                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _searchText = "";
                    });
                  },
                )
              : null,

          filled: true,

          fillColor: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF7F7F7),

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 0,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),

            borderSide: BorderSide(color: borderColor),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),

            borderSide: BorderSide(color: borderColor),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),

            borderSide: const BorderSide(color: Color(0xFF258EDB), width: 1.5),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // 左タブ：友達一覧
  // =====================================================
  Widget _buildFriendsList(String currentUserId, bool isDark) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .snapshots(),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('友達一覧を取得できませんでした'));
        }

        final friends = snapshot.data?.docs ?? [];

        if (friends.isEmpty) {
          return const Center(
            child: Text('まだ友達がいません', style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          itemCount: friends.length,

          itemBuilder: (context, index) {
            final friendData = friends[index].data();

            final friendId = friendData['userId'] ?? friends[index].id;

            final friendName =
                friendData['username'] ?? friendData['name'] ?? '名前なし';

            // =====================================
            // 2人専用のroomIdを作成
            // =====================================
            final ids = [currentUserId, friendId];

            ids.sort();

            final roomId = '${ids[0]}_${ids[1]}';

            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),

                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF258EDB).withOpacity(0.12),

                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF258EDB),
                      size: 27,
                    ),
                  ),

                  title: Text(
                    friendName,

                    style: TextStyle(
                      fontWeight: FontWeight.bold,

                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),

                  subtitle: const Padding(
                    padding: EdgeInsets.only(top: 4),

                    child: Text(
                      'タップしてチャットを開く',

                      style: TextStyle(color: Colors.grey),
                    ),
                  ),

                  onTap: () {
                    // 自分と友達のUIDを使って、共通のチャットルームIDを作成
                    final ids = [currentUserId, friendId];

                    ids.sort();

                    final roomId = '${ids[0]}_${ids[1]}';

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(
                          userName: friendName,
                          userId: friendId,
                        )
                      ),
                    );
                  },
                ),

                Divider(
                  height: 1,

                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =====================================================
  // 右タブ：友達ではないユーザーを検索
  // =====================================================
  Widget _buildUserSearchResultList(
    String currentUserId,
    String searchText,
    bool isDark,
  ) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // ===============================================
      // まず友達一覧を取得
      // ===============================================
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .snapshots(),

      builder: (context, friendSnapshot) {
        if (friendSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // ===============================================
        // 友達のUID一覧を作成
        // ===============================================
        final friendIds =
            friendSnapshot.data?.docs
                .map((doc) => doc.data()['userId'] ?? doc.id)
                .toSet() ??
            <String>{};

        // ===============================================
        // ユーザー名を検索
        // ===============================================
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('name', isGreaterThanOrEqualTo: searchText)
              .where('name', isLessThan: '$searchText\uf8ff')
              .snapshots(),

          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (userSnapshot.hasError) {
              return const Center(child: Text('ユーザーの検索に失敗しました'));
            }

            final users = userSnapshot.data?.docs ?? [];

            // ===========================================
            // 自分と友達を除外
            // ===========================================
            final filteredUsers = users.where((doc) {
              final userId = doc.id;

              return userId != currentUserId && !friendIds.contains(userId);
            }).toList();

            if (filteredUsers.isEmpty) {
              return const Center(
                child: Text(
                  'ユーザーが見つかりません',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              itemCount: filteredUsers.length,

              itemBuilder: (context, index) {
                final doc = filteredUsers[index];

                final data = doc.data();

                final userId = doc.id;

                final userName = data['username'] ?? data['name'] ?? '名前なし';

                final icon = data['icon'] ?? '';

                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),

                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(
                          0xFF258EDB,
                        ).withOpacity(0.12),

                        backgroundImage: icon.isNotEmpty
                            ? NetworkImage(icon)
                            : null,

                        child: icon.isEmpty
                            ? const Icon(
                                Icons.person,
                                color: Color(0xFF258EDB),
                                size: 27,
                              )
                            : null,
                      ),

                      title: Text(
                        userName,

                        style: TextStyle(
                          fontWeight: FontWeight.bold,

                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),

                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),

                      onTap: () {},
                    ),

                    Divider(
                      height: 1,

                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
