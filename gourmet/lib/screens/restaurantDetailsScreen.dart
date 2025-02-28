import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gourmet_app/screens/threadScreen.dart';

import 'UploadScreen.dart';
import 'loginScreen.dart';
import 'mapScreen.dart';
import 'myPageScreen.dart';

class RestaurantDetailsScreen extends StatefulWidget {
  final String name;//음식점이름
  RestaurantDetailsScreen(this.name);

  @override
  State<RestaurantDetailsScreen> createState() => _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {

  bool _isMenu=true;
  late final Stream<QuerySnapshot> restaurantStream;
  Stream<QuerySnapshot>? reviewStream;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    restaurantStream = FirebaseFirestore.instance
        .collection("Restaurant")
        .where("Restaurant_name", isEqualTo: widget.name)
        .snapshots();

    // 바로 스트림 설정
    reviewStream = FirebaseFirestore.instance
        .collection("Review")
        .where("Restaurant_name", isEqualTo: widget.name)  // 1. 먼저 필터링
        //.orderBy("Date", descending: true)  // 2. 그 다음 정렬
        .snapshots();

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
        onTap: (index)async {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MapScreen(index)),
                  (route) => false,
            );
          }else if (index == 1) {
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
        selectedItemColor: Colors.grey,
        unselectedItemColor: Colors.grey,
      ),
      body:SafeArea(
        child: StreamBuilder<QuerySnapshot>(
            stream: restaurantStream,
            builder: (context,snapshot) {
              if(snapshot.connectionState==ConnectionState.waiting){
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (snapshot.hasError) {
                return Center(child: Text("에러가 발생했습니다: ${snapshot.error}"));
              }

              // 데이터가 없을 때
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text("아직 리뷰가 없습니다."));
              }

              final data=snapshot.data!.docs;

              return StreamBuilder<QuerySnapshot>(
                  stream:  reviewStream,
                  builder: (context,snapshot){
                    if(snapshot.connectionState==ConnectionState.waiting){
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    final docs=snapshot.data!.docs;
                    docs.sort((a, b) => (b.get("Date") as Timestamp).compareTo(a.get("Date") as Timestamp) );
                    int reviewCount=docs.length;
                    print("reviewCount = ${reviewCount}");
                    double sum=0;
                    double avg=0;
                    if(reviewCount>0){
                      for(int i=0; i<reviewCount; i++){
                        if (docs[i]["Rating"] is num){
                          sum+= (docs[i]["Rating"] as num).toDouble();
                        }
                      }
                      avg=sum/reviewCount;
                    }
                    return Container(
                      child: Column(
                        children: [
                          SizedBox(
                            height: 20,
                          ),
                          Container(
                              padding: EdgeInsets.symmetric(vertical: 10,horizontal: 15),
                              height: 170,
                              width: MediaQuery.of(context).size.width-70,
                              child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: data[0]["Restaurant_imgs"].length,
                                  itemBuilder: (context, index) {
                                    return Container(  // 각 아이템을 Container로 감싸기
                                      margin: EdgeInsets.only(right: 10),  // 이미지 간 간격
                                      width: MediaQuery.of(context).size.width * 0.7,  // 이미지 너비를 화면 크기에 비례하게
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: CachedNetworkImage(
                                          imageUrl: data[0]["Restaurant_imgs"][index],
                                          width: 60,  // Container 너비에 맞춤
                                          height: 200,  // Container 높이에 맞춤
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Center(
                                              child: CircularProgressIndicator()
                                          ),
                                          errorWidget: (context, url, error) => Icon(Icons.error),
                                        ),
                                      ),
                                    );
                                  }
                              )
                          ),
                          SizedBox(
                            height: 15,
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(data[0]["Restaurant_name"],
                                style:TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),),
                              SizedBox(
                                height: 5,
                              ),
                              Container(
                                height: 40,
                                margin: EdgeInsets.symmetric(horizontal: 30),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.black,  // 테두리 색상
                                    width: 1,  // 테두리 두께
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                    ),
                                    Text("별점 ${avg}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text("리뷰 ${reviewCount}", style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),),
                                    SizedBox(
                                      width: 45,
                                    ),
                                    Text("영업시간 : ${data[0]["Runtime"]}",style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    children: [
                                      TextButton(
                                        child: Text("메뉴",style:
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
                                        child: Text("리뷰",style:
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
                              Divider(
                                color: Colors.grey[400],       // 선 색상
                                thickness: 2,             // 선 두께// 끝 지점 여백
                              ),
                            ],
                          ),
                          if(_isMenu)
                            Expanded(//여기 부부누부분!!!!!!!!!!!!
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 30),
                                child: ListView.builder(
                                  itemCount: data[0]["Menus"].length,
                                  itemBuilder: (context,index){
                                    return Container(
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            height: 10,
                                          ),
                                          Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(20),
                                                child: CachedNetworkImage(
                                                  imageUrl: data[0]["Menus"][index]["Url"],
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) => CircularProgressIndicator(),
                                                  errorWidget: (context, url, error) => Icon(Icons.error),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 10,
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text("${data[0]["Menus"][index]["Name"]}",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                  ),),
                                                  SizedBox(
                                                    height: 5,
                                                  ),
                                                  Text("${data[0]["Menus"][index]["Price"]}원",style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.red,
                                                  ),),
                                                ],
                                              ),

                                            ],
                                          ),
                                          SizedBox(
                                            height: 10,
                                          ),
                                          Container(
                                            height:1,
                                            decoration: BoxDecoration(
                                                color: Colors.grey[200]
                                            ),
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: ListView.builder(
                                  itemBuilder: (context,index){
                                    return Container(
                                      padding: EdgeInsets.all(20),
                                      height: 300,
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
                                          SizedBox(
                                            height: 20,
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
                                          ),
                                          SizedBox(
                                            height: 15,
                                          ),
                                          Container(
                                            height:1,
                                            decoration: BoxDecoration(
                                                color: Colors.grey[200]
                                            ),
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                  itemCount: docs.length,
                                ),
                              ),
                            )

                        ],
                      )
                    );
                  });
        
            },
            
        ),
      ),

    );
  }
}
