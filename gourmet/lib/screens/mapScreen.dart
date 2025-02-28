import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gourmet_app/screens/loginScreen.dart';
import 'package:gourmet_app/screens/restaurantDetailsScreen.dart';
import 'package:gourmet_app/screens/threadScreen.dart';
import '../components/restourantInfo.dart';
import 'UploadScreen.dart';
import 'myPageScreen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';


class MapScreen extends StatefulWidget {
  final int selected;  // final로 변경

  MapScreen(this.selected);  // 생성자 간소화

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  List<LatLng> locations=[LatLng(37.582848,127.01058),LatLng(37.588227,126.9936),LatLng(37.5893,127.032)];//한성대 성균관대 고려대 순서
  Map<int,String> _currentStatusMap={0:"한성대학교",1:"성균관대학교",2:"고려대학교"};
  late int _selectedIndex;  // null 안전성을 위해 late 사용


  //초기 카메라 위치는 한성대학교로 설청할것임.

  // 현재위치
  LatLng? currentLocation;

  final LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100,
  );

  Stream<DocumentSnapshot> _loadUserDataStream() {
    String userUid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userUid)
        .snapshots();
  }

  Future<void> getLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    Position position = await Geolocator.getCurrentPosition(locationSettings: locationSettings);
    currentLocation = LatLng(
      position.latitude,   // Position의 위도
      position.longitude,  // Position의 경도
    );
  }


  int _currentStatus=0;//0은 한성대 1은 성균관대 2는 고려대


  // 마커 저장할 Set
  //쉽게쉽게 가기 위해서, init 시에, 모든 마커 / 한성대마커/ 성균관대 마커/ 고려대 마커를 초기화할 것이다.
  Set<Marker> _allMarkers = {};
  Set<Marker> _hansungMarkers = {};
  Set<Marker> _koreaMarkers = {};
  Set<Marker> _sungkyunMarkers = {};
  //또한 원도 초기화할것이다.
  Set<Circle> _hansungCircles = {};
  Set<Circle> _koreacircles = {};
  Set<Circle> _sungkyuncircles = {};

  Future<void>? initFuture;



  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selected;
    initFuture=initData();

  }

  Future<DocumentSnapshot> _loadUserData() async {
    String userUid = FirebaseAuth.instance.currentUser!.uid;
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(userUid)
        .get();
  }

  Future<void> initData() async {
    try {
      // 1. 현재 위치 가져오기
      await getLocation();

      // 2. 현재 위치 마커 (빨간색)
      Marker currentLocationMarker = Marker(
        markerId: MarkerId("currentLocation"),
        position: currentLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: "현재 위치"),
      );

      // 3. 대학교 마커 생성
      Marker hansung = Marker(
        markerId: MarkerId("한성대학교 위치"),
        position: locations[0],
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow: InfoWindow(title: "한성대학교"),
      );

      Marker sungkyun = Marker(
        markerId: MarkerId("성균관대학교 위치"),
        position: locations[1],
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow: InfoWindow(title: "성균관대학교"),
      );

      Marker korea = Marker(
        markerId: MarkerId("고려대학교 위치"),
        position: locations[2],
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow: InfoWindow(title: "고려대학교"),
      );

      // 4. 마커 추가
      _allMarkers.add(currentLocationMarker);
      _allMarkers.add(hansung);
      _allMarkers.add(sungkyun);
      _allMarkers.add(korea);

      _hansungMarkers.add(currentLocationMarker);
      _hansungMarkers.add(hansung);

      _koreaMarkers.add(currentLocationMarker);
      _koreaMarkers.add(korea);

      _sungkyunMarkers.add(currentLocationMarker);
      _sungkyunMarkers.add(sungkyun);

      // 5. 원형 초기화 (for 루프 밖으로 이동)
      _hansungCircles.add(
        Circle(
          circleId: CircleId('hansung_circle'),
          center: locations[0],
          radius: 3000,
          fillColor: Colors.blue.withOpacity(0.2),
          strokeColor: Colors.blue,
          strokeWidth: 2,
        ),
      );

      _sungkyuncircles.add(
        Circle(
          circleId: CircleId('sungkyun_circle'),
          center: locations[1],
          radius: 3000,
          fillColor: Colors.blue.withOpacity(0.2),
          strokeColor: Colors.blue,
          strokeWidth: 2,
        ),
      );

      _koreacircles.add(
        Circle(
          circleId: CircleId('korea_circle'),
          center: locations[2],
          radius: 3000,
          fillColor: Colors.blue.withOpacity(0.2),
          strokeColor: Colors.blue,
          strokeWidth: 2,
        ),
      );

      // 6. Firestore에서 음식점 데이터 가져오기
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("Restaurant")
          .get();

      // 7. 각 음식점 데이터 처리
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        print("${data['Restaurant_name']} ${data['Latitude']} ${data['Longitude']} ");
        LatLng position = LatLng(
          (data['Latitude'] is int)
              ? (data['Latitude'] as int).toDouble()
              : data['Latitude'],
          (data['Longitude'] is int)
              ? (data['Longitude'] as int).toDouble()
              : data['Longitude'],
        );
        Marker marker = Marker(
          markerId: MarkerId(data['Restaurant_name']),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: data['Restaurant_name']),
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => RestourantInfo(name: data['Restaurant_name']),
              isScrollControlled: true,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.25,
              ),
            );
          },
        );

        _allMarkers.add(marker);

        List<dynamic> schools = data['Schools'];
        if (schools.contains("한성대학교")) {
          _hansungMarkers.add(marker);
        }
        if (schools.contains("고려대학교")) {
          _koreaMarkers.add(marker);
        }
        if (schools.contains("성균관대학교")) {
          _sungkyunMarkers.add(marker);
        }
      }

    } catch (e) {
      print('Error initializing data: $e');
    }
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
      body: Stack(
        children:[ FutureBuilder(
            future: initFuture,
            builder: (context,snapshot){
              if(snapshot.connectionState==ConnectionState.waiting)
                {
                  return Center(child: CircularProgressIndicator());
                }

              return GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: locations[_currentStatus],
                  zoom: 14.0,
                ),
                markers: _currentStatus==0? _hansungMarkers : _currentStatus==1? _sungkyunMarkers : _koreaMarkers ,
                circles: _currentStatus==0? _hansungCircles : _currentStatus==1? _sungkyuncircles : _koreacircles,
              );
            }),
            Positioned(
              top: 20,
              left: 15,
              child: Container(
                width: MediaQuery.of(context).size.width-30,
                decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 5,
                  )
                ]
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(

                       style: ElevatedButton.styleFrom(
                         foregroundColor: _currentStatus==0? Colors.white : Colors.grey[500],  // 텍스트 색상
                         backgroundColor: _currentStatus==0? Colors.lightBlueAccent : Colors.grey[200] ,   // 버튼 배경색
                         padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                         shape: _currentStatus==0? RoundedRectangleBorder(              // 테두리 모양
                           borderRadius: BorderRadius.circular(10),   // 모서리 둥글기
                           side: BorderSide(                         // 테두리 스타일
                             color: Colors.blue,                     // 테두리 색상
                             width: 2,                               // 테두리 두께
                           ),
                         ) : RoundedRectangleBorder(              // 테두리 모양
                           borderRadius: BorderRadius.circular(10),   // 모서리 둥글기
                         ),
                         // 버튼 패딩
                       ),

                        onPressed: (){
                          setState(() {
                            _currentStatus=0;
                          });
                        },
                        child: Text("한성대학교",
                          style:TextStyle(
                            fontWeight: _currentStatus==0? FontWeight.w900 : FontWeight.w400
                          ) ,)
                    ),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: _currentStatus==1? Colors.white : Colors.grey[500],  // 텍스트 색상
                          backgroundColor: _currentStatus==1? Colors.lightBlueAccent : Colors.grey[200] ,   // 버튼 배경색
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: _currentStatus==1? RoundedRectangleBorder(              // 테두리 모양
                            borderRadius: BorderRadius.circular(10),   // 모서리 둥글기
                            side: BorderSide(                         // 테두리 스타일
                              color: Colors.blue,                     // 테두리 색상
                              width: 2,                               // 테두리 두께
                            ),
                          ) : RoundedRectangleBorder(              // 테두리 모양
                            borderRadius: BorderRadius.circular(10),   // 모서리 둥글기
                          ),
                          // 버튼 패딩
                        ),
                        onPressed: (){
                          setState(() {
                            _currentStatus=1;
                          });
                        },
                        child: Text("성균관대학교",style:TextStyle(
                            fontWeight: _currentStatus==1? FontWeight.w900 : FontWeight.w400
                        ))),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: _currentStatus==2? Colors.white : Colors.grey[500],  // 텍스트 색상
                          backgroundColor: _currentStatus==2? Colors.lightBlueAccent : Colors.grey[200] ,   // 버튼 배경색
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: _currentStatus==2? RoundedRectangleBorder(              // 테두리 모양
                            borderRadius: BorderRadius.circular(10),   // 모서리 둥글기
                            side: BorderSide(                         // 테두리 스타일
                              color: Colors.blue,                     // 테두리 색상
                              width: 2,                               // 테두리 두께
                            ),
                          ) : RoundedRectangleBorder(              // 테두리 모양
                            borderRadius: BorderRadius.circular(10),   // 모서리 둥글기
                          ),
                          // 버튼 패딩
                        ),

                        onPressed: (){
                          setState(() {
                            _currentStatus=2;
                          });
                        },
                        child: Text("고려대학교",style:TextStyle(
                            fontWeight: _currentStatus==2? FontWeight.w900 : FontWeight.w400
                        )))
                  ],
                ),
              ),
            ),
          DraggableScrollableSheet(
            initialChildSize: 0.15,
            minChildSize: 0.15,
            maxChildSize: 0.9,
            snapSizes: [0.2, 0.4, 0.7],
            snap: true,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30)
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection("Restaurant")
                        .where("Schools",arrayContains: _currentStatusMap[_currentStatus])
                        .snapshots(),
                    builder: (context, snapshot) {
                      if(snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return Center(child: Text("레스토랑 정보가 없습니다"));
                      }
                      return Column(
                        children: [
                          Container(
                            height: 55,
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 25,
                                ),
                                Container(
                                  decoration:BoxDecoration(
                                    color: Colors.grey[350],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  width: 150,
                                  height: 12,
                                ),
                              ],
                            )
                          ),
                          Expanded(
                            child: ListView.separated(
                                controller: scrollController,
                                itemCount: docs.length,
                                separatorBuilder: (context, index) => Divider(
                                  height: 1,
                                  color: Colors.grey[200],
                                ),
                                itemBuilder: (context, index) {
                                  return StreamBuilder(
                                    stream: FirebaseFirestore.instance
                                        .collection("Review")
                                        .where("Restaurant_name", isEqualTo: docs[index]["Restaurant_name"])
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if(snapshot.connectionState == ConnectionState.waiting) {
                                        return Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                            
                                      String url = docs[index]["Restaurant_imgs"][0];
                                      String restaurant_name = docs[index]["Restaurant_name"];
                                      String category = docs[index]["Category"];
                                      String runtime = docs[index]["Runtime"];
                            
                                      final reviewdocs = snapshot.data!.docs;
                                      int reviewCount = reviewdocs.length;
                                      double sum = 0;
                                      double avg = 0;
                                      if(reviewCount > 0) {
                                        for(int i = 0; i < reviewCount; i++) {
                                          if (reviewdocs[i]["Rating"] is num) {
                                            sum += (reviewdocs[i]["Rating"] as num).toDouble();
                                          }
                                        }
                                        avg = sum/reviewCount;
                                      }
                            
                                      return GestureDetector(
                                        onTap: (){
                                          Navigator.push(context,
                                              MaterialPageRoute(builder: (context){
                                                return RestaurantDetailsScreen(restaurant_name);
                                              }));
                                        },
                                        child: Container(
                                          color: Colors.white,
                                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.only(left: 20),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(15),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black.withOpacity(0.2),
                                                          spreadRadius: 1,
                                                          blurRadius: 3,
                                                          offset: Offset(0, 2),
                                                        ),
                                                      ],
                                                      border: Border.all(
                                                        color: Colors.white,
                                                        width: 3,
                                                      ),
                                                    ),
                                                    child: CachedNetworkImage(
                                                      imageUrl: url,
                                                      width: 100,
                                                      height: 100,
                                                      fit: BoxFit.cover,
                                                      placeholder: (context, url) => CircularProgressIndicator(),
                                                      errorWidget: (context, url, error) => Icon(Icons.error),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 15),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    SizedBox(height: 3),
                                                    Text(
                                                      restaurant_name,
                                                      style: TextStyle(
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 15
                                                      ),
                                                    ),
                                                    Text(
                                                      category,
                                                      style: TextStyle(
                                                          fontWeight: FontWeight.w400,
                                                          fontSize: 12
                                                      ),
                                                    ),
                                                    SizedBox(height: 10),
                                                    Text("영업시간: $runtime"),
                                                    SizedBox(height: 9),
                                                    Row(
                                                      children: [
                                                        Text("평점: ${avg.toStringAsFixed(1)}  "),
                                                        Text("리뷰: $reviewCount개"),
                                                      ],
                                                    )
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }
                            ),
                          ),
                        ],
                      );
                    }
                ),
              );
            },
          ),
             ]
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


          }  else if (index == 2) {
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