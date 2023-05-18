import 'package:flutter/material.dart';
import 'package:objectdetection/screen/login/signin_screen.dart';

import 'defalutbutton.dart';
import 'onboardingcontent.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int currentPage = 0;
  List<Map<String, String>> splashData = [
    {"text": "저희 세이크 앱에 오신 것을 환영합니다", "image": "images/logo.png"},
    {"text": "안전한 주행을 위해 도와드리겠습니다!", "image": "images/Group 146.png"},
    {"text": "오늘도 안전한 자전거 주행 되세요", "image": "images/rider.png"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: PageView.builder(
                  onPageChanged: (value) {
                    setState(() {
                      currentPage = value;
                    });
                  },
                  itemCount: splashData.length,
                  itemBuilder: (context, index) => OnBoardingContent(
                    text: "${splashData.elementAt(index)['text']}",
                    image: "${splashData.elementAt(index)['image']}",
                    //image: splashData[index]["image"],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height*0.02,
                      ),
                      Row(
                        children: List.generate(splashData.length,
                              (index) => buildDot(index),
                        ),
                        mainAxisAlignment: MainAxisAlignment.center,
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height*0.15,
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                blurRadius: 3.0,
                                spreadRadius: 0.0,
                                offset: const Offset(0, 7),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: (){
                              Navigator.pushReplacement(context, MaterialPageRoute(
                                builder: (context) => SignInScreen(),
                              ));
                            },
                            style: ElevatedButton.styleFrom(
                              primary: Colors.grey[350],
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text('계속하기',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,

                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  AnimatedContainer buildDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      padding: EdgeInsets.only(right: 5.0),
      height: 6,
      width: currentPage == index ? 50 : 10,
      decoration: BoxDecoration(
          color: currentPage == index ? Colors.grey[200] : Colors.grey,
          borderRadius: BorderRadius.circular(3.0)),
    );
  }
}
