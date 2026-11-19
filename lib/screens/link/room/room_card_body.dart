// ======================================================================
// 【部品】ルームのカードの見た目（「作成」タブと「検索」タブで同じ形にする）
//
// 主なクラス: RoomCardBody
// 使う場所: create_tab/room_card.dart（自分のルーム）
//          search_tab/public_room_card.dart（公開ルーム）
// ・左：オーナーのアイコン（丸）。オーナーが分からないときは、うすい青の四角にのせたアイコン
// ・まん中：ルーム名、説明（あれば2行まで）、オーナーの名前とID、「公開・〇人」
// ・右：それぞれのカードが渡すもの（メニューや「参加」ボタン）
// ・白いカード（枠つき・角丸16）。ほかの画面のカードと同じ形
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:study_support_app/screens/record/comparison/compare_user_picker.dart'
    show PartnerAvatar;
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/theme/app_palette.dart';

class RoomCardBody extends StatefulWidget {
  final String roomId;
  final String title;
  final String description;
  final bool isPublic;
  final String ownerId;
  final Widget? trailing;
  final VoidCallback? onTap;

  const RoomCardBody({
    super.key,
    required this.roomId,
    required this.title,
    required this.description,
    required this.isPublic,
    this.ownerId = "",
    this.trailing,
    this.onTap,
  });

  @override
  State<RoomCardBody> createState() => _RoomCardBodyState();
}

class _RoomCardBodyState extends State<RoomCardBody> {
  // 参加している人数（描き直すたびに作り直さないよう、最初に1回だけ作る）
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _members =
      FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('members')
          .snapshots();

  // オーナーのプロフィール（オーナーが分からないときは null。1回だけ読む）
  late final Future<DocumentSnapshot<Map<String, dynamic>>>? _owner =
      widget.ownerId.isEmpty
      ? null
      : FirebaseFirestore.instance
            .collection('users')
            .doc(widget.ownerId)
            .get();

  // オーナーの行：名前（太字）、ID（うすい灰色）。アイコンは左に大きく出す
  Widget _buildOwner() {
    final p = context.pal;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _owner,
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final name = (data?['name'] ?? '').toString();
        final userId = (data?['userId'] ?? '').toString();

        return Row(
          children: [
            Flexible(
              child: Text(
                name.isEmpty ? "…" : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: p.text,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (userId.isNotEmpty) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  userId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.muted, fontSize: 11.5),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final description = widget.description.trim();

    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
          child: Row(
            children: [
              // ---------------- アイコン（オーナーのアイコン） ----------------
              // オーナーが分からないルームは、うすい青の四角に人々のアイコン
              if (_owner != null)
                FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: _owner,
                  builder: (context, snapshot) => PartnerAvatar(
                    icon: (snapshot.data?.data()?['icon'] ?? '').toString(),
                    radius: 24,
                  ),
                )
              else
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: p.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),

              const SizedBox(width: 12),

              // ---------------- ルームの情報 ----------------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title.isEmpty ? "名前のないルーム" : widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: p.text,
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.secondary,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],

                    // オーナー（アイコン・名前・ID）
                    if (_owner != null) ...[
                      const SizedBox(height: 7),
                      _buildOwner(),
                    ],

                    const SizedBox(height: 6),

                    // 公開・人数
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _members,
                      builder: (context, snapshot) {
                        final count = snapshot.data?.docs.length;

                        return Row(
                          children: [
                            Icon(
                              widget.isPublic
                                  ? Icons.public
                                  : Icons.lock_outline_rounded,
                              size: 14,
                              color: p.muted,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              widget.isPublic ? "公開" : "非公開",
                              style: TextStyle(color: p.muted, fontSize: 12),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.person_outline_rounded,
                              size: 15,
                              color: p.muted,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              count == null ? "-人" : "$count人",
                              style: TextStyle(color: p.muted, fontSize: 12),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              if (widget.trailing != null) ...[
                const SizedBox(width: 4),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
