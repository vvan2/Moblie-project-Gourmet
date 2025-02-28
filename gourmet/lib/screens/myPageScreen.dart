import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
class MyPageScreen extends StatefulWidget {
  final String? userName;
  const MyPageScreen({super.key,this.userName});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  bool _isMenu=true;//true면 타임라인, 아니면 프로필



  Stream<DocumentSnapshot> _loadUserDataStream() {
    String userUid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userUid)
        .snapshots();
  }



  void initState() {
    // TODO: implement initState
    super.initState();
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: StreamBuilder(
              stream: _loadUserDataStream(),
              builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot){
                if(snapshot.connectionState==ConnectionState.waiting){
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                final userData = snapshot.data!.data() as Map<String, dynamic>; //나중에 이 데이터를 통해 보여주기
                return StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection("Review")
                        .where("Nickname", isEqualTo: userData["Nickname"])
                        .snapshots(),
                    builder: (context,snapshot2){
                      if(snapshot2.connectionState==ConnectionState.waiting){
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final docs=snapshot2.data!.docs;
                      docs.sort((a, b) => (b.get("Date") as Timestamp).compareTo(a.get("Date") as Timestamp) );

                      return Container(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 20,
                            ),
                            Row(
                              children: [
                                SizedBox(
                                  width: 30,
                                ),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(userData["Nickname"],style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 25
                                      ),),
                                      IconButton(
                                          padding: EdgeInsets.only(right: 20),
                                          onPressed: (){
                                            Navigator.pop(context);
                                          },
                                          icon: Icon(Icons.arrow_back_ios_sharp)
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  children: [
                                    TextButton(
                                      child: Text("타임라인",style:
                                      TextStyle(
                                        color: _isMenu?Colors.black : Colors.grey[500],
                                        fontWeight: _isMenu? FontWeight.w700 :FontWeight.w400,
                                        fontSize: 15,
                                      ),
                                      ),
                                      onPressed: (){
                                        setState(() {
                                          _isMenu=true;
                                        });
                                      },
                                    ),
                                    if(_isMenu)
                                      Container(
                                        width: 40,
                                        height: 2,
                                        decoration:BoxDecoration(
                                            color: Colors.grey[700]
                                        ),
                                      )
                                  ],
                                ),
                                Column(
                                  children: [
                                    TextButton(
                                      child: Text("프로필",style:
                                      TextStyle(
                                        color: _isMenu?Colors.grey[500] : Colors.black,
                                        fontWeight: _isMenu? FontWeight.w400 :FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                      ),
                                      onPressed: (){
                                        setState(() {
                                          _isMenu=false;
                                        });
                                      },
                                    ),
                                    if(!_isMenu)
                                      Container(
                                        width: 40,
                                        height: 2,
                                        decoration:BoxDecoration(
                                            color: Colors.grey[700]
                                        ),
                                      )
                                  ],
                                ),
                              ],
                            ),
                            Expanded(
                                child: Container(
                                   decoration: BoxDecoration(

                                   ),
                                   child: _isMenu? Expanded(
                                     child: Container(
                                       child: ListView.builder(
                                         itemCount: docs.length,
                                         itemBuilder: (context, index) {
                                           return Container(
                                             margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                             decoration: BoxDecoration(
                                               color: Colors.white,
                                               borderRadius: BorderRadius.circular(15),
                                               boxShadow: [
                                                 BoxShadow(
                                                   color: Colors.grey.withOpacity(0.3),
                                                   spreadRadius: 2,
                                                   blurRadius: 5,
                                                 ),
                                               ],
                                             ),
                                             child: Column(
                                               crossAxisAlignment: CrossAxisAlignment.start,
                                               children: [
                                                 // 날짜 표시
                                                 Padding(
                                                   padding: EdgeInsets.all(10),
                                                   child: Row(
                                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                     children: [
                                                       Text(
                                                         (docs[index]["Date"] as Timestamp).toDate().toString().split(' ')[0],
                                                         style: TextStyle(
                                                           color: Colors.grey[600],
                                                           fontWeight: FontWeight.w500,
                                                         ),
                                                       ),
                                                       IconButton(
                                                         icon: Icon(Icons.delete),
                                                         onPressed: () {
                                                           showDialog(
                                                             context: context,
                                                             builder: (BuildContext context) {
                                                               return AlertDialog(
                                                                 title: Text('게시물 삭제'),
                                                                 content: Text('정말로 이 게시물을 삭제하시겠습니까?'),
                                                                 actions: [
                                                                   TextButton(
                                                                     child: Text('아니오'),
                                                                     onPressed: () {
                                                                       Navigator.of(context).pop(); // 다이얼로그 닫기
                                                                     },
                                                                   ),
                                                                   TextButton(
                                                                     child: Text('예'),
                                                                     onPressed: () async {
                                                                       try {
                                                                         // 게시물 삭제
                                                                         await FirebaseFirestore.instance
                                                                             .collection("Review")
                                                                             .doc(docs[index].id)
                                                                             .delete();

                                                                         Navigator.of(context).pop(); // 다이얼로그 닫기

                                                                         // 삭제 성공 메시지 표시
                                                                         ScaffoldMessenger.of(context).showSnackBar(
                                                                           SnackBar(
                                                                             content: Text('게시물이 삭제되었습니다.'),
                                                                             duration: Duration(seconds: 2),
                                                                           ),
                                                                         );
                                                                       } catch (e) {
                                                                         // 에러 처리
                                                                         Navigator.of(context).pop(); // 다이얼로그 닫기
                                                                         ScaffoldMessenger.of(context).showSnackBar(
                                                                           SnackBar(
                                                                             content: Text('게시물 삭제 중 오류가 발생했습니다.'),
                                                                             duration: Duration(seconds: 2),
                                                                           ),
                                                                         );
                                                                       }
                                                                     },
                                                                   ),
                                                                 ],
                                                               );
                                                             },
                                                           );
                                                         },
                                                       )
                                                     ],
                                                   ),
                                                 ),
                                                 // 이미지 리스트뷰
                                                 Container(
                                                   height: 200,
                                                   child: ListView.builder(
                                                     scrollDirection: Axis.horizontal,
                                                     itemCount: docs[index]["Images"].length,
                                                     itemBuilder: (context, imgIndex) {
                                                       return Padding(
                                                         padding: EdgeInsets.only(right: 10),
                                                         child: ClipRRect(
                                                           borderRadius: BorderRadius.circular(10),
                                                           child: CachedNetworkImage(
                                                             imageUrl: docs[index]["Images"][imgIndex],
                                                             width: 200,
                                                             height: 200,
                                                             fit: BoxFit.cover,
                                                             placeholder: (context, url) => Center(
                                                               child: CircularProgressIndicator(),
                                                             ),
                                                           ),
                                                         ),
                                                       );
                                                     },
                                                   ),
                                                 ),
                                                 // 음식점 이름과 리뷰 내용
                                                 Padding(
                                                   padding: EdgeInsets.all(10),
                                                   child: Column(
                                                     crossAxisAlignment: CrossAxisAlignment.start,
                                                     children: [
                                                       Text(
                                                         docs[index]["Restaurant_name"],
                                                         style: TextStyle(
                                                           fontWeight: FontWeight.bold,
                                                           fontSize: 16,
                                                         ),
                                                       ),
                                                       SizedBox(height: 5),
                                                       Text(
                                                         docs[index]["Content"],
                                                         maxLines: 2,
                                                         overflow: TextOverflow.ellipsis,
                                                         style: TextStyle(
                                                           color: Colors.grey[800],
                                                           fontSize: 14,
                                                         ),
                                                       ),
                                                     ],
                                                   ),
                                                 ),
                                               ],
                                             ),
                                           );
                                         },
                                       ),
                                     ),
                                   ) : SingleChildScrollView(
                                     child: Container(
                                       padding: EdgeInsets.symmetric(horizontal: 30),
                                       child: Column(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                           SizedBox(height: 90),
                                           InfoRow(
                                               label: "이메일",
                                               value: userData["Email"] ?? "",
                                               isEditable: false
                                           ),
                                           SizedBox(height: 40),
                                           InfoRow(
                                               label: "이름",
                                               value: userData["User_name"] ?? "",
                                               isEditable: false
                                           ),
                                           SizedBox(height: 40),
                                           InfoRow(
                                               label: "소속",
                                               value: userData["Is_student"] ?
                                               userData["University_name"] : "일반회원",
                                               isEditable: false
                                           ),
                                           SizedBox(height: 40),
                                           EditableNicknameRow(
                                               initialValue: userData["Nickname"] ?? "",
                                               onSaved: (newValue) async {
                                                 await FirebaseFirestore.instance
                                                     .collection("users")
                                                     .doc(FirebaseAuth.instance.currentUser!.uid)
                                                     .update({"Nickname": newValue});

                                                 QuerySnapshot reviewDocs = await FirebaseFirestore.instance
                                                     .collection("Review")
                                                     .where("Nickname", isEqualTo: userData["Nickname"])
                                                     .get();

                                                 WriteBatch batch = FirebaseFirestore.instance.batch();
                                                 for (var doc in reviewDocs.docs) {
                                                   batch.update(doc.reference, {"Nickname": newValue});
                                                 }
                                                 await batch.commit();
                                               }
                                           ),
                                         ],
                                       ),
                                     ),
                                   ),
                                ))
                          ],
                        ),
                      );

                    }
                    );

              }
          )
      ),
    );
  }
}


