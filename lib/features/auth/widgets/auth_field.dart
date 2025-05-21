import 'package:flutter/material.dart';
import 'package:snippet/theme/pallete.dart';

class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isPassword;
  final TextInputType? keyboardType;
  final Icon? prefixIcon;
  final Function(String)? onChanged; // Added onChanged parameter

  const AuthField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.isPassword = false,
    this.keyboardType,
    this.prefixIcon,
    this.onChanged, // Added to constructor parameters
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Pallete.greyColor),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Pallete.greyColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(15),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Pallete.blueColor, width: 1.5),
          borderRadius: BorderRadius.circular(15),
        ),
        contentPadding: const EdgeInsets.all(18),
        prefixIcon: prefixIcon,
        fillColor: Pallete.backgroundColor,
        filled: true,
      ),
      obscureText: isPassword,
      keyboardType: keyboardType,
      onChanged: onChanged, // Pass the onChanged callback to TextField
    );
  }
}
