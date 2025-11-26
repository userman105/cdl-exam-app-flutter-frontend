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
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero, // prevent shifting
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isActive ? Colors.black : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        //
        Container(
          margin: const EdgeInsets.only(top: 6),
          height: 2,
          width: underlineWidth,
          color: isActive ? Colors.black : Colors.transparent,
        ),
      ],
    );
  }
}

