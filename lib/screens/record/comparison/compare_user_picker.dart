// ======================================================================
// 【部品】比較する相手を選ぶ（下から出る画面）
//
// 主な関数: showCompareUserPicker（選んだ相手 ComparePartner を返す。閉じたら null）
// 開き方: 学習記録の「他の人と比較」で「特定のユーザー」の「相手を選ぶ」
// ・上：名前かユーザーIDで探す（最初の何文字かを入れると候補が出る。「@」はあってもなくてもよい）
//   （Firestore の仕組みで、言葉の途中の部分からは探せない）
// ・下：友達の一覧（名前・ID・アイコンは相手の今のプロフィールから出す）
// ・自分は出さない
// ・使うデータ: users, users/{uid}/friends
// ======================================================================

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/data/profile_options.dart';
import 'package:study_support_app/theme/filter_button.dart';
import 'package:study_support_app/theme/app_palette.dart';

// 比較する相手
class ComparePartner {
  // Firestore の users/{uid} の uid
  final String uid;
  final String name;

  // 「@〜」のユーザーID（ないときは空）
  final String userId;

  // アイコンの画像のURL（ないときは空）
  final String icon;

  // 学習記録を公開しているか（設定の「学習記録を公開する」。決めていない人は公開）
  // 非公開の人は、比べる相手に選べない
  final bool isPublic;

  const ComparePartner({
    required this.uid,
    required this.name,
    required this.userId,
    required this.icon,
    this.isPublic = true,
  });

  factory ComparePartner.fromUserData(
    String uid,
    Map<String, dynamic>? data, {
    String fallbackName = "ユーザー",
  }) {
    return ComparePartner(
      uid: uid,
      name: (data?["name"] ?? data?["username"] ?? fallbackName).toString(),
      userId: (data?["userId"] ?? "").toString(),
      icon: (data?["icon"] ?? "").toString(),
      isPublic: data?["isPublic"] != false,
    );
  }
}

Future<ComparePartner?> showCompareUserPicker(BuildContext context) {
  return showModalBottomSheet<ComparePartner>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppPalette.of(context).card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _CompareUserPicker(),
  );
}

class _CompareUserPicker extends StatefulWidget {
  const _CompareUserPicker();

  @override
  State<_CompareUserPicker> createState() => _CompareUserPickerState();
}

class _CompareUserPickerState extends State<_CompareUserPicker> {
  final _searchController = TextEditingController();

  final String? _myUid = FirebaseAuth.instance.currentUser?.uid;

  // 探した結果（まだ探していないときは null）
  List<ComparePartner>? _results;
  bool _isSearching = false;

  // 失敗したときの、赤い文字の案内
  String? _searchError;

  // 入力が止まってから少し待って探す
  Timer? _debounce;

