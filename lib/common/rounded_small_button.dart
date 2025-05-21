import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/theme/pallete.dart';

class RoundedSmallButton extends ConsumerWidget {
  final VoidCallback onTap;
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final int fontSize;
  final EdgeInsets padding;

  const RoundedSmallButton({
    super.key,
    required this.onTap,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.fontSize = 15,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final defaultBackgroundColor = backgroundColor ?? 
        (isDarkMode ? Pallete.whiteColor : Pallete.blueColor);
    final defaultTextColor = textColor ?? 
        (isDarkMode ? Pallete.backgroundColorDark : Pallete.whiteColor);

    return InkWell(
      onTap: onTap,
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            color: defaultTextColor,
            fontSize: fontSize.toDouble(),
          ),
        ),
        backgroundColor: defaultBackgroundColor,
        labelPadding: padding,
      ),
    );
  }
}
