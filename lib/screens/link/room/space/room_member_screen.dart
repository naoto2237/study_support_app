// ======================================================================
// 【部品】ルームの中の「メンバー」一覧
//
// 主なクラス: RoomMemberScreen / MemberTile（メンバー1人分）
// ・オーナーを先頭に、参加した順に並べる
// ・1人分：アイコン、名前（自分は「あなた」の札）、ユーザーID、オーナーの札、
//          今日の学習時間、勉強中かどうか
// ・今日の学習時間：保存ずみの記録（users/{uid}/studyRecords/{今日}）に、
//   勉強中ならタイマーを始めてからの分を足す。自分はタイマーの今の値（todayStudySeconds）
//   学習記録を非公開にしている人は「非公開」と出す
// ・勉強中：users/{uid}.studyingSince（services/study_timer_remote.dart が保存する）
// ======================================================================

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_support_app/main.dart' show todayStudySeconds;
import 'package:study_support_app/screens/record/comparison/compare_user_picker.dart'
    show PartnerAvatar;
import 'package:study_support_app/services/study_timer_remote.dart';
import 'package:study_support_app/theme/app_colors.dart';
import 'package:study_support_app/theme/app_palette.dart';
import 'package:study_support_app/theme/empty_message.dart';

class RoomMemberScreen extends StatefulWidget {
  final String roomId;

  const RoomMemberScreen({super.key, required this.roomId});

  @override
  State<RoomMemberScreen> createState() => _RoomMemberScreenState();
}

class _RoomMemberScreenState extends State<RoomMemberScreen> {
  // 描き直すたびに作り直さないよう、最初に1回だけ作る
  late final DocumentReference<Map<String, dynamic>> _roomRef =
      FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _room = _roomRef
      .snapshots();

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _members = _roomRef
      .collection('members')
      .orderBy('joinedAt')
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _room,
      builder: (context, roomSnapshot) {
        final ownerId = (roomSnapshot.data?.data()?['ownerId'] ?? '')
            .toString();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _members,
          builder: (context, memberSnapshot) {
            if (memberSnapshot.hasError) {
              return const EmptyMessage(
                icon: Icons.cloud_off_rounded,
                text: 'メンバーを読み込めませんでした',
              );
            }

            if (memberSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final memberDocs = memberSnapshot.data?.docs ?? [];

            if (memberDocs.isEmpty) {
              return const EmptyMessage(
                icon: Icons.groups_outlined,
                text: '参加しているメンバーはいません',
              );
            }

            // オーナーを先頭にする（ほかは参加した順のまま）
            final sorted = [...memberDocs]
              ..sort((a, b) {
                if (a.id == ownerId) return -1;
                if (b.id == ownerId) return 1;
                return 0;
              });

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(17, 14, 17, 24),
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final uid = sorted[index].id;

                return MemberTile(
                  key: ValueKey(uid),
                  uid: uid,
                  isOwner: uid == ownerId,
                );
              },
            );
          },
        );
      },
    );
  }
}

// =========================================================
// メンバー1人分
// =========================================================

class MemberTile extends StatefulWidget {
  final String uid;
  final bool isOwner;

  const MemberTile({super.key, required this.uid, this.isOwner = false});

  @override
  State<MemberTile> createState() => _MemberTileState();
}

class _MemberTileState extends State<MemberTile> {
  late final bool _isMe = widget.uid == FirebaseAuth.instance.currentUser?.uid;

  late final DocumentReference<Map<String, dynamic>> _userRef =
      FirebaseFirestore.instance.collection('users').doc(widget.uid);

  // プロフィール（名前・アイコン・公開設定・勉強中）。変わったらすぐ出し直す
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _user = _userRef
      .snapshots();

  // 今日の保存ずみの学習時間
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _todayRecord =
      _userRef.collection('studyRecords').doc(_todayId()).snapshots();

  // 勉強中のとき、時間を1秒ずつ進めて見せるための描き直し
  // （勉強中でない人は時間が変わらないので、描き直さない）
  Timer? _ticker;
  bool _isStudying = false;