// Add these widget classes:
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isEditable;

  const InfoRow({
    required this.label,
    required this.value,
    this.isEditable = false
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 60,
          child: Text(label,
            style: TextStyle(
                color: Colors.grey[400],
                fontSize: 15
            ),
          ),
        ),
        SizedBox(width: 15),
        Expanded(
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(15),
              ),
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            )
        )
      ],
    );
  }
}

class EditableNicknameRow extends StatefulWidget {
  final String initialValue;
  final Function(String) onSaved;

  EditableNicknameRow({
    required this.initialValue,
    required this.onSaved
  });

  @override
  State<EditableNicknameRow> createState() => _EditableNicknameRowState();
}

class _EditableNicknameRowState extends State<EditableNicknameRow> {
  late TextEditingController _controller;
  bool _isEditing = false;
  late String oldNickname; // 이전 닉네임 저장용

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    oldNickname = widget.initialValue; // 초기값 저장
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 60,
          child: Text("닉네임",
            style: TextStyle(
                color: Colors.grey[400],
                fontSize: 15
            ),
          ),
        ),
        SizedBox(width: 15),
        Expanded(
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: _isEditing ? Colors.white : Colors.grey[400],
                border: _isEditing ? Border.all(color: Colors.grey) : null,
                borderRadius: BorderRadius.circular(15),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: _isEditing ?
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  border: InputBorder.none,
                ),
              ) :
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _controller.text,
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.black
                  ),
                ),
              ),
            )
        ),
        if(_isEditing)
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              widget.onSaved(_controller.text);
              setState(() => _isEditing = false);
            },
          )
        else
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => setState(() => _isEditing = true),
          )
      ],
    );
  }
}
