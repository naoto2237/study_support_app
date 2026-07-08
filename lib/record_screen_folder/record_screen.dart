import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_record_screen.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  BarChartGroupData makeBar(
      int x,
      double value,
      ){

    return BarChartGroupData(

      x:x,

      barRods:[

        BarChartRodData(

          toY:value,

          width:20,

          borderRadius:
          BorderRadius.circular(5),

        ),

      ],

    );

  }

  // 学習記録取得
  Stream<QuerySnapshot> getRecords() {
    return _firestore
        .collection("records")
        .orderBy("date", descending: true)
        .snapshots();
  }


  // 学習時間合計
  int calculateTotalHours(List<QueryDocumentSnapshot> docs) {

    int totalMinutes = 0;

    for (var doc in docs) {
      totalMinutes += doc["studyTime"] as int;
    }

    return (totalMinutes / 60).floor();
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "学習記録",
        ),
        centerTitle: true,
      ),


      body: StreamBuilder<QuerySnapshot>(

        stream: getRecords(),

        builder: (context, snapshot) {


          // 読み込み中
          if (snapshot.connectionState ==
              ConnectionState.waiting) {

            return const Center(
              child: CircularProgressIndicator(),
            );
          }


          // データなし
          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {

            return const Center(
              child: Text(
                "まだ学習記録がありません",
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            );
          }


          final records =
              snapshot.data!.docs;


          final totalHours =
          calculateTotalHours(records);



          return Column(

            children: [


              // 合計時間カード
              Padding(
                padding:
                const EdgeInsets.all(16),

                child: Card(

                  elevation: 3,

                  child: Padding(

                    padding:
                    const EdgeInsets.all(20),

                    child: Row(

                      mainAxisAlignment:
                      MainAxisAlignment.center,

                      children: [

                        const Icon(
                          Icons.timer,
                          size: 35,
                          color: Colors.blue,
                        ),


                        const SizedBox(
                          width: 15,
                        ),


                        Column(

                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [

                            const Text(
                              "累計学習時間",
                              style: TextStyle(
                                fontSize: 14,
                              ),
                            ),


                            Text(
                              "$totalHours時間",
                              style:
                              const TextStyle(
                                fontSize: 28,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),

                          ],
                        )

                      ],
                    ),
                  ),
                ),
              ),

// 学習時間グラフ
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),

                child: Card(
                  elevation: 3,

                  child: Padding(
                    padding: const EdgeInsets.all(16),

                    child: Column(

                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [

                        const Text(
                          "週間学習時間",
                          style: TextStyle(
                            fontSize:18,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),


                        const SizedBox(
                          height:20,
                        ),


                        SizedBox(

                          height:200,

                          child: BarChart(

                            BarChartData(

                              alignment:
                              BarChartAlignment.spaceAround,


                              maxY: 5,


                              barGroups: [

                                makeBar(
                                  0,
                                  2,
                                ),

                                makeBar(
                                  1,
                                  1,
                                ),

                                makeBar(
                                  2,
                                  3,
                                ),

                                makeBar(
                                  3,
                                  2,
                                ),

                                makeBar(
                                  4,
                                  1,
                                ),

                                makeBar(
                                  5,
                                  4,
                                ),

                                makeBar(
                                  6,
                                  2,
                                ),

                              ],

                              titlesData:
                              FlTitlesData(

                                bottomTitles:
                                AxisTitles(

                                  sideTitles:
                                  SideTitles(

                                    showTitles:true,

                                    getTitlesWidget:
                                        (value,title){

                                      const days=[
                                        "月",
                                        "火",
                                        "水",
                                        "木",
                                        "金",
                                        "土",
                                        "日",
                                      ];


                                      return Text(
                                        days[value.toInt()],
                                      );

                                    },

                                  ),

                                ),

                                leftTitles:
                                const AxisTitles(

                                  sideTitles:
                                  SideTitles(
                                    showTitles:true,
                                  ),

                                ),

                              ),

                            ),

                          ),

                        ),

                      ],
                    ),
                  ),
                ),
              ),

              // 記録一覧
              Expanded(

                child: ListView.builder(

                  itemCount:
                  records.length,


                  itemBuilder:
                      (context,index){


                    final data =
                    records[index].data()
                    as Map<String,dynamic>;



                    return Card(

                      margin:
                      const EdgeInsets
                          .symmetric(
                        horizontal:16,
                        vertical:6,
                      ),


                      child: ListTile(

                        leading:
                        const CircleAvatar(

                          child:
                          Icon(
                            Icons.book,
                          ),

                        ),


                        title:
                        Text(
                          data["subject"],
                        ),


                        subtitle:
                        Text(
                          data["memo"],
                        ),


                        trailing:
                        Text(
                          "${data["studyTime"]}分",
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),

                      ),
                    );

                  },
                ),
              ),
            ],
          );

        },
      ),



      floatingActionButton:
      FloatingActionButton(

        onPressed: () {

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:(context)=>
              const AddRecordScreen(),
            ),
          );
        },

        child:
        const Icon(
          Icons.add,
        ),

      ),

    );

  }
}
