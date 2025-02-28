import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';


import '../screens/restaurantDetailsScreen.dart';
class RestourantInfo extends StatefulWidget {
  final name;
  const RestourantInfo({super.key,required this.name});
  
  @override
  State<RestourantInfo> createState() => _RestourantInfoState();
}

class _RestourantInfoState extends State<RestourantInfo> {

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("Restaurant")
            .where("Restaurant_name", isEqualTo: widget.name)
            .snapshots(),
        builder: (context,snapshot){
          if(snapshot.connectionState==ConnectionState.waiting){
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          final docs=snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Text("레스토랑 정보가 없습니다"));
          }
          return StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection("Review")
                .where("Restaurant_name", isEqualTo: widget.name)
                .snapshots(),
            builder: (context,snapshot){
              if(snapshot.connectionState==ConnectionState.waiting){
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              //정리
              String url=docs[0]["Restaurant_imgs"][0];//docs[0]으로 접근하는 이유는 하나의 문서밖에 안나올것이다. 식당은 중복x
              String restaurant_name=docs[0]["Restaurant_name"];
              String category=docs[0]["Category"];
              String runtime=docs[0]["Runtime"];

              //별점과 리뷰를 계산하기위해 Review테이블에 접근한 것이다.
              final reviewdocs=snapshot.data!.docs;
              int reviewCount=reviewdocs.length;
              double sum=0;
              double avg=0;
              if(reviewCount>0){
                for(int i=0; i<reviewCount; i++){
                  if (reviewdocs[i]["Rating"] is num){
                   sum+= (reviewdocs[i]["Rating"] as num).toDouble();
                  }
                }
                avg=sum/reviewCount;
              }

                return GestureDetector(
                  onTap: (){
                    Navigator.push(context,
                    MaterialPageRoute(builder: (context){
                      return RestaurantDetailsScreen(widget.name);
                    }));
                  },
                  child: Container(
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
                        SizedBox(
                          width: 15,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 45,
                            ),
                            Text("${restaurant_name}",style:
                              TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15
                              ),),
                            Text("${category}",style:
                            TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 12
                            ),),
                            SizedBox(
                              height: 10,
                            ),
                            Text("영업시간:${runtime}"),
                            SizedBox(
                              height: 9,
                            ),
                            Row(

                              children: [
                                Text("벌점:${avg}  "),
                                Text("리뷰:${reviewCount}개"),
                              ],
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                );
            },
          );


        }
    );
  }
}
