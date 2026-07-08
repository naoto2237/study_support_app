import 'package:cloud_firestore/cloud_firestore.dart';


class RecordService {


  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;



  // 学習記録を追加
  Future<void> addRecord({

    required String subject,

    required int studyTime,

    required String memo,

  }) async {


    await _firestore
        .collection("records")
        .add({

      "subject": subject,

      "studyTime": studyTime,

      "memo": memo,

      "date": Timestamp.now(),

    });


  }





  // 学習記録を取得
  Stream<QuerySnapshot> getRecords(){


    return _firestore

        .collection("records")

        .orderBy(
      "date",
      descending:true,
    )

        .snapshots();


  }





  // 学習記録を削除
  Future<void> deleteRecord(
      String id
      ) async {


    await _firestore

        .collection("records")

        .doc(id)

        .delete();


  }





  // 学習時間の合計
  Future<int> getTotalStudyTime()
  async {


    final snapshot =
    await _firestore

        .collection("records")

        .get();



    int total = 0;



    for(var doc in snapshot.docs){


      total +=
      doc["studyTime"] as int;


    }



    return total;


  }





  // 指定した期間の学習記録取得
  Future<List<QueryDocumentSnapshot>>
  getRecordsByDate(
      DateTime start,
      DateTime end,
      ) async {



    final snapshot =
    await _firestore

        .collection("records")

        .where(
      "date",
      isGreaterThanOrEqualTo:
      Timestamp.fromDate(start),
    )

        .where(
      "date",
      isLessThanOrEqualTo:
      Timestamp.fromDate(end),
    )

        .get();



    return snapshot.docs;


  }


}