// ======================================================================
// 【しくみ】この人にメッセージを送れるか
//
// 主なクラス: CanMessageBuilder
// 使う画面: 相手のマイページの「メッセージ」、1対1のチャット（chat_room_screen.dart）
// ・送れるのは、次のどれかのとき
//     友達になっている（users/{自分}/friends/{相手} がある）
//     相手が設定で「友達以外からのメッセージ」をオンにしている
//       （users/{相手} の allowNonFriendMessages が true。設定画面で切りかえる）
//     相手から、もうメッセージが届いている（返事はできるようにする）
//       （users/{自分}/chats/{相手} の otherSent が true。chat_room_screen.dart で書く）
// ・どれかが変わると、すぐに表示も変わる
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CanMessageBuilder extends StatefulWidget {
  final String userId;

  // canMessage: 送れるか / loading: まだ調べている途中か
  final Widget Function(BuildContext context, bool canMessage, bool loading)
  builder;

  const CanMessageBuilder({
    super.key,
    required this.userId,
    required this.builder,
  });

  @override
  State<CanMessageBuilder> createState() => _CanMessageBuilderState();
}

class _CanMessageBuilderState extends State<CanMessageBuilder> {
  // Stream は1回だけ作る（親が作りなおされても、読みなおさない）
  late final Stream<bool> _isFriend;
  late final Stream<bool> _theyAllow;
  late final Stream<bool> _theySent;

  @override
  void initState() {
    super.initState();

    final me = FirebaseAuth.instance.currentUser?.uid;
    final users = FirebaseFirestore.instance.collection('users');

    _isFriend = me == null
        ? Stream.value(false)
        : users
              .doc(me)
              .collection('friends')
              .doc(widget.userId)
              .snapshots()
              .map((snap) => snap.exists)
              .handleError((_) {});

    _theySent = me == null
        ? Stream.value(false)
        : users
              .doc(me)
              .collection('chats')
              .doc(widget.userId)
              .snapshots()
              .map((snap) => snap.data()?['otherSent'] == true)
              .handleError((_) {});

    _theyAllow = users
        .doc(widget.userId)
        .snapshots()
        .map((snap) => snap.data()?['allowNonFriendMessages'] == true)
        .handleError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _isFriend,
      builder: (context, friendSnap) {
        return StreamBuilder<bool>(
          stream: _theyAllow,
          builder: (context, allowSnap) {
            return StreamBuilder<bool>(
              stream: _theySent,
              builder: (context, sentSnap) {
                final canMessage =
                    (friendSnap.data ?? false) ||
                    (allowSnap.data ?? false) ||
                    (sentSnap.data ?? false);
                // まだ全部わかっていないうちは「送れない」と決めない
                final loading =
                    !canMessage &&
                    (!friendSnap.hasData ||
                        !allowSnap.hasData ||
                        !sentSnap.hasData);

                return widget.builder(context, canMessage, loading);
              },
            );
          },
        );
      },
    );
  }
}
