import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AddRecordScreen extends StatefulWidget {

  const AddRecordScreen({
    super.key,
  });


  @override
  State<AddRecordScreen> createState() =>
      _AddRecordScreenState();

}



class _AddRecordScreenState
    extends State<AddRecordScreen> {


  final _formKey =
  GlobalKey<FormState>();


  final TextEditingController subjectController =
  TextEditingController();


  final TextEditingController timeController =
  TextEditingController();


  final TextEditingController memoController =
  TextEditingController();



  bool isLoading = false;



  // Firestore保存
  Future<void> saveRecord() async {


    if (!_formKey.currentState!.validate()) {
      return;
    }


    setState(() {
      isLoading = true;
    });



    try {


      await FirebaseFirestore.instance
          .collection("records")
          .add({

        "subject":
        subjectController.text,


        "studyTime":
        int.parse(
          timeController.text,
        ),


        "memo":
        memoController.text,


        "date":
        Timestamp.now(),


      });



      if (!mounted) return;



      Navigator.pop(context);



    } catch(e) {


      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content:
          Text(
            "保存に失敗しました $e",
          ),
        ),

      );


    }



    setState(() {

      isLoading = false;

    });


  }





  @override
  void dispose() {

    subjectController.dispose();

    timeController.dispose();

    memoController.dispose();

    super.dispose();

  }







  @override
  Widget build(BuildContext context) {


    return Scaffold(


      appBar: AppBar(

        title:
        const Text(
          "学習記録を追加",
        ),

        centerTitle:true,

      ),




      body:

      Padding(

        padding:
        const EdgeInsets.all(20),


        child:

        Form(

          key:_formKey,


          child:

          Column(


            children:[




              TextFormField(

                controller:
                subjectController,


                decoration:
                const InputDecoration(

                  labelText:
                  "科目",

                  hintText:
                  "例：Java、Flutter",

                  border:
                  OutlineInputBorder(),

                ),



                validator:(value){


                  if(value==null ||
                      value.isEmpty){

                    return
                      "科目を入力してください";

                  }


                  return null;

                },

              ),





              const SizedBox(
                height:20,
              ),





              TextFormField(


                controller:
                timeController,


                keyboardType:
                TextInputType.number,


                decoration:
                const InputDecoration(


                  labelText:
                  "学習時間（分）",


                  hintText:
                  "例：60",


                  border:
                  OutlineInputBorder(),

                ),




                validator:(value){


                  if(value==null ||
                      value.isEmpty){

                    return
                      "時間を入力してください";

                  }


                  if(int.tryParse(value)
                      ==null){

                    return
                      "数字で入力してください";

                  }


                  return null;

                },


              ),





              const SizedBox(
                height:20,
              ),





              TextFormField(


                controller:
                memoController,


                maxLines:4,


                decoration:
                const InputDecoration(

                  labelText:
                  "メモ",

                  hintText:
                  "学習内容を入力",

                  border:
                  OutlineInputBorder(),

                ),

              ),





              const SizedBox(
                height:30,
              ),






              SizedBox(

                width:
                double.infinity,


                height:
                50,


                child:

                ElevatedButton(


                  onPressed:
                  isLoading
                      ? null
                      : saveRecord,



                  child:

                  isLoading

                      ? const SizedBox(

                    height:25,

                    width:25,

                    child:
                    CircularProgressIndicator(),

                  )


                      :

                  const Text(

                    "保存する",

                    style:
                    TextStyle(

                      fontSize:16,

                    ),

                  ),



                ),

              )



            ],

          ),

        ),

      ),

    );

  }

}