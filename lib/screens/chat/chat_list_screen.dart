// ======================================================================
// 【画面】チャットの相手一覧
//
// 主なクラス: ChatListScreen / _ChatRow（1人分の行）
// 開き方: ホーム・Link・学習記録の上部のチャットアイコン
// ・「友達」タブ: 友達を、最近話した順に白いカードで並べる
//     アイコン・今の名前・最後のメッセージ・時刻を出す。押すと1対1のチャット（chat_room_screen.dart）へ
//     その下に、友達以外の人との会話（users/{自分}/chats）を別のカードで出す
// ・「探す」タブ: 友達でないユーザーを、名前かユーザーIDの最初の文字で探す。押すとその人のページへ
//     （友達申請やメッセージは、相手のページから行う）
// ・最後のメッセージと時刻は users/{自分}/chats/{相手} の lastMessage・updatedAt
//   （chat_room_screen.dart で送ったときに書く）
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_support_app/screens/chat/chat_room_screen.dart';
import 'package:study_support_app/screens/link/user_profile_screen.dart';
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/theme/app_palette.dart';
import 'package:study_support_app/theme/empty_message.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  String _searchText = "";

  // 探した結果（入力が変わるたびに作りなおす）
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>? _searchFuture;

  late TabController _tabController;

  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  // Stream は1回だけ作る（タブの切りかえや入力で、読みなおさない）
  Stream<QuerySnapshot<Map<String, dynamic>>>? _friends;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _chats;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    // 「探す」から「友達」へ移動したら検索をリセット
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _tabController.index == 0) {
        _searchController.clear();
        _setSearchText("");
      }
    });

    final uid = _uid;

    if (uid != null) {
      final me = FirebaseFirestore.instance.collection('users').doc(uid);
      _friends = me.collection('friends').snapshots();
      _chats = me.collection('chats').snapshots();
    }
  }

  // 入力が変わったら、探しなおす
  void _setSearchText(String value) {
    final text = value.trim();

    setState(() {
      _searchText = text;
      _searchFuture = text.isEmpty ? null : _searchUsers(text);
    });
  }

  // 名前・ユーザーIDが、入れた文字で始まる人を探す
  // （ユーザーIDは「@」つきで保存されている人と、つかずに保存されている人がいるので両方で探す。
  //   Firestore の仕組みで、言葉の途中の部分からは探せない）
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _searchUsers(
    String text,
  ) async {
    final users = FirebaseFirestore.instance.collection('users');

    Future<QuerySnapshot<Map<String, dynamic>>> startsWith(
      String field,
      String value,
    ) {
      return users
          .where(field, isGreaterThanOrEqualTo: value)
          .where(field, isLessThan: '$value')
          .limit(20)
          .get();
    }

    final withoutAt = text.startsWith('@') ? text.substring(1) : text;

    final snapshots = await Future.wait([
      startsWith('name', text),
      if (withoutAt.isNotEmpty) startsWith('userId', '@$withoutAt'),
      if (withoutAt.isNotEmpty) startsWith('userId', withoutAt),
    ]);

    // 同じ人が何度も出ないようにまとめる
    final found = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final snapshot in snapshots) {
      for (final doc in snapshot.docs) {
        found[doc.id] = doc;
      }
    }

    return found.values.toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final uid = _uid;

    return Scaffold(
      backgroundColor: p.page,

      appBar: AppBar(
        centerTitle: false,
        backgroundColor: p.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        title: Transform.translate(
          offset: const Offset(-19, 0),
          child: Text(
            "チャット",
            style: TextStyle(
              color: p.text,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        iconTheme: IconThemeData(color: p.text),

        // ======================================================
        // タブ
        // ======================================================
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: p.card,
            child: TabBar(
              controller: _tabController,

              // 選んだタブの下線は、タブの幅いっぱいの長い線にする
              // （学習記録・ルームのタブと同じ）
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(color: AppColors.primary, width: 3),
              ),
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              dividerColor: p.divider,

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

      body: uid == null
          ? const EmptyMessage(icon: Icons.login_rounded, text: 'ログインしてください')
          : TabBarView(
              controller: _tabController,
              children: [
                // 左タブ：友達（と、友達以外との会話）
                _buildTalkList(),

                // 右タブ：ユーザー検索
                Column(
                  children: [
                    _buildSearchBar(),
                    Expanded(
                      child: _searchText.isEmpty
                          ? const EmptyMessage(
                              icon: Icons.person_search_outlined,
                              text: '名前かユーザーIDを入力して\nチャットする相手を探しましょう',
                            )
                          : _buildSearchResults(uid, _searchText),
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
  // ユーザー検索（user_search_screen.dart）の検索欄と同じ見た目：
  // 白い丸い面だけで浮かせ、入力中だけ青い枠
  Widget _buildSearchBar() {
    final p = context.pal;

    OutlineInputBorder pill(Color color, double width) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: width == 0
            ? BorderSide.none
            : BorderSide(color: color, width: width),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 14, 17, 8),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: p.text, fontSize: 15),
        cursorColor: AppColors.primary,
        textInputAction: TextInputAction.search,
        onChanged: _setSearchText,
        decoration: InputDecoration(
          hintText: '名前かユーザーIDで検索',
          hintStyle: TextStyle(color: p.muted, fontSize: 15),
          filled: true,
          fillColor: p.card,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 14,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 4),
            child: Icon(Icons.search_rounded, color: p.muted),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 44),
          suffixIcon: _searchText.isNotEmpty
              ? IconButton(
                  tooltip: "消す",
                  icon: Icon(Icons.cancel_rounded, size: 20, color: p.muted),
                  onPressed: () {
                    _searchController.clear();
                    _setSearchText("");
                  },
                )
              : null,
          border: pill(Colors.transparent, 0),
          enabledBorder: pill(Colors.transparent, 0),
          focusedBorder: pill(AppColors.primary, 1.5),
        ),
      ),
    );
  }

  // =====================================================
  // 左タブ：友達（最近話した順）＋ 友達以外との会話
  // =====================================================
  Widget _buildTalkList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _friends,
      builder: (context, friendSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _chats,
          builder: (context, chatSnapshot) {
            if (friendSnapshot.hasError) {
              return const EmptyMessage(
                icon: Icons.cloud_off_rounded,
                text: '友達一覧を取得できませんでした',
              );
            }

            if (!friendSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            // 相手ごとの会話の記録（最後のメッセージ・時刻）
            final chatById = <String, Map<String, dynamic>>{
              for (final doc in chatSnapshot.data?.docs ?? [])
                doc.id: doc.data(),
            };

            final friends = friendSnapshot.data!.docs.map((doc) {
              final id = (doc.data()['userId'] ?? doc.id).toString();
              return _Talk(
                userId: id,
                savedName: (doc.data()['username'] ?? 'ユーザー').toString(),
                chat: chatById[id],
              );
            }).toList();

            final friendIds = friends.map((t) => t.userId).toSet();

            final others = chatById.entries
                .where((e) => !friendIds.contains(e.key))
                .map(
                  (e) => _Talk(userId: e.key, savedName: 'ユーザー', chat: e.value),
                )
                .toList();

            // 最近話した順（まだ話していない友達は、そのあと）
            friends.sort((a, b) => b.sortTime.compareTo(a.sortTime));
            others.sort((a, b) => b.sortTime.compareTo(a.sortTime));

            if (friends.isEmpty && others.isEmpty) {
              return const EmptyMessage(
                icon: Icons.people_outline_rounded,
                text: 'まだ友達がいません',
                subText: '「探す」から学習仲間を見つけましょう',
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                if (friends.isNotEmpty)
                  _Section(
                    title: '友達',
                    children: [
                      for (int i = 0; i < friends.length; i++)
                        _ChatRow(
                          talk: friends[i],
                          showDivider: i < friends.length - 1,
                        ),
                    ],
                  ),

                if (friends.isNotEmpty && others.isNotEmpty)
                  const SizedBox(height: 20),

                if (others.isNotEmpty)
                  _Section(
                    title: '友達以外からのメッセージ',
                    children: [
                      for (int i = 0; i < others.length; i++)
                        _ChatRow(
                          talk: others[i],
                          showDivider: i < others.length - 1,
                        ),
                    ],
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // =====================================================
  // 右タブ：友達ではないユーザーを検索（名前かユーザーIDの最初の文字で探す）
  // =====================================================
  Widget _buildSearchResults(String uid, String searchText) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _friends,
      builder: (context, friendSnapshot) {
        final friendIds = (friendSnapshot.data?.docs ?? [])
            .map((doc) => (doc.data()['userId'] ?? doc.id).toString())
            .toSet();

        return FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          future: _searchFuture,
          builder: (context, userSnapshot) {
            if (userSnapshot.hasError) {
              return const EmptyMessage(
                icon: Icons.cloud_off_rounded,
                text: 'ユーザーの検索に失敗しました',
              );
            }

            if (!userSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            // 自分と友達を除く
            final users = userSnapshot.data!
                .where((doc) => doc.id != uid && !friendIds.contains(doc.id))
                .toList();

            if (users.isEmpty) {
              return const EmptyMessage(
                icon: Icons.search_off_rounded,
                text: 'ユーザーが見つかりませんでした',
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _Section(
                  children: [
                    for (int i = 0; i < users.length; i++)
                      _ChatRow(
                        talk: _Talk(
                          userId: users[i].id,
                          savedName: 'ユーザー',
                          chat: null,
                        ),
                        showDivider: i < users.length - 1,
                        openProfile: true,
                      ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ======================================================
// 1人分のデータ（相手と、会話の記録）
// ======================================================

class _Talk {
  final String userId;
  final String savedName;
  final Map<String, dynamic>? chat;

  const _Talk({
    required this.userId,
    required this.savedName,
    required this.chat,
  });

  String get lastMessage => (chat?['lastMessage'] ?? '').toString();

  DateTime? get updatedAt {
    final t = chat?['updatedAt'];
    if (t is Timestamp) return t.toDate();
    // 送った直後で、まだ時刻が入っていないとき
    return chat != null ? DateTime.now() : null;
  }

  DateTime get sortTime => updatedAt ?? DateTime(2000);
}

// ======================================================
// 見出しと、白いカード（枠つき・角丸16）
// ======================================================

class _Section extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _Section({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: p.secondary,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ======================================================
// 1人分の行
// 左にアイコン、まん中に名前と最後のメッセージ（なければ ID）、右に時刻
// 押すとチャットを開く（探すタブでは、相手のページを開く）
// ======================================================

class _ChatRow extends StatelessWidget {
  final _Talk talk;
  final bool showDivider;
  final bool openProfile;

  const _ChatRow({
    required this.talk,
    required this.showDivider,
    this.openProfile = false,
  });

  // 今日なら「14:05」、昨日なら「昨日」、それより前は「11/3」
  static String _timeText(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);

    if (day == today) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
    if (today.difference(day).inDays == 1) return '昨日';

    return '${time.month}/${time.day}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      // 相手の今の名前・アイコン
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(talk.userId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        final String name =
            (data?['name'] ?? data?['username'] ?? talk.savedName).toString();
        final String id = (data?['userId'] ?? '').toString();
        final String icon = (data?['icon'] ?? '').toString();

        final String sub = talk.lastMessage.isNotEmpty
            ? talk.lastMessage
            : (openProfile ? id : 'まだメッセージはありません');

        final time = talk.updatedAt;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => openProfile
                    ? UserProfileScreen(userId: talk.userId)
                    : ChatRoomScreen(userName: name, userId: talk.userId),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: showDivider
                ? BoxDecoration(
                    border: Border(bottom: BorderSide(color: p.divider)),
                  )
                : null,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: p.primarySoft,
                  backgroundImage: icon.isNotEmpty ? NetworkImage(icon) : null,
                  child: icon.isEmpty
                      ? const Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 27,
                        )
                      : null,
                ),

                const SizedBox(width: 12),

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
                          color: p.text,
                        ),
                      ),
                      if (sub.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: talk.lastMessage.isNotEmpty
                                ? p.secondary
                                : p.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                if (time != null && !openProfile)
                  Text(
                    _timeText(time),
                    style: TextStyle(fontSize: 12, color: p.muted),
                  )
                else
                  Icon(Icons.chevron_right_rounded, color: p.muted, size: 22),
              ],
            ),
          ),
        );
      },
    );
  }
}
