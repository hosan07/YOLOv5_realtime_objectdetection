import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
class SettingPage extends StatefulWidget {
  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  var currentUser = FirebaseAuth.instance.currentUser;

  final _authentication = FirebaseAuth.instance;

  User loggedUser;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser(){
    try {
      final user = _authentication.currentUser;
      if (user != null) {
        loggedUser = user;
        print(loggedUser.email);
        print(loggedUser.displayName);
      }
    }catch(e){
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('설정'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '사용자 정보',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5.0),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(17.0),
                    child: Row(
                      children: [
                        Text(
                          '이름',
                          style: TextStyle(
                            fontSize: 17,
                          ),
                        ),
                        Spacer(),
                        Text(
                          '${FirebaseAuth.instance.currentUser.displayName}',
                          style: TextStyle(
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(17.0),
                    child: Row(
                      children: [
                        Text(
                          '이름',
                          style: TextStyle(
                            fontSize: 17,
                          ),
                        ),
                        Spacer(),
                        Text(
                          '${FirebaseAuth.instance.currentUser.email}',
                          style: TextStyle(
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.0),
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(17.0),
                child: Row(
                  children: [
                    Text(
                      '버전',
                      style: TextStyle(
                        fontSize: 17,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '0.01',
                      style: TextStyle(
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),

              SwitchListTile(
                title: Text('Email Notifications'),
                value: true,
                onChanged: (bool value) {
                  // 여기에 이메일 알림 설정을 처리하는 로직을 추가할 수 있습니다.
                },
              ),
              // 추가적인 설정 항목들을 여기에 추가할 수 있습니다.
            ],
          ),
        ),
      ),
    );
  }
}
