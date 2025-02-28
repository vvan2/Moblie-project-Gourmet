import 'dart:async';
import 'dart:ffi';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import "package:cloud_firestore/cloud_firestore.dart";

import 'mapScreen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _State();
}

class _State extends State<SignupScreen> {
  bool _isStudent=true;//대학생인지 일반인인지
  int _currentProcess=1;//현재 회원과입 과정 페이지

  TextEditingController _studentController=new TextEditingController();
  TextEditingController _normalUserController=new TextEditingController();

  String _verifyMsg="인 증";

  bool timeChecking=true;

  String _alertMessage="";
  String _timeMessage="";
  Map<String, String> _schoolEmails = {
    "@hansung.ac.kr": "한성대학교",
    "@skku.edu": "성균관대학교",
    "@korea.ac.kr": "고려대학교",
  };
  String? _email;
  String _school="";
  String? _pwd;
  String? _name;
  String? _nickName;

  bool verification=false;//인증상태
  Timer? timer;
  int attempts = 60;

  final _formKey=GlobalKey<FormState>();
  final _jobKey=GlobalKey<FormState>();
  final _normalFormKey=GlobalKey<FormState>();

  Future<void> checkEmailVerified(User user) async{

    await user.reload();//user가 속해있는 FirebaseAuth 인스턴스 업데이트!!!
    //업데이트를 했으면 다시 최신 user로 가져와야한다.
    final updatedUser = FirebaseAuth.instance.currentUser;
    setState(() {
      verification = updatedUser!.emailVerified;
    });

  }

