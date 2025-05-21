// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:snippet/constants/constants.dart';
import 'package:snippet/core/enums/notification_type_enum.dart';
import 'package:snippet/models/notification_model.dart' as model;
import 'package:snippet/theme/pallete.dart';

class NotificationTile extends ConsumerWidget {
  final model.Notification notification;
  const NotificationTile({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: notification.notificationType == NotificationType.follow
          ? const Icon(
              Icons.person,
              color: Pallete.blueColor,
            )
          : notification.notificationType == NotificationType.like
              ? SvgPicture.asset(
                  AssetsConstants.likeFilledIcon,
                  color: Pallete.redColor,
                  height: 20,
                )
              : notification.notificationType == NotificationType.retweet
                  ? SvgPicture.asset(
                      AssetsConstants.retweetIcon,
                      colorFilter: ColorFilter.mode(Pallete.iconColor, BlendMode.srcIn),
                      height: 20,
                    )
                  : null,
      title: Text(
        notification.text,
        style: TextStyle(color: Pallete.textColor),
      ),
    );
  }
}
