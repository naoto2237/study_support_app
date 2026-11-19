// ======================================================================
// 【しくみ】アカウントを消す
//
// 主な関数: AccountDeleter.deleteMyAccount
// 使う画面: settings_screen.dart（設定 → アカウントを削除）
//
// 消すもの:
// ・自分のデータ users/{自分} と、その下（学習記録・AIの履歴・友達・友達申請・
//   チャット・通知・見た人・応援）
// ・友達の一覧から、自分を消す（users/{友達}/friends/{自分}）
// ・自分が送った友達申請（users/{相手}/friend_requests/{自分}）
// ・自分が作ったルーム（中のデータごと）と、参加しているルームのメンバー
// ・自分が書いた Q&A の質問
// ・最後に、ログインのアカウント（Firebase Authentication）
//   （本人の確認は、Firebase に言われたときだけ。ふつうは画面を出さずに消す）
//
// 残るもの（相手のデータなので消さない）:
// ・相手のチャット画面にある、やりとりの記録
// ・ほかの人の質問に書いた回答
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_support_app/services/firestore_cleanup.dart';
import 'package:study_support_app/services/google_account.dart';

class AccountDeleter {
  AccountDeleter._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 終わったら true（データを消して、ログアウトまでした）
  static Future<bool> deleteMyAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final uid = user.uid;
    final me = _db.collection('users').doc(uid);

    // ------------------------------------------------------
    // ① 友達の一覧から、自分を消す
    // ------------------------------------------------------
    final friends = await me.collection('friends').get();
    for (final friend in friends.docs) {
      await _db
          .collection('users')
          .doc(friend.id)
          .collection('friends')
          .doc(uid)
          .delete();
    }

    // ------------------------------------------------------
    // ①' 自分が送った友達申請（相手の users/{相手}/friend_requests/{自分}）を消す
    //     送った相手は、どこにも記録していないので、ぜんぶの人の友達申請から
    //     「送った人が自分」のものを探す（Firestore のルールで、自分の分だけ読める）
    // ------------------------------------------------------
    final sentRequests = await _db
        .collectionGroup('friend_requests')
        .where('senderId', isEqualTo: uid)
        .get();
    for (final request in sentRequests.docs) {
      await request.reference.delete();
    }

    // ------------------------------------------------------
    // ② ルーム
    //    自分が作ったルームは中身ごと消す。
    //    ほかのルームからは、メンバーとしての自分を消す
    //    （いないルームの分は、消しても何も起きない）
    // ------------------------------------------------------
    final rooms = await _db.collection('rooms').get();
    WriteBatch batch = _db.batch();
    int count = 0;

    for (final room in rooms.docs) {
      if (room.data()['ownerId'] == uid) {
        await deleteRoomCompletely(room.reference);
        continue;
      }

      batch.delete(room.reference.collection('members').doc(uid));
      count++;

      if (count == 400) {
        await batch.commit();
        batch = _db.batch();
        count = 0;
      }
    }
    if (count > 0) await batch.commit();

    // ------------------------------------------------------
    // ③ 自分が書いた Q&A の質問
    // ------------------------------------------------------
    final questions = await _db
        .collection('questions')
        .where('userId', isEqualTo: uid)
        .get();
    for (final question in questions.docs) {
      await question.reference.delete();
    }

    // ------------------------------------------------------
    // ④ 自分のデータ（下のコレクションを先に消してから、本体を消す）
    // ------------------------------------------------------

    // AIの履歴とチャットは、その下にさらにメッセージがある
    for (final name in const ['ai_history', 'chats']) {
      final docs = await me.collection(name).get();
      for (final doc in docs.docs) {
        await deleteCollection(doc.reference.collection('messages'));
      }
    }

    for (final name in const [
      'studyRecords',
      'ai_history',
      'friends',
      'friend_requests',
      'chats',
      'notifications',
      'profileViews',
      'cheers',
    ]) {
      await deleteCollection(me.collection(name));
    }

    await me.delete();

    // ------------------------------------------------------
    // ⑤ ログインのアカウントを消す
    //    ふつうは、そのまま消せる。
    //    Firebase が「ログインしてから時間がたっている」と言ったときだけ、
    //    Google で本人かを確かめてから消す（このときだけ、Google の画面が出ることがある）
    // ------------------------------------------------------
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') rethrow;

      if (await GoogleAccount.reauthenticate()) {
        await user.delete();
      }
      // 確かめずに閉じたときも、データはもう消えているので、ログアウトだけして終える
      // （次に同じ Google でログインすると、はじめの登録からやりなおしになる）
    }

    // 次の人が、Google のアカウントをえらびなおせるようにする
    await GoogleAccount.signOut();

    return true;
  }
}
