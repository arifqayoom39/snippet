// ignore_for_file: camel_case_types, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:snippet/theme/pallete.dart';

class tweetIconButton extends StatelessWidget {
  final String pathName;
  final String text;
  final VoidCallback onTap;
  final double fontSize;
  final Color? color;

  const tweetIconButton({
    super.key,
    required this.pathName,
    required this.text,
    required this.onTap,
    required this.fontSize,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          SvgPicture.asset(
            pathName,
            colorFilter: ColorFilter.mode(color ?? Pallete.greyColor, BlendMode.srcIn),
            height: 18,
          ),
          Container(
            margin: const EdgeInsets.all(6),
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                color: color ?? Pallete.greyColor,
              ),
            ),
          )
        ],
      ),
    );
  }
}
