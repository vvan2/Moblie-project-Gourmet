import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gourmet_app/screens/signupScreen.dart';

import 'mapScreen.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends State<LoginScreen> {

  final _formKey=GlobalKey<FormState>();
  String? _userEmail;
  String? _userPwd;


  Future<void> login() async {
    final check = _formKey.currentState!.validate(); //모두 null을 리턴하면 true 리턴
    if (check) {
      _formKey.currentState!.save();
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
            email: _userEmail!, password: _userPwd!);
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) {
              return MapScreen(0);
            }),
                (route) => false
        );
      } catch (e) {
        String message = '로그인 실패';
        if (e is FirebaseAuthException) {
          if (e.code == 'user-not-found') {
            message = '사용자를 찾을 수 없습니다.';
          } else if (e.code == 'wrong-password') {
            message = '잘못된 비밀번호입니다.';
          } else {
            message = '${e} 로그인 실패';
          }
        }
        // Snackbar 띄우기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: Duration(seconds: 1),
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
          child: SafeArea(
            child: Container(
              child: Column(
                children: [
                  SizedBox(
                    height: 140,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Gourmet",
                        style: GoogleFonts.poppins(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                SizedBox(
                  height: 100,
                ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 35),
                    child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("이메일",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),),
                            TextFormField(
                              key: ValueKey(1),
                              validator: (value){
                                if(value!.isEmpty)
                                {
                                  return "이메일을 작성해주세요.";
                                }
                                else if(!value.contains("@")){
                                  return "이메일 형식을 갖추세요.";
                                }
                                return null;
                              },
                              onSaved: (value){
                                _userEmail=value;
                              },
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
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
                                hintText: "email",
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[300]!,
                                ),
                               ),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Text("비밀번호",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),),
                            TextFormField(
                              key: ValueKey(2),
                              validator: (value){
                                if(value!.isEmpty)
                                {
                                  return "비밀번호를 작성해주세요.";
                                }
                                return null;
                              },
                              onSaved: (value){
                                _userPwd=value;
                              },
                              obscureText : true,
                              decoration: InputDecoration(
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
                          ],
                        )
                    ),
                  ),
                  SizedBox(
                    height: 150,
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width-68,
                    child: ElevatedButton(

                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15)), // 사각형 모양을 위한 설정
                          ),
                        ),
                        onPressed: ()async{
                          await login();
                        },
                        child: Text("로그인 하기",
                          style: TextStyle(
                              fontWeight: FontWeight.w800
                          ),)
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width-68,
                    child: ElevatedButton(

                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.grey[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15)), // 사각형 모양을 위한 설정
                          ),
                        ),
                        onPressed: (){
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context){
                                return SignupScreen();
                              })
                          );
                        },
                        child: Text("회원가입 하기",
                        style: TextStyle(
                          fontWeight: FontWeight.w800
                        ),)
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
