import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:objectdetection/screen/login/signin_screen.dart';

class SignUpScreen extends StatefulWidget {

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final userRef = FirebaseFirestore.instance.collection("users");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height*0.15,
                ),
                Image.asset('images/logo.png'),
                SizedBox(
                  height: MediaQuery.of(context).size.height*0.05,
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: '이름',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이름을 입력해주세요';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: '이메일',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이메일을 입력해주세요';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요';
                    }
                    if (value.length < 6) {
                      return '비밀번호는 최소 6자 이상이어야 합니다';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),
                Container(
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
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[350],
                        shape: RoundedRectangleBorder( // 양쪽 모서리를 둥글게 변경
                          borderRadius: BorderRadius.circular(50),
                        ),
                        minimumSize: Size(double.infinity, 50)
                    ),
                    onPressed: () async {
                      if (_formKey.currentState.validate()) {
                        try {
                          UserCredential userCredential =
                          await FirebaseAuth.instance
                              .createUserWithEmailAndPassword(
                            email: _emailController.text.trim(),
                            password: _passwordController.text.trim(),
                          );
                          //display name
                          User loggedUser = FirebaseAuth.instance.currentUser;
                          loggedUser?.updateDisplayName(_nameController.text.trim());

                          // Save user's info to Firestore
                          String uid = userCredential.user.uid;
                          userRef.doc(uid).set({
                            'name': _nameController.text.trim(),
                            'email': _emailController.text.trim(),
                            // Add other user info here
                          }).then((value) => null).catchError((onError) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('사용자 정보를 저장하는 중에 오류가 발생했습니다')),
                            );
                          });

                          userCredential.user.sendEmailVerification();
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('회원가입'),
                                content: Text('회원가입에 성공하였습니다. 이메일 인증을 해주세요.'),
                                actions: [
                                  TextButton(
                                    child: Text('확인'),
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => SignInScreen()),
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        } on FirebaseAuthException catch (e) {
                          if (e.code == 'weak-password') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('비밀번호가 너무 약합니다')),
                            );
                          } else if (e.code == 'email-already-in-use') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('이미 가입된 이메일입니다')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('회원가입에 실패하였습니다')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('회원가입에 실패하였습니다')),
                          );
                        }
                      }
                    },
                    child: Text('회원가입',style: TextStyle(color: Colors.black)),
                  ),
                ),
                TextButton(
                  onPressed: (){
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignInScreen()));
                  },
                  child: Text(
                    '로그인',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