  // 古い検索の結果で上書きしないための番号
  int _searchNumber = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _search);
  }

  // 名前・ユーザーIDが、入れた文字で始まる人を探す
  Future<QuerySnapshot<Map<String, dynamic>>> _startsWith(
    String field,
    String text,
  ) {
    return FirebaseFirestore.instance
        .collection("users")
        .where(field, isGreaterThanOrEqualTo: text)
        .where(field, isLessThan: "$text")
        .limit(10)
        .get();
  }

  // 絞り込み（指定しないときは null）
  String? _grade;
  String? _goal;

  bool get _hasFilter => _grade != null || _goal != null;

  // 絞り込みに合う人か
  bool _matches(Map<String, dynamic> data) {
    if (_grade != null && data["grade"] != _grade) return false;
    if (_goal != null && data["goal"] != _goal) return false;
    return true;
  }

  // 文字を入れずに、絞り込みだけで探す（学年・目標が同じ人）
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _byFilter() async {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
      "users",
    );
    if (_grade != null) query = query.where("grade", isEqualTo: _grade);
    if (_goal != null) query = query.where("goal", isEqualTo: _goal);
    final snapshot = await query.limit(30).get();
    return snapshot.docs;
  }

  Future<void> _search() async {
    _debounce?.cancel();

    final text = _searchController.text.trim();
    final number = ++_searchNumber;

    if (text.isEmpty && !_hasFilter) {
      setState(() {
        _results = null;
        _isSearching = false;
        _searchError = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      // ユーザーIDは「@」つきで保存されている人と、つかずに保存されている人がいるので両方で探す
      final withoutAt = text.startsWith("@") ? text.substring(1) : text;

      // 文字があれば名前・IDで探す。なければ絞り込みだけで探す
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
      if (text.isEmpty) {
        docs = await _byFilter();
      } else {
        final snapshots = await Future.wait([
          _startsWith("name", text),
          if (withoutAt.isNotEmpty) _startsWith("userId", "@$withoutAt"),
          if (withoutAt.isNotEmpty) _startsWith("userId", withoutAt),
        ]);
        docs = [for (final s in snapshots) ...s.docs];
      }

      if (!mounted || number != _searchNumber) return;

      // 同じ人が何度も出ないようにまとめる（自分と、絞り込みに合わない人は出さない）
      final found = <String, ComparePartner>{};

      for (final doc in docs) {
        if (doc.id == _myUid) continue;
        if (!_matches(doc.data())) continue;
        found[doc.id] = ComparePartner.fromUserData(doc.id, doc.data());
      }

      setState(() {
        _isSearching = false;
        _results = found.values.toList();
      });
    } catch (e) {
      debugPrint("比較する相手の検索に失敗しました: $e");

      if (!mounted || number != _searchNumber) return;

      setState(() {
        _isSearching = false;
        _results = null;
        _searchError = "探せませんでした。時間をおいてもう一度お試しください";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Padding(
      // キーボードが出ても、入力欄が隠れないようにする
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // つまみ
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 14),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: p.muted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "比較する相手を選ぶ",
                style: TextStyle(
                  color: p.text,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ------------------------------------------------------
            // 名前かユーザーIDで探す
            // ------------------------------------------------------
            _sectionTitle("名前・ユーザーID・学年や目標で探す", p),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onChanged: _onSearchChanged,
                      onSubmitted: (_) => _search(),
                      style: TextStyle(color: p.text, fontSize: 14.5),
                      decoration: InputDecoration(
                        hintText: "名前かIDの最初の文字",
                        hintStyle: TextStyle(color: p.muted),
                        isDense: true,
                        filled: true,
                        fillColor: p.field,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      // 「探す」を押したら、キーボードを閉じてから探す
                      onPressed: _isSearching
                          ? null
                          : () {
                              FocusScope.of(context).unfocus();
                              _search();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "探す",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 絞り込み（学年・職種／学習目標）。変えたら、すぐ探しなおす
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterButton(
                    title: "学年・職種",
                    options: ProfileOptions.grades,
                    value: _grade,
                    onChanged: (v) {
                      setState(() => _grade = v);
                      _search();
                    },
                  ),
                  FilterButton(
                    title: "学習目標",
                    options: ProfileOptions.goals,
                    value: _goal,
                    onChanged: (v) {
                      setState(() => _goal = v);
                      _search();
                    },
                  ),
                ],
              ),
            ),

            if (_isSearching)
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),

            if (_searchError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 20, 0),
                child: Text(
                  _searchError!,
                  style: const TextStyle(
                    color: Color(0xFFE5534B),
                    fontSize: 12.5,
                  ),
                ),
              ),

            if (!_isSearching && _results != null && _results!.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 20, 0),
                child: Text(
                  "見つかりませんでした",
                  style: TextStyle(color: p.secondary, fontSize: 12.5),
                ),
              ),

            // 探した結果（多いときは、この中でスクロール）
            if (!_isSearching && _results != null && _results!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  // 枠線は中身の上に描く（中の行の色で、角の枠線が隠れないように）
                  foregroundDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: [
                      for (int i = 0; i < _results!.length; i++)
                        _PartnerRow(
                          partner: _results![i],
                          showDivider: i < _results!.length - 1,
                          onTap: () => Navigator.pop(context, _results![i]),
                        ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // ------------------------------------------------------
            // 友達から選ぶ
            // ------------------------------------------------------
            _sectionTitle("友達から選ぶ", p),

            Expanded(child: _buildFriendList(p)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, AppPalette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 20, 8),
      child: Text(
        text,
        style: TextStyle(
          color: p.secondary,
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFriendList(AppPalette p) {
    if (_myUid == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(_myUid)
          .collection("friends")
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _message("友達を読み込めませんでした", p);
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final friends = snapshot.data!.docs
            .where((doc) => doc.id != _myUid)
            .toList();

        if (friends.isEmpty) {
          return _message("まだ友達がいません\n上のIDで探すこともできます", p);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Container(
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(14),
              ),
              // 枠線は中身の上に描く（中の行の色で、角の枠線が隠れないように）
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (int i = 0; i < friends.length; i++)
                    _FriendPartnerRow(
                      friendId: friends[i].id,
                      savedName: (friends[i].data()["username"] ?? "ユーザー")
                          .toString(),
                      showDivider: i < friends.length - 1,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _message(String text, AppPalette p) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Align(
        alignment: Alignment.topCenter,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: p.secondary, fontSize: 13, height: 1.6),
        ),
      ),
    );
  }
}

// ======================================================
// 友達1人分の行（相手の今のプロフィールを読んでから出す）
// ======================================================

class _FriendPartnerRow extends StatelessWidget {
  final String friendId;

  // 相手のプロフィールが読めないときに出す名前
  final String savedName;

  final bool showDivider;

  const _FriendPartnerRow({
    required this.friendId,
    required this.savedName,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection("users")
          .doc(friendId)
          .get(),
      builder: (context, snapshot) {
        final partner = ComparePartner.fromUserData(
          friendId,
          snapshot.data?.data(),
          fallbackName: savedName,
        );

        return _PartnerRow(
          partner: partner,
          showDivider: showDivider,
          onTap: () => Navigator.pop(context, partner),
        );
      },
    );
  }
}

// ======================================================
// 相手1人分の行（アイコン・名前・ID・「選ぶ」）
// ======================================================

class _PartnerRow extends StatelessWidget {
  final ComparePartner partner;
  final bool showDivider;
  final VoidCallback onTap;

  const _PartnerRow({
    required this.partner,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    // 学習記録を非公開にしている人は、押せない（右に「非公開」と出す）
    final canSelect = partner.isPublic;

    return InkWell(
      onTap: canSelect ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: showDivider
            ? BoxDecoration(
                border: Border(bottom: BorderSide(color: p.divider)),
              )
            : null,
        child: Row(
          children: [
            PartnerAvatar(icon: partner.icon, radius: 20),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    partner.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: p.text,
                    ),
                  ),
                  if (partner.userId.isNotEmpty)
                    Text(
                      partner.userId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: p.secondary),
                    ),
                ],
              ),
            ),

            if (canSelect)
              const Text(
                "選ぶ",
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 14, color: p.muted),
                  const SizedBox(width: 3),
                  Text("非公開", style: TextStyle(color: p.muted, fontSize: 12)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// 相手のアイコン（画像がないときは人のマーク）
class PartnerAvatar extends StatelessWidget {
  final String icon;
  final double radius;

  // 丸の背景の色（画像がないときに見える。指定しないときはうすい青）
  final Color? backgroundColor;

  const PartnerAvatar({
    super.key,
    required this.icon,
    required this.radius,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppColors.primarySoft,
      backgroundImage: icon.isNotEmpty ? NetworkImage(icon) : null,
      child: icon.isEmpty
          ? Icon(Icons.person, color: AppColors.primary, size: radius * 1.1)
          : null,
    );
  }
}
