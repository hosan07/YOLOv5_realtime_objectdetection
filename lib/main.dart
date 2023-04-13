import 'dart:collection';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:objectdetection/bottomnavigation/main_naviagation_screen.dart';
import 'package:objectdetection/screen/home/widget/diary/diary_screen.dart';
import 'package:objectdetection/screen/home/widget/map/pages/maps.dart';
import 'package:objectdetection/screen/login/login_screen.dart';

import 'constants/sizes.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //initialRoute: '/',
      routes: {
        '/map' : (context) => MapPage(),
        '/diary': (context) => DiaryScreen(),
      },
      title: 'Object Detection TFLite',
      theme: ThemeData(
        //backgroundColor: Color(0xfff5f5f5),
        canvasColor: Colors.transparent,
        //scaffoldBackgroundColor: Color(0xfff5f5f5),
        scaffoldBackgroundColor: Color(0xFFffffff),
        primaryColor: Color(0xFFffffff),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFFE9435A),
        ),
        splashColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w300,
            fontSize: Sizes.size16 + Sizes.size2,
          ),
        ),
      ),
      //home: HomeView(),
      //home: HomePage(),
      //home: MainNavigationScreen(),
      home: LoginScreen(),
    );
  }
}
