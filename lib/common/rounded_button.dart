import 'package:flutter/material.dart';
import 'package:snippet/theme/pallete.dart';

class RoundedButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final bool isLoading;

  const RoundedButton({
    Key? key,
    required this.onTap,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor ?? Pallete.blueColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                )
              : Text(
                  label,
                  style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontSize: fontSize ?? 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
