import 'package:flutter/material.dart';

class DefaultButton extends StatelessWidget {
  const DefaultButton({
    this.text,
    this.press,
  });
  final String text;
  final Function() press;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      /*shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(23)
      ),*/
      onPressed: press,
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[200]
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          color: Colors.white,
        ),
      ),
    );
  }
}
