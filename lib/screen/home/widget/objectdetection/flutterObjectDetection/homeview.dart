import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../lib5/RunModelByCameraDemo.dart';

class ChooseDemo extends StatefulWidget {
  const ChooseDemo({Key key}) : super(key: key);

  @override
  State<ChooseDemo> createState() => _ChooseDemoState();
}

class _ChooseDemoState extends State<ChooseDemo> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Pytorch Mobile Example'),
        ),
        body: Builder(
            builder: (context) {
              return Center(
                child: Column(
                  children: [
                    TextButton(
                      onPressed: () => {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RunModelByCameraDemo()),
                        )
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text(
                        "Run Model with Camera",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
        ),
      ),
    );
  }
}