import 'package:flutter/material.dart';
class UserScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text('사용자',style: Theme.of(context).appBarTheme.titleTextStyle,),
      ),
      body: Column(
        children: [
          Text('d'),
        ],
      ),
    );
  }
}
