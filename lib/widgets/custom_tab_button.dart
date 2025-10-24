import 'package:flutter/material.dart';

class CustomTabButton extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onTap;
  final double underlineWidth;

  const CustomTabButton({
    Key? key,
    required this.text,
    required this.isActive,
    required this.onTap,
    required this.underlineWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: onTap,
          child: Text(
            text,
            style: TextStyle(
              color: isActive ? Colors.black : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (isActive)
          Container(
            margin: const EdgeInsets.only(top: 6),
            height: 4,
            width: underlineWidth,
            color: Colors.black,
          ),
      ],
    );
  }
}
