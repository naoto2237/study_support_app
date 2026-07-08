import 'package:cloud_firestore/cloud_firestore.dart';


class RecordModel {


  // ドキュメントID
  final String id;


  // 科目名
  final String subject;


  // 学習時間（分）
  final int studyTime;


  // メモ
  final String memo;


  // 日付
  final DateTime date;



  RecordModel({

    required this.id,

    required this.subject,

    required this.studyTime,

    required this.memo,

    required this.date,

  });




  // Firestore → RecordModelへ変換
  factory RecordModel.fromFirestore(
      DocumentSnapshot doc
      ){


    final data =
    doc.data()
    as Map<String,dynamic>;



    return RecordModel(

      id: doc.id,


      subject:
      data["subject"] ?? "",


      studyTime:
      data["studyTime"] ?? 0,


      memo:
      data["memo"] ?? "",


      date:
      (data["date"] as Timestamp)
          .toDate(),

    );


  }





  // RecordModel → Firestoreへ変換
  Map<String,dynamic> toMap(){


    return {


      "subject":
      subject,


      "studyTime":
      studyTime,


      "memo":
      memo,


      "date":
      Timestamp.fromDate(date),


    };


  }



}