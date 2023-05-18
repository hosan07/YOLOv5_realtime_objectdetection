import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:objectdetection/screen/home/widget/diary/diary_screen.dart';
import 'package:objectdetection/screen/home/widget/map/pages/maps.dart';
import 'package:objectdetection/screen/home/widget/objectdetection/ui/home_view.dart';
import 'package:objectdetection/screen/home/widget/objectdetection/ui/homeview4.dart';
import 'package:objectdetection/screen/home/widget/objectdetection/yolo_5/HomeScreen.dart';
import 'package:objectdetection/screen/login/signin_screen.dart';
import 'package:objectdetection/screen/login/signup_screen.dart';
import 'package:objectdetection/screen/splash/splash_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'bottomnavigation/main_naviagation_screen.dart';
import 'constants/sizes.dart';
import 'lib2/ui/home_view.dart';
import 'lib3/ui/home_view.dart';
import 'lib5/choosedemostate.dart';
//import 'lib2/ui/home_view.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    await Permission.storage.request();
  }
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
      //home: HomeVieww(),
      //home: HomeView4(),
      //home: HomeView(),
      //home: MainNavigationScreen(),
      //home: SignInScreen(),
      //home: SplashScreen(),
      home: YOLO5Screen(),
      //home: ChooseDemo(),
      //home: MapPage(),
    );
  }
}

