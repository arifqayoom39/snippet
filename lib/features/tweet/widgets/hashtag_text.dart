import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:snippet/features/tweet/views/hashtag_view.dart';
import 'package:snippet/theme/pallete.dart';

class HashtagText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color textColor;
  final FontWeight fontWeight;

  HashtagText({
    Key? key,
    required this.text,
    this.fontSize = 16,
    Color? textColor,
    this.fontWeight = FontWeight.normal,
  })  : textColor = textColor ?? Pallete.textColor,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    List<TextSpan> textSpans = [];
    RegExp exp = RegExp(r"\B#[a-zA-Z0-9]+\b");
    
    // Find all hashtags in the text
    List<RegExpMatch> matches = exp.allMatches(text).toList();
    
    int currentIndex = 0;
    
    // Create TextSpans for each part of the text, making hashtags clickable
    for (var match in matches) {
      // Add regular text before the hashtag
      if (match.start > currentIndex) {
        textSpans.add(
          TextSpan(
            text: text.substring(currentIndex, match.start),
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ),
        );
      }
      
      // Add the hashtag with a special style and make it clickable
      String hashtag = text.substring(match.start, match.end);
      String hashtagWithoutSymbol = hashtag.substring(1); // Remove the # symbol
      
      textSpans.add(
        TextSpan(
          text: hashtag,
          style: TextStyle(
            color: Pallete.blueColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              // Navigate to the hashtag view
              Navigator.push(
                context,
                HashtagView.route(hashtagWithoutSymbol),
              );
            },
        ),
      );
      
      currentIndex = match.end;
    }
    
    // Add any remaining text after the last hashtag
    if (currentIndex < text.length) {
      textSpans.add(
        TextSpan(
          text: text.substring(currentIndex),
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(
        children: textSpans,
      ),
    );
  }
}
