import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gourmet_app/screens/threadScreen.dart';
import 'package:image_picker/image_picker.dart';
import 'loginScreen.dart';
import 'mapScreen.dart';
import 'myPageScreen.dart';

class UploadScreen extends StatefulWidget {
  final int selected;  // final로 변경


  UploadScreen(this.selected);  // 생성자 간소화

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  late int _selectedIndex;  // null 안전성을 위해 late 사용

  int rating=0;
  int  findFood=0;//0이면 안보이게, 1이면 검색 2이면 검색결과보여주기

  TextEditingController textEditingController=new TextEditingController();
  List<String> imageUrls = [];  // 업로드된 이미지 URL 저장
  int imageCheck=0;//사진선택 0이면 선택x 1이면 업로드 대기중 2면 업로드 완료
  bool restCheck=false;//음식점선택
String reviewContent="";
  String foodName="";
 bool reviewCheck=false;

  String research="";
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selected;
    _userDataStream=_loadUserDataStream();
  }
  late Stream<DocumentSnapshot> _userDataStream;
  // 추가할 Stream 함수
  Stream<DocumentSnapshot> _loadUserDataStream() {
    String userUid = FirebaseAuth.instance.currentUser!.uid;
    print("check★★★★★★★★★★★★");
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userUid)
        .snapshots();
  }

  void _handleError(dynamic error) {
    print('Error: ${error.toString()}');
    if (error is FirebaseException) {
      print('Error Code: ${error.code}');
      print('Error Message: ${error.message}');
    } else if (error is PlatformException) {
      print('Platform Error: ${error.message}');
    } else {
      print('Unknown Error: $error');
    }
  }
  Future<void> pickAndUploadMultipleImages() async {

    try {
      print('Starting image picker...');
      final imagePicker = ImagePicker();
      final List<XFile> pickedFiles = await imagePicker.pickMultiImage(
      );

      print('Picked files count: ${pickedFiles.length}');

      if (pickedFiles.isEmpty) {
        setState(() {
          imageCheck = 0;
          imageUrls = [];
        });
        return;
      }

      List<String> uploadedUrls = [];

      for (XFile imageFile in pickedFiles) {
        try {
          // 파일 존재 확인
          final file = File(imageFile.path);
          final exists = await file.exists();
          print('File exists at ${imageFile.path}: $exists');
          print('File size: ${await file.length()} bytes');

          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${uploadedUrls.length}.jpg';
          print('Attempting to upload file: $fileName');

          // Storage 참조 생성 확인
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('user_images')
              .child(fileName);
          print('Storage reference created: ${storageRef.fullPath}');

          // 메타데이터 설정
          final metadata = SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {
                'originalPath': imageFile.path,
                'uploadTime': DateTime.now().toIso8601String(),
              }
          );

          // 업로드 시작
          print('Starting file upload...');
          final uploadTask = storageRef.putFile(file, metadata);

          // 업로드 진행상황 모니터링
          uploadTask.snapshotEvents.listen(
                (TaskSnapshot snapshot) {
              print('Upload progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes} bytes');
            },
            onError: (error) {
              print('Upload snapshot error: $error');
            },
          );

          setState(() {
            imageCheck=1;
          });
          // 업로드 완료 대기
          final snapshot = await uploadTask;
          print('Upload completed. State: ${snapshot.state}');
          if (snapshot.state == TaskState.success) {
            // URL 가져오기 시도
            try {
              final downloadUrl = await storageRef.getDownloadURL();
              print('Download URL obtained: $downloadUrl');
              uploadedUrls.add(downloadUrl);
            } catch (urlError) {
              print('Error getting download URL: $urlError');
              throw urlError;
            }
          } else {
            print('Upload finished but not successful. State: ${snapshot.state}');
          }

        } catch (singleFileError) {
          print('Error processing single file: $singleFileError');
          // 스택 트레이스 출력
          print(StackTrace.current);
        }
      }

      setState(() {
        imageUrls = uploadedUrls;
        imageCheck = 2;
        print('Final state - imageCheck: $imageCheck, URLs count: ${imageUrls.length}');
      });

    } catch (error, stackTrace) {
      print('Main error in pickAndUploadMultipleImages: $error');
      print('Stack trace: $stackTrace');
      setState(() {
        imageCheck = 0;
        imageUrls = [];
      });
    }
  }
  // DocumentSnapshot을 반환하도록 수정
  Future<DocumentSnapshot> _loadUserData() async {
    String userUid = FirebaseAuth.instance.currentUser!.uid;
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(userUid)
        .get();
  }


  Future<List<DocumentSnapshot>> searchRestaurants(String searchText) async {
    // 현재 유저 정보를 한 번만 가져옴
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    String school = (userDoc.data() as Map<String, dynamic>)["University_name"];

    // 학교에 해당하는 레스토랑 정보 가져오기
    QuerySnapshot restaurantSnapshot = await FirebaseFirestore.instance
        .collection("Restaurant")
        .where("Schools", arrayContains: school)
        .get();

    return restaurantSnapshot.docs.where((doc) {
      String name = doc['Restaurant_name'].toString().toLowerCase();
      return name.contains(searchText.toLowerCase());
    }).toList();
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
          //준비되면 yserdata를 이용할 수 있다는것이다.
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          //변화가 생기면 nickname을 수정하면된다.

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
      body:GestureDetector(
        onTap: (){
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: StreamBuilder<DocumentSnapshot>(
            stream: _userDataStream,
          builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return Center(child: Text('데이터를 찾을 수 없습니다'));
            }

            //준비되면 yserdata를 이용할 수 있다는것이다.
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            // ready 상태에 따라 다른 화면 보여주기
            return Container(
              padding: EdgeInsets.only(left: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 40,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${userData["Nickname"]}",style:
                        TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w700

                        ),),
                      SizedBox(
                        width: 110,
                      ),
                      Container(
                        margin: EdgeInsets.only(right: 15),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(15)), // 사각형 모양을 위한 설정
                              ),
                            ),
                            onPressed:  findFood==2&&imageCheck==2&&reviewCheck&&rating>0 ? ()async{
                              Map<String, dynamic> reviewData = {
                                'Bad_rate': 0,
                                'Bad_users': [],  // 리스트 변수 사용
                                'Content': reviewContent,
                                'Date': Timestamp.now(),
                                'Good_rate': 0,
                                'Good_users': [],  // 리스트 변수 사용
                                'Images': imageUrls,  // 리스트 변수 사용
                                'Nickname': userData["Nickname"],
                                'Rating': rating,
                                'Restaurant_name': foodName,
                                'UserId': FirebaseAuth.instance.currentUser!.uid
                              };
                              await FirebaseFirestore.instance
                                  .collection('Review')
                                  .add(reviewData);
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => ThreadScreen(2)),
                                    (route) => false,
                              );
                            }:null,
                            child: Text("등록하기")),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          visualDensity: VisualDensity(horizontal: -4, vertical: -4), // 버튼 간격 줄이기
                          padding: EdgeInsets.zero, // 패딩 제거
                          onPressed: (){
                            setState(() {
                              rating=1;
                            });
                          },
                          icon: rating < 1 ?Icon(Icons.star_border,color: Colors.grey[700]):Icon(Icons.star,color: Colors.grey[700])
                      ),
                      IconButton(
                          visualDensity: VisualDensity(horizontal: -4, vertical: -4), // 버튼 간격 줄이기
                          padding: EdgeInsets.zero, // 패딩 제거
                          onPressed: (){
                            setState(() {
                              rating=2;
                            });
                          },
                          icon: rating < 2 ?Icon(Icons.star_border,color: Colors.grey[700]):Icon(Icons.star,color: Colors.grey[700])
                      ),
                      IconButton(
                          visualDensity: VisualDensity(horizontal: -4, vertical: -4), // 버튼 간격 줄이기
                          padding: EdgeInsets.zero, // 패딩 제거
                          onPressed: (){
                            setState(() {
                              rating=3;
                            });
                          },
                          icon: rating < 3 ?Icon(Icons.star_border,color: Colors.grey[700]):Icon(Icons.star,color: Colors.grey[700])
                      ),
                      IconButton(
                          visualDensity: VisualDensity(horizontal: -4, vertical: -4), // 버튼 간격 줄이기
                          padding: EdgeInsets.zero, // 패딩 제거
                          onPressed: (){
                            setState(() {
                              rating=4;
                            });
                          },
                          icon: rating < 4 ?Icon(Icons.star_border,color: Colors.grey[700]):Icon(Icons.star,color: Colors.grey[700])
                      ),
                      IconButton(
                          visualDensity: VisualDensity(horizontal: -4, vertical: -4), // 버튼 간격 줄이기
                          padding: EdgeInsets.zero, // 패딩 제거
                          onPressed: (){
                            setState(() {
                              rating=5;
                            });
                          },
                          icon: rating < 5 ?Icon(Icons.star_border,color: Colors.grey[700]):Icon(Icons.star,color: Colors.grey[700])
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    height: 200,
                    width: 300,
                    constraints: BoxConstraints(
                      minHeight: 50,  // 최소 높이
                      maxHeight: 200,  // 최대 높이
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextFormField(
                      maxLines: null, // null로 설정하면 자동으로 늘어남
                      minLines: 1, // 최소 라인 수
                      keyboardType: TextInputType.multiline,
                      controller: textEditingController,
                      textInputAction: TextInputAction.done,  // 완료 버튼으로 변경
                      // 또는 TextInputAction.next, TextInputAction.send 등
                      onFieldSubmitted: (value) {
                        // 완료 버튼 눌렀을 때 실행할 동작
                        FocusScope.of(context).unfocus();  // 키보드 닫기
                        reviewCheck=true;
                      },
                      onChanged: (value){
                        setState(() {
                          if(value==""){
                            reviewCheck=false;
                            reviewContent=value;
                          }
                          else
                            {
                              reviewCheck=true;
                              reviewContent=value;
                            }

                        });
                      },
                      decoration: InputDecoration(
                        border: InputBorder.none,  // 테두리 제거
                        focusedBorder: InputBorder.none,  // 포커스 시 테두리 제거
                        enabledBorder: InputBorder.none,  // 기본 테두리 제거
                        errorBorder: InputBorder.none,  // 에러 시 테두리 제거
                        disabledBorder: InputBorder.none,  // 비활성화 시 테두리 제거
                        hintText: '여기다가 리뷰를 작성해주세요!',
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 5
                        ),
                      ),
                    ),
                  ),
                  //Icons.star_border:Icons.star,color: Colors.grey[700]

                  TextButton(
                      onPressed: ()async{
                        pickAndUploadMultipleImages();
                      },
                      child: Text("사진 추가+")
                  ),
                  if(imageCheck==1)
                    Container(
                        width: 300,
                        height: 200,
                        child: Center(child: CircularProgressIndicator()))
                  else if(imageCheck==2)
                    Container(
                      height: 200,
                      child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (contex,index){
                            return Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrls[index],
                                    width: 300,  // Container 너비에 맞춤
                                    height: 500,  // Container 높이에 맞춤
                                    fit: BoxFit.fill,
                                    placeholder: (context, url) => Center(
                                        child: CircularProgressIndicator()
                                    ),
                                    errorWidget: (context, url, error) => Icon(Icons.error),
                                  ),
                                ),
                                SizedBox(
                                  width: 10,
                                )
                              ],
                            );
                          },
                          itemCount: imageUrls.length,
                      ),
                    )
                  ,
                  TextButton(
                      onPressed: ()async{
                        setState(() {
                          research="";
                          findFood=1;
                        });
                      },
                      child: Text("음식점 추가+")
                  ),
                  if(findFood==1)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 330,
                          child: TextFormField(
                            onChanged: (value) {
                              setState(() {
                                research = value.trim(); // 앞뒤 공백 제거
                                print(research);
                              });
                            },
                            // 스타일 및 UI
                            decoration: InputDecoration(
                              hintText: '레스토랑 검색...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 14
                              ),
                            ),
                            // 입력 제어
                            textInputAction: TextInputAction.search,
                            keyboardType: TextInputType.text,
                          ),
                        ),
                        Container(
                          height: 240,
                          child: FutureBuilder(
                              future: searchRestaurants(research),
                              builder: (context,snapshot){
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                }
                                // 데이터가 없거나 리스트가 비어있을 때
                                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return Center(child: Text('검색 결과가 없습니다'));
                                }
                                final datas=snapshot.data;
                                return ListView.builder(
                                    itemBuilder: (context,index){
                                      final documentData = datas[index].data() as Map<String, dynamic>;
                                      return GestureDetector(
                                        onTap: (){
                                          setState(() {
                                            restCheck=true;//굳이안써도될듯
                                            findFood=2;
                                            foodName=documentData["Restaurant_name"];
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.only(top: 20),
                                          height: 90,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(10),
                                                    child: CachedNetworkImage(
                                                      imageUrl:  documentData["Restaurant_imgs"][0],
                                                      width: 55,  // Container 너비에 맞춤
                                                      height: 55,  // Container 높이에 맞춤
                                                      fit: BoxFit.fill,
                                                      placeholder: (context, url) => Center(
                                                          child: CircularProgressIndicator()
                                                      ),
                                                      errorWidget: (context, url, error) => Icon(Icons.error),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 10,
                                                  ),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(documentData["Restaurant_name"],style:
                                                        TextStyle(
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.w600,
                                                        ),),
                                                      Text(documentData["Category"],style:
                                                        TextStyle(
                                                          color: Colors.grey[500]
                                                        ),)
                                                    ],
                                                  )
                                                ],
                                              ),
                                              SizedBox(
                                                height: 10,
                                              ),
                                              Container(
                                                width: 340,
                                                height:2,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[300]
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                    itemCount: datas!.length,
                                );
                              }),
                        )
                      ],
                    )
                  else if(findFood==2)
                    Container(
                      padding: EdgeInsets.only(left: 12),
                        child: Text("${foodName}",
                          style: TextStyle(
                            fontSize: 15
                          ),)
                    ),
                ],
              ),
            );
          },
              ),
        ),
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
        onTap: (index)async{
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