  static String _todayId() {
    final now = DateTime.now();
    return "${now.year.toString().padLeft(4, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isStudying) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // 「2時間15分」「45分10秒」「20秒」のような書き方（1時間未満だけ秒まで出す）
  String _durationLabel(int seconds) {
    final h = seconds ~/ 3600;
    final m = seconds ~/ 60 % 60;
    final s = seconds % 60;

    if (h > 0) return m == 0 ? "$h時間" : "$h時間$m分";
    if (m > 0) return "$m分$s秒";
    return "$s秒";
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _user,
      builder: (context, userSnapshot) {
        final data = userSnapshot.data?.data();
        final name = (data?['name'] ?? '').toString();
        final userId = (data?['userId'] ?? '').toString();
        final icon = (data?['icon'] ?? '').toString();

        // 学習記録を見せてよいか（自分はいつも見られる）
        final isPublic = _isMe || data?['isPublic'] != false;

        // 勉強中なら、始めた時刻（自分はタイマーの今の状態を使う）
        final studyingSince = _isMe
            ? null
            : StudyTimerRemote.studyingSinceOf(data);

        // 勉強中の人だけ、1秒ごとに時間を進める
        _isStudying = studyingSince != null;

        return Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border),
          ),
          child: Row(
            children: [
              PartnerAvatar(icon: icon, radius: 23),

              const SizedBox(width: 12),

              // ---------------- 名前・ID・今日の学習時間 ----------------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name.isEmpty ? "…" : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: p.text,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (widget.isOwner) ...[
                          const SizedBox(width: 6),
                          _badge("オーナー"),
                        ],
                        if (_isMe) ...[const SizedBox(width: 6), _badge("あなた")],
                      ],
                    ),

                    if (userId.isNotEmpty)
                      Text(
                        userId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: p.muted, fontSize: 11.5),
                      ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: p.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "今日 ",
                          style: TextStyle(color: p.secondary, fontSize: 12.5),
                        ),
                        if (!isPublic)
                          Text(
                            "非公開",
                            style: TextStyle(color: p.muted, fontSize: 12.5),
                          )
                        else if (_isMe)
                          ValueListenableBuilder<int>(
                            valueListenable: todayStudySeconds,
                            builder: (context, seconds, _) =>
                                _timeText(seconds),
                          )
                        else
                          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: _todayRecord,
                            builder: (context, recordSnapshot) {
                              final saved =
                                  (recordSnapshot.data?.data()?['studyTime']
                                          as num?)
                                      ?.toInt() ??
                                  0;

                              // 勉強中なら、始めてからの分（今日の0時より後だけ）を足す
                              var running = 0;
                              if (studyingSince != null) {
                                final now = DateTime.now();
                                final midnight = DateTime(
                                  now.year,
                                  now.month,
                                  now.day,
                                );
                                final from = studyingSince.isBefore(midnight)
                                    ? midnight
                                    : studyingSince;
                                running = now.difference(from).inSeconds;
                                if (running < 0) running = 0;
                              }

                              return _timeText(saved + running);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ---------------- 勉強中 ----------------
              if (_isMe)
                ValueListenableBuilder<bool>(
                  valueListenable: StudyTimerRemote.isRunning,
                  builder: (context, running, _) =>
                      running ? _studyingLabel() : const SizedBox.shrink(),
                )
              else if (studyingSince != null)
                _studyingLabel(),
            ],
          ),
        );
      },
    );
  }

  Widget _timeText(int seconds) {
    return Text(
      _durationLabel(seconds),
      style: TextStyle(
        color: context.pal.text,
        fontSize: 12.5,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // 「オーナー」「あなた」の札（うすい青の面に青い文字）
  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: context.pal.primarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 「● 勉強中」（緑の点と文字）
  Widget _studyingLabel() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 8, color: AppColors.green),
        SizedBox(width: 4),
        Text(
          "勉強中",
          style: TextStyle(
            color: AppColors.green,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
