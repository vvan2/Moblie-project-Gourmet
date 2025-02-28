import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import "package:firebase_core/firebase_core.dart";
import 'package:gourmet_app/screens/loginScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 추가
import 'package:firebase_storage/firebase_storage.dart'; // 추가
import 'package:path_provider/path_provider.dart'; // 추가
import 'dart:io'; // 추가
import 'dart:convert'; // 추가
import 'firebase_options.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Future<void> initializeApp() async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("Firebase 초기화 성공!");

      await Future.delayed(Duration(seconds: 1));
    }

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "gourmetApp",
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.white,
        ),
        home: FutureBuilder(
            future: initializeApp(),
            builder: (context, snapshot) {
              if(snapshot.connectionState == ConnectionState.waiting) {
                return SafeArea(
                  child: Container(
                    decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage("images/loading.png"),
                          fit: BoxFit.fill,
                        )
                    ),
                  ),
                );
              }
              return LoginScreen();
            }
        )
    );
  }
}