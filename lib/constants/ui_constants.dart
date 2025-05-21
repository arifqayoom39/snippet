import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:snippet/constants/constants.dart';
import 'package:snippet/features/explore/view/explore_view.dart';
import 'package:snippet/features/notifications/views/notification_view.dart';
import 'package:snippet/features/tweet/widgets/tweet_list.dart';
import 'package:snippet/theme/pallete.dart';

class UIConstants {
  static AppBar appBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(
        'Snippet',
        style: TextStyle(
          color: Pallete.blueColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: false,
    );
  }

  static const List<Widget> bottomTabBarPages = [
    tweetList(),
    ExploreView(),
    NotificationView(),
  ];
}
