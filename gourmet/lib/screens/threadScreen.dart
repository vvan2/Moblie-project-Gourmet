import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'UploadScreen.dart';
import 'loginScreen.dart';
import 'mapScreen.dart';
import 'myPageScreen.dart';

class ThreadScreen extends StatefulWidget {
  final int selected;  // final로 변경
  ThreadScreen(this.selected);  // 생성자 간소화

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  late int _selectedIndex;  // null 안전성을 위해 late 사용


  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selected;

  }
  Stream<DocumentSnapshot> _loadUserDataStream() {
    String userUid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userUid)
        .snapshots();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Gourmet",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          IconButton(

              onPressed: ()async{
                await FirebaseAuth.instance.signOut();

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route)=>false,
                );
              },
              icon: Icon(Icons.logout))

        ],
      ),
      drawer: StreamBuilder<DocumentSnapshot>(
        stream: _loadUserDataStream(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Drawer(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Drawer(
              child: Center(child: Text('오류가 발생했습니다: ${snapshot.error}')),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Drawer(
              child: Center(child: Text('데이터를 찾을 수 없습니다')),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;

          return Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(userData["Nickname"] ?? "사용자"),
                  accountEmail: Text(userData["Email"] ?? "이메일 없음"),
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40.0),
                      bottomRight: Radius.circular(40.0),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text("마이페이지"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyPageScreen(userName: userData["Nickname"])),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      body: StreamBuilder(
          stream: FirebaseFirestore.instance.collection("Review").orderBy("Date",descending:true).snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
            if(snapshot.connectionState==ConnectionState.waiting){
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            else if(snapshot.hasData==null){
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            final docs=snapshot.data!.docs;
            // List<bool> likes=List.generate(docs.length, (index){return false;});
            // List<bool> dislikes=List.generate(docs.length, (index){return false;});
            return RefreshIndicator(
              onRefresh: ()async{
                await Future.delayed(Duration(seconds: 1));
                return Future.value();
              },
              child: ListView.builder(
                  itemBuilder: (context,index){

                  return Container(
                    padding: EdgeInsets.all(20),
                    height: 450,
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(docs[index]["Nickname"],
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15
                            ),),
                            SizedBox(
                              width: 10,
                            ),
                            Icon(
                                docs[index]["Rating"]<1?Icons.star_border:Icons.star,color: Colors.grey[700]
                            ),
                            Icon(
                                docs[index]["Rating"]<2?Icons.star_border:Icons.star,color: Colors.grey[700]
                            ),
                            Icon(
                                docs[index]["Rating"]<3?Icons.star_border:Icons.star,color: Colors.grey[700]
                            ),
                            Icon(
                                docs[index]["Rating"]<4?Icons.star_border:Icons.star,color: Colors.grey[700]
                            ),
                            Icon(
                                docs[index]["Rating"]<5?Icons.star_border:Icons.star,color: Colors.grey[700]
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          docs[index]["Content"],
                          style: TextStyle(fontSize: 12),
                          overflow: TextOverflow.visible,  // 또는 TextOverflow.clip
                          softWrap: true,  // 자동 줄바꿈 활성화
                          maxLines: null,  // 여러 줄 허용
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text("#${docs[index]["Restaurant_name"]}",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600
                                  ),),
                            ),
                            likeDislikeContainer(docs[index].id,docs[index]["UserId"]),
                          ],
                        ),
                        Expanded(
                          child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: docs[index]["Images"].length,
                              itemBuilder: (context,index2){
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(5),  // 더 작은 radius 값
                                  ),
                                  child:  Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: CachedNetworkImage(
                                          imageUrl: docs[index]["Images"][index2],
                                          width: 200,
                                          height: 200,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => CircularProgressIndicator(),
                                          errorWidget: (context, url, error) => Icon(Icons.error),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 30,
                                      )
                                    ],
                                  ),
                                );
                              }
                          ),
                        )
                      ],
                    ),
                  );

                  },
                  itemCount: docs.length,
              ),
            );

          },

      ),



      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: '지도',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: '추가',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            label: '그리드',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) async{
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MapScreen(index)),
                  (route) => false,
            );
          } else if (index == 1) {
            final userDoc = await FirebaseFirestore.instance
                .collection("users")
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .get();

            final isStudent = (userDoc.data() as Map<String, dynamic>)["Is_student"];
            if(isStudent){
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => UploadScreen(index)),
                    (route) => false,
              );
            }else
            {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('알림'),
                    content: Row(
                      children: [
                        Text("일반유저",style:
                        TextStyle(
                            fontSize: 15,
                            color: Colors.red
                        ),),
                        Text('이므로 작성할 수 없습니다.',style:
                        TextStyle(
                            fontSize: 15
                        ),),
                      ],
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text('확인'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  );
                },
              );
            }
          } else if (index == 2) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => ThreadScreen(index)),
                  (route) => false,
            );
          }
        },
        showSelectedLabels: false,  // 선택된 아이템의 라벨 숨기기
        showUnselectedLabels: false,  // 선택되지 않은 아이템의 라벨 숨기기
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}


class likeDislikeContainer extends StatefulWidget {
  final String documentId;
  final String userId;
  const likeDislikeContainer(this.documentId,this.userId);

  @override
  State<likeDislikeContainer> createState() => _likeDislikeContainerState();
}

class _likeDislikeContainerState extends State<likeDislikeContainer> {
  bool isliked=false;
  bool isdisliked=false;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseFirestore.instance.collection("Review").doc(widget.documentId).snapshots(),
        builder: (context,snapshot){

          final doc=snapshot.data!.data();
          isliked=doc!["Good_users"].contains(FirebaseAuth.instance.currentUser!.uid);
          isdisliked=doc!["Bad_users"].contains(FirebaseAuth.instance.currentUser!.uid);
          return Container(
            child: Row(
              children: [
                Row(
                  children: [
                    IconButton(
                        onPressed: ()async{
                          isliked=!isliked;
                            await FirebaseFirestore.instance
                                .collection("Review")
                                .doc(widget.documentId)
                                .update({
                              "Good_rate": FieldValue.increment(isliked ? 1 : -1),
                              "Good_users": isliked?  FieldValue.arrayUnion([FirebaseAuth.instance.currentUser!.uid]) : FieldValue.arrayRemove([FirebaseAuth.instance.currentUser!.uid])
                            });
                        },
                      icon: Icon(
                        isliked ? Icons.thumb_up : Icons.thumb_up_outlined,  // 좋아요 상태면 채워진 아이콘
                        size: 20,
                        color: isliked ? Colors.blue : Colors.grey,  // 좋아요 상태면 파란색
                      ),
                    ),
                    Text("${doc!["Good_rate"]}")
                  ],
                )
                ,
                Row(
                  children: [

                    IconButton(
                      onPressed: ()async{
                        isdisliked=!isdisliked;
                        await FirebaseFirestore.instance
                            .collection("Review")
                            .doc(widget.documentId)
                            .update({
                          "Bad_rate": FieldValue.increment(isdisliked ? 1 : -1),
                          "Bad_users": isdisliked?  FieldValue.arrayUnion([FirebaseAuth.instance.currentUser!.uid]) : FieldValue.arrayRemove([FirebaseAuth.instance.currentUser!.uid])
                        });

                      },
                      icon: Icon(
                        isdisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                        size: 20,
                        color: isdisliked ? Colors.red : Colors.grey,
                      ),
                    ),
                    Text("${doc!["Bad_rate"]}"),
                  ],
                )


              ],
            ),
          );

        });
  }
}
