// ======================================================================
// 【しくみ】Firestore のデータをまとめて消す
//
// 主な関数: deleteCollection / deleteRoomCompletely
// 使う場所: room_card.dart（ルームの削除）／account_deleter.dart（アカウントの削除）
// ・Firestore では、ドキュメントを消しても、その下のコレクションは残る。
//   そのため、下のコレクションを先に1件ずつ消す
// ======================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

// コレクションの中のドキュメントを、すべて消す
// （一度にまとめて消せるのは500件までなので、200件ずつ消す）
Future<void> deleteCollection(
  CollectionReference<Map<String, dynamic>> collection,
) async {
  while (true) {
    final snapshot = await collection.limit(200).get();

    if (snapshot.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}

// ルームを、中のデータ（チャット・共有ノート・メンバー）ごと消す
// メンバーと本体は最後に消す（途中で失敗しても、ルームが一覧に残り、やり直せる）
Future<void> deleteRoomCompletely(
  DocumentReference<Map<String, dynamic>> roomRef,
) async {
  for (final name in const ["messages", "notes", "members"]) {
    await deleteCollection(roomRef.collection(name));
  }

  await roomRef.delete();
}
