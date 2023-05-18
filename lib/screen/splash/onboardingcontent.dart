
import 'package:flutter/material.dart';

class OnBoardingContent extends StatelessWidget {
  const OnBoardingContent({
    this.text,
    this.image,
  });
  final String text, image;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
            height: MediaQuery.of(context).size.height*0.05,
        ),
        Text(
          "SAKE",
          style: TextStyle(
              fontSize: 36,
              color: Colors.black,
              fontWeight: FontWeight.bold
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height*0.01,
        ),
        Text(
          text,
          textAlign: TextAlign.center,
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height*0.04,
        ),
        Image.asset(
          image,
          height: 350,
          width: 300,
        )
      ],
    );
  }
}
