import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/common/common.dart';
import 'package:snippet/constants/constants.dart';
import 'package:snippet/features/auth/controller/auth_controller.dart';
import 'package:snippet/features/notifications/controller/notification_controller.dart';
import 'package:snippet/features/notifications/widget/notification_tile.dart';
import 'package:snippet/models/notification_model.dart' as model;
import 'package:snippet/theme/pallete.dart';

class NotificationView extends ConsumerWidget {
  const NotificationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserDetailsProvider).value;
    final isDarkMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      appBar: AppBar(
        backgroundColor: Pallete.backgroundColor,
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(color: Pallete.textColor),
        ),
        iconTheme: IconThemeData(color: Pallete.iconColor),
      ),
      body: currentUser == null
          ? const Loader()
          : ref.watch(getNotificationsProvider(currentUser.uid)).when(
                data: (notifications) {
                  return ref.watch(getLatestNotificationProvider).when(
                        data: (data) {
                          if (data.events.contains(
                            'databases.*.collections.${AppwriteConstants.notificationsCollection}.documents.*.create',
                          )) {
                            final latestNotif =
                                model.Notification.fromMap(data.payload);
                            if (latestNotif.uid == currentUser.uid) {
                              notifications.insert(0, latestNotif);
                            }
                          }

                          return notifications.isEmpty 
                              ? Center(
                                  child: Text(
                                    'No notifications yet',
                                    style: TextStyle(color: Pallete.textColor),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: notifications.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final notification = notifications[index];
                                    return NotificationTile(
                                      notification: notification,
                                    );
                                  },
                                );
                        },
                        error: (error, stackTrace) => ErrorText(
                          error: error.toString(),
                        ),
                        loading: () {
                          return notifications.isEmpty 
                              ? Center(
                                  child: Text(
                                    'No notifications yet',
                                    style: TextStyle(color: Pallete.textColor),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: notifications.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final notification = notifications[index];
                                    return NotificationTile(
                                      notification: notification,
                                    );
                                  },
                                );
                        },
                      );
                },
                error: (error, stackTrace) => ErrorText(
                  error: error.toString(),
                ),
                loading: () => const Loader(),
              ),
    );
  }
}