  Future<void> signup(GlobalKey<FormState> formKey) async{
    final check=formKey.currentState!.validate();//모두 null을 리턴하면 true 리턴
    if(check)
    {
      formKey.currentState!.save();
      try{
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email!, password: _pwd!);
        await FirebaseFirestore.instance.collection("users").doc(userCredential.user!.uid)
            .set({
          "Password" : _pwd,
          "Is_student" : _isStudent,
          "Nickname":_nickName,
          "User_name":_name,
          "University_name":_school,//비회원이면 빈칸으로 들어갈것
          "Email":_email
        });

        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context){
              return MapScreen(0);
            }),
                (route)=>false
        );
      }catch (e) {
        String message = '로그인에 실패했습니다.';

        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'user-not-found':
              message = '등록된 사용자를 찾을 수 없습니다. 이메일을 다시 확인해주세요.';
              break;
            case 'wrong-password':
              message = '비밀번호가 올바르지 않습니다. 다시 입력해 주세요.';
              break;
            case 'invalid-email':
              message = '유효하지 않은 이메일 형식입니다. 다시 입력해주세요.';
              break;
            case 'email-already-in-use':
              message = '이미 사용 중인 이메일입니다. 다른 이메일을 입력해주세요.';
              break;
            case 'weak-password':
              message = '비밀번호가 너무 약합니다. 더 강력한 비밀번호를 사용해주세요.';
              break;
            case 'operation-not-allowed':
              message = '이메일 로그인 기능이 비활성화되었습니다.';
              break;
            default:
              message = '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
              break;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: (){
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height,
            child: SafeArea(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 50),
                child: Column(
                  children: [
                    SizedBox(
                      height: 40,
                    ),
                    Container(
                      margin: EdgeInsets.only(right: 250),
                      padding:EdgeInsets.only(right: 10),
                      child: IconButton(
                          visualDensity: VisualDensity(horizontal: -4, vertical: -4), // 버튼 간격 줄이기
                          padding: EdgeInsets.zero, // 패딩 제거
                          onPressed: (){
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.arrow_back_ios_sharp)
                      ),
                    ),
                    SizedBox(
                      height: 50,
                    ),
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _currentProcess==1? Colors.black : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              "1",
                              style: TextStyle(
                                color: _currentProcess==1? Colors.white : Colors.grey[500],
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 13,
                        ),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _currentProcess==2? Colors.black : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              "2",
                              style: TextStyle(
                                color: _currentProcess==2? Colors.white : Colors.grey[500],
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 13,
                        ),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _currentProcess==3? Colors.black : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              "3",
                              style: TextStyle(
                                color: _currentProcess==3? Colors.white : Colors.grey[500],
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    if(_currentProcess==1)//첫번째 페이지(대학생/일반인 체크)
                    Expanded(
                      child: Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("현재 당신은 대학생이신가요?",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(
                              height: 120,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: 110,
                                  height: 110,
                                  child: ElevatedButton(

                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.black,
                                        backgroundColor: Colors.grey[350],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(Radius.circular(15)), // 사각형 모양을 위한 설정
                                        ),
                                      ),
                                      onPressed: (){
                                       setState(() {
                                         _currentProcess=2;
                                         _isStudent=true;
                                       });
                                      },
                                      child: Text("대학생",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 20
                                        ),)
                                  ),
                                ),
                                SizedBox(
                                  width: 110,
                                  height: 110,
                                  child: ElevatedButton(

                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.grey[700],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(Radius.circular(15)), // 사각형 모양을 위한 설정
                                        ),
                                      ),
                                      onPressed: (){
                                        setState(() {
                                          _currentProcess=2;
                                          _isStudent=false;
                                        });
                                      },
                                      child: Text("일반인",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 20
                                        ),)
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      ),
                    )
                    else if(_currentProcess==2 && _isStudent==true)//대학생 두번째 페이지
                      Expanded(
                        child: Container(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("이메일로 대학생임을 인증해주세요.",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(
                                  height: 120,
                                ),
                                Text("대학교 이메일",
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500
                                  ),),
                                SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _studentController,
                                        key: ValueKey(1),
                                        keyboardType: TextInputType.emailAddress,
                                        decoration: InputDecoration(
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.grey,
                                            ),
                                            borderRadius: BorderRadius.all(Radius.circular(10)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.grey,
                                            ),
                                            borderRadius: BorderRadius.all(Radius.circular(10)),
                                          ),
                                          hintText: "university email",
                                          hintStyle: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 8,
                                    ),
                                    SizedBox(
                                      width: 70,
                                      height: 40,
                                      child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(Radius.circular(10)), // 사각형 모양을 위한 설정
                                            ),
                                          ),
                                          onPressed: timeChecking?()async{
                                            setState(() {
                                              timeChecking=false;
                                            });
                                            String inputEmail=_studentController.text!.trim();
                                            bool schoolEmailCheck=false;
                                            //학교이메일을 입력했는지 확인해야한다.
                                            _schoolEmails.forEach((domain, name) {
                                              if (inputEmail.endsWith(domain)) {
                                                schoolEmailCheck=true;
                                                _school = name; // 도메인과 일치할 경우 학교 이름 저장
                                              }
                                            });

                                            if(schoolEmailCheck==false)
                                              {
                                                  setState(() {
                                                    _alertMessage="대학교 이메일이 아닙니다.";
                                                    timeChecking=true;
                                                  });
                                              }
                                            else if(schoolEmailCheck==true)
                                              {
                                                //우선 이메일을 보낼 수 있도록 새로운 유저를 만든다.
                                                final UserCredential verifyUser=await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                                    email: inputEmail,
                                                    password: "12345678"
                                                );
                                                if(verifyUser.user!=null)
                                                  {
                                                    await verifyUser.user!.sendEmailVerification();//해당하는 이메일 전송
                                                    setState(() {
                                                      _alertMessage="인증 이메일이 전송되었습니다. 이메일을 확인해주세요.";
                                                    });
                                                  }

                                                timer = Timer.periodic(
                                                    Duration(seconds: 1), (_) async {
                                                      attempts--;//60->59->58
                                                      setState(() {
                                                        if(attempts<10)
                                                          {
                                                            _timeMessage="00:0${attempts}";
                                                          }
                                                        else
                                                          {
                                                            _timeMessage="00:${attempts}";
                                                          }

                                                      });
                                                      await checkEmailVerified(verifyUser.user!);
                                                      if (verification) {
                                                      timer!.cancel(); //타이머종료
                                                      setState(() {
                                                        _alertMessage="인증 완료되었습니다.";
                                                        _timeMessage="";
                                                        //그래도 유저를 삭제한다. 왜냐하면 현재는 그냥 이메일을 인증하기 위해 만들었기 때문이다.
                                                        verifyUser.user!.delete();
                                                        _email=inputEmail;
                                                      });
                                                      }
                                                      if(attempts==0)
                                                      {
                                                        timer!.cancel();
                                                        verifyUser.user!.delete();
                                                        attempts=60;

                                                        setState(() {
                                                          _alertMessage="인증 시간이 지났습니다. 다시 인증하세요.";
                                                          _verifyMsg="재인증";
                                                          _timeMessage="";
                                                          timeChecking=true;
                                                        });
                                                      }
                                                 }
                                                );
                                              }
                                          } : null,
                                          child: Text("${_verifyMsg}",
                                            style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: _verifyMsg=="인 증"? 10:8,
                                            ),)
                                      ),
                                    ),
                                  ],
                                ),
                                Text("${_alertMessage}",
                                style: TextStyle(
                                  color: verification?Colors.blue : Colors.red,
                                  fontSize: 10,
                                ),),
                                Text("${_timeMessage}",
                                  style: TextStyle(
                                    color: Colors.black,
                                  ),),
                                SizedBox(
                                  height: 250,
                                ),
                                SizedBox(
                                  width: 400,
                                  child: ElevatedButton(

                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(Radius.circular(15)), // 사각형 모양을 위한 설정
                                        ),
                                      ),
                                      onPressed: verification?(){
                                        setState(() {
                                          _currentProcess=3;
                                        });
                                      }:null,
                                      child: Text("다음",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w800
                                        ),)
                                  ),
                                ),
                              ]
                            )
                        ),
                      )
                    else if(_currentProcess==3 && _isStudent==true)//대학생 세번째 페이지
                      Expanded(
                          child: Container(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              Text("당신의 개인정보를 입력해주세요.",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(
                              height: 70,
                            ),
                                Container(
                                  height: 350,
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              child: Text("대학교",
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 15
                                              ),),
                                            ),
                                            SizedBox(
                                              width: 15,
                                            ),
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
                                                    "${_school}",
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                )
                                            )
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              child: Text("이메일",
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 15
                                                ),),
                                            ),
                                            SizedBox(
                                              width: 15,
                                            ),
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
                                                    "${_email}",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                )
                                            )
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              child: Text("비밀번호",
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 11
                                                ),),
                                            ),
                                            SizedBox(
                                              width: 15,
                                            ),
                                            Expanded(
                                              child: TextFormField(
                                                key: ValueKey(2),
                                                validator: (value){
                                                  if(value!.isEmpty||value.length<6)
                                                    {
                                                      return "비밀번호는 6글자 이상이어야 합니다.";
                                                    }
                                                  return null;
                                                },
                                                onSaved: (value){
                                                    _pwd=value;
                                                },
                                                keyboardType: TextInputType.emailAddress,
                                                decoration: InputDecoration(
                                                  contentPadding: EdgeInsets.symmetric(vertical: 8,horizontal: 12),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Colors.grey,
                                                    ),
                                                    borderRadius: BorderRadius.all(Radius.circular(15)),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Colors.grey,
                                                    ),
                                                    borderRadius: BorderRadius.all(Radius.circular(15)),
                                                  ),
                                                  hintText: "password",
                                                  hintStyle: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[300]!,
                                                  ),
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              child: Text("이름",
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 15
                                                ),),
                                            ),
                                            SizedBox(
                                              width: 15,
                                            ),
                                            Expanded(
                                              child: TextFormField(
                                                key: ValueKey(3),
                                                validator: (value){
                                                  if(value!.isEmpty)
                                                    {
                                                      return "이름을 작성해주세요.";
                                                    }
                                                  return null;
                                                },
                                                onSaved: (value){
                                                    _name=value;
                                                },
                                                keyboardType: TextInputType.emailAddress,
                                                decoration: InputDecoration(
                                                  contentPadding: EdgeInsets.symmetric(vertical: 8,horizontal: 12),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Colors.grey,
                                                    ),
                                                    borderRadius: BorderRadius.all(Radius.circular(15)),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Colors.grey,
                                                    ),
                                                    borderRadius: BorderRadius.all(Radius.circular(15)),
                                                  ),
                                                  hintText: "name",
                                                  hintStyle: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[300]!,
                                                  ),
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              child: Text("닉네임",
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 15
                                                ),),
                                            ),
                                            SizedBox(
                                              width: 15,
                                            ),
                                            Expanded(
                                              child: TextFormField(
                                                key: ValueKey(4),
                                                validator: (value){
                                                  if(value!.isEmpty)
                                                    {
                                                      return "닉네임을 작성해주세요.";
                                                    }
                                                  return null;
                                                },
                                                onSaved: (value){
                                                _nickName=value;
                                                },
                                                keyboardType: TextInputType.emailAddress,
                                                decoration: InputDecoration(
                                                  contentPadding: EdgeInsets.symmetric(vertical: 8,horizontal: 12),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Colors.grey,
                                                    ),
                                                    borderRadius: BorderRadius.all(Radius.circular(15)),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Colors.grey,
                                                    ),
                                                    borderRadius: BorderRadius.all(Radius.circular(15)),
                                                  ),
                                                  hintText: "nickname",
                                                  hintStyle: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[300]!,
                                                  ),
                                                ),
                                              ),
                                            )
                                          ],
                                        ),

                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 60,
                                ),
                                SizedBox(
                                  width: 400,
                                  child: ElevatedButton(

                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(Radius.circular(15)), // 사각형 모양을 위한 설정
                                        ),
                                      ),
                                      onPressed: ()async{
                                        await signup(_formKey);
                                      },
                                      child: Text("회원가입",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w800
                                        ),)
                                  ),
                                ),
                              ],
                            ),

                          ))
                      else if(_currentProcess==2 && _isStudent==false)//대학생 세번째 페이지
                        Expanded(
                            child: Container(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("당신의 직업을 알려주세요.",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 70,
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        child: Text("직업",
                                          style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 15
                                          ),),
                                      ),
                                      SizedBox(
                                        width: 15,
                                      ),
                                      Expanded(
                                        child: Form(
                                          key: _jobKey,
                                          child: TextFormField(
                                            key: ValueKey(5),
                                            validator: (value){
                                              if(value!.isEmpty)
                                              {
                                                return "직업을 작성해주세요.";
                                              }
                                              return null;
                                            },
                                            keyboardType: TextInputType.emailAddress,
                                            decoration: InputDecoration(
                                              contentPadding: EdgeInsets.symmetric(vertical: 8,horizontal: 12),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Colors.grey,
                                                ),
                                                borderRadius: BorderRadius.all(Radius.circular(15)),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Colors.grey,
                                                ),
                                                borderRadius: BorderRadius.all(Radius.circular(15)),
                                              ),
                                              hintText: "job",
                                              hintStyle: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[300]!,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  SizedBox(
                                    height: 350,
                                  ),
                                  SizedBox(
                                    width: 400,
                                    child: ElevatedButton(

                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(15)), // 사각형 모양을 위한 설정
                                          ),
                                        ),
                                        onPressed: ()async{
                                          setState(() {
                                            if(_jobKey.currentState!.validate()==true)
                                              {
                                                _currentProcess=3;
                                              }
                                          });
                                        },
                                        child: Text("다음",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w800
                                          ),)
                                    ),
                                  ),
                                ],
                              ),
                            ))
                      else if(_currentProcess==3 && _isStudent==false)
                            Expanded(
                              child: Container(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "당신의 개인정보를 입력해주세요.",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 70,
                                    ),
                                    Container(
                                      height: 350,
                                      child: Form(
                                        key: _normalFormKey,
                                        child: Container(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text("이메일",
                                                    style: TextStyle(
                                                        color: Colors.grey[500],
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w500
                                                    ),),
                                                  SizedBox(
                                                    width: 5,
                                                  ),
                                                  Expanded(
                                                    child: TextField(
                                                      controller: _normalUserController,
                                                      key: ValueKey(6),
                                                      keyboardType: TextInputType.emailAddress,
                                                      decoration: InputDecoration(
                                                        enabledBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                            color: Colors.grey,
                                                          ),
                                                          borderRadius: BorderRadius.all(Radius.circular(10)),
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                            color: Colors.grey,
                                                          ),
                                                          borderRadius: BorderRadius.all(Radius.circular(10)),
                                                        ),
                                                        hintText: "your email",
                                                        hintStyle: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey[300]!,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 8,
                                                  ),
                                                  SizedBox(
                                                    width: 70,
                                                    height: 40,
                                                    child: ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        foregroundColor: Colors.white,
                                                        backgroundColor: Colors.black,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.all(Radius.circular(10)), // 사각형 모양 설정
                                                        ),
                                                      ),
                                                      onPressed: timeChecking
                                                          ? () async {
                                                        setState(() {
                                                          timeChecking = false;
                                                        });

                                                        String inputEmail = _normalUserController.text.trim();

                                                        if (inputEmail.isNotEmpty) {
                                                          try {
                                                            // 이메일을 전송할 수 있도록 새로운 유저 생성
                                                            final UserCredential verifyUser = await FirebaseAuth.instance
                                                                .createUserWithEmailAndPassword(
                                                              email: inputEmail,
                                                              password: "12345678",
                                                            );

                                                            if (verifyUser.user != null) {
                                                              await verifyUser.user!.sendEmailVerification(); // 인증 이메일 전송
                                                              setState(() {
                                                                _alertMessage = "인증 이메일이 전송되었습니다. 이메일을 확인해주세요.";
                                                              });
                                                            }

                                                            // 타이머 시작
                                                            timer = Timer.periodic(Duration(seconds: 1), (_) async {
                                                              attempts--; // 60초에서 1초씩 감소
                                                              setState(() {
                                                                _timeMessage = attempts < 10 ? "00:0$attempts" : "00:$attempts";
                                                              });

                                                              // 이메일 인증 확인
                                                              await checkEmailVerified(verifyUser.user!);
                                                              if (verification) {
                                                                timer!.cancel(); // 타이머 종료
                                                                setState(() {
                                                                  _alertMessage = "인증 완료되었습니다.";
                                                                  _timeMessage = "";
                                                                  verifyUser.user!.delete(); // 유저 삭제
                                                                  _email = inputEmail;
                                                                });
                                                              }

                                                              if (attempts == 0) {
                                                                timer!.cancel(); // 타이머 종료
                                                                verifyUser.user!.delete(); // 유저 삭제
                                                                attempts = 60;
                                                                setState(() {
                                                                  _alertMessage = "인증 시간이 지났습니다. 다시 인증하세요.";
                                                                  _verifyMsg = "재인증";
                                                                  _timeMessage = "";
                                                                  timeChecking = true;
                                                                });
                                                              }
                                                            });
                                                          } catch (e) {
                                                            if (e is FirebaseAuthException) {
                                                              if (e.code == 'invalid-email') {
                                                                setState(() {  // setState 추가
                                                                  _alertMessage = "이메일 형식이 올바르지 않습니다.";
                                                                  timeChecking = true;  // 재시도할 수 있도록 true로 변경
                                                                });
                                                              }
                                                            }
                                                            }
                                                        }
                                                        else
                                                          {
                                                            setState(() {
                                                              _alertMessage="이메일을 입력주세요.";
                                                              timeChecking=true;
                                                            });
                                                          }
                                                      }
                                                          : null,
                                                      child: Text(
                                                        _verifyMsg,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.w800,
                                                          fontSize: _verifyMsg == "인 증" ? 10 : 8,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                          ],
                                              ),
                                              Text("${_alertMessage}",
                                                style: TextStyle(
                                                  color: verification?Colors.blue : Colors.red,
                                                  fontSize: 10,
                                                ),),
                                              Text("${_timeMessage}",
                                                style: TextStyle(
                                                  color: Colors.black,
                                                ),),
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 40,
                                                    child: Text("비밀번호",
                                                      style: TextStyle(
                                                          color: Colors.grey[400],
                                                          fontSize: 11
                                                      ),),
                                                  ),
                                                  SizedBox(
                                                    width: 15,
                                                  ),
                                                  Expanded(
                                                    child: TextFormField(
                                                      key: ValueKey(7),
                                                      enabled: verification?true:false,
                                                      validator: (value){
                                                        if(value!.isEmpty||value.length<6)
                                                        {
                                                          return "비밀번호는 6글자 이상이어야 합니다.";
                                                        }
                                                        return null;
                                                      },
                                                      onSaved: (value){
                                                        _pwd=value;
                                                      },
                                                      keyboardType: TextInputType.emailAddress,
                                                      decoration: InputDecoration(
                                                        contentPadding: EdgeInsets.symmetric(vertical: 8,horizontal: 12),
                                                        enabledBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                            color: Colors.grey,
                                                          ),
                                                          borderRadius: BorderRadius.all(Radius.circular(15)),
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                            color: Colors.grey,
                                                          ),
                                                          borderRadius: BorderRadius.all(Radius.circular(15)),
                                                        ),
                                                        hintText: "password",
                                                        hintStyle: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey[300]!,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                              SizedBox(
                                                height: 20,
                                              ),
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 40,
                                                    child: Text("이름",
                                                      style: TextStyle(
                                                          color: Colors.grey[400],
                                                          fontSize: 15
                                                      ),),
                                                  ),
                                                  SizedBox(
                                                    width: 15,
                                                  ),
                                                  Expanded(
                                                    child: TextFormField(
                                                      key: ValueKey(8),
                                                      enabled: verification?true:false,
                                                      validator: (value){
                                                        if(value!.isEmpty)
                                                        {
                                                          return "이름을 작성해주세요.";
                                                        }
                                                        return null;
                                                      },
                                                      onSaved: (value){
                                                        _name=value;
                                                      },
                                                      keyboardType: TextInputType.emailAddress,
                                                      decoration: InputDecoration(
                                                        contentPadding: EdgeInsets.symmetric(vertical: 8,horizontal: 12),
                                                        enabledBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                            color: Colors.grey,
                                                          ),
                                                          borderRadius: BorderRadius.all(Radius.circular(15)),
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                            color: Colors.grey,
                                                          ),
                                                          borderRadius: BorderRadius.all(Radius.circular(15)),
                                                        ),
                                                        hintText: "name",
                                                        hintStyle: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey[300]!,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                              SizedBox(
                                                height: 20,
                                              ),
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 40,
                                                    child: Text("닉네임",
                                                      style: TextStyle(
                                                          color: Colors.grey[400],
                                                          fontSize: 15
                                                      ),),
                                                  ),
                                                  SizedBox(
                                                    width: 15,
                                                  ),
                                                  Expanded(
                                                    child: TextFormField(
                                                      key: ValueKey(9),
                                                      enabled: verification?true:false,
                                                      validator: (value){
                                                        if(value!.isEmpty)
                                                        {
                                                          return "닉네임을 작성해주세요.";
                                                        }
                                                        return null;
                                                      },
                                                      onSaved: (value){
                                                        _nickName=value;
                                                      },
                                                      keyboardType: TextInputType.emailAddress,
                                                      decoration: InputDecoration(
                                                        contentPadding: EdgeInsets.symmetric(vertical: 8,horizontal: 12),
                                                        enabledBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                            color: Colors.grey,
                                                          ),
                                                          borderRadius: BorderRadius.all(Radius.circular(15)),
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                            color: Colors.grey,
                                                          ),
                                                          borderRadius: BorderRadius.all(Radius.circular(15)),
                                                        ),
                                                        hintText: "nickname",
                                                        hintStyle: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey[300]!,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 60,
                                    ),
                                    SizedBox(
                                      width: 400,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(15)), // 사각형 모양을 위한 설정
                                          ),
                                        ),
                                        onPressed:verification? () async {
                                          await signup(_normalFormKey);
                                        }:null,
                                        child: Text(
                                          "회원가입",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                  ],
                )
              )
            ),
          ),
        ),
      ),
    );
  }
}

