import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/apis/notification_api.dart';
import 'package:snippet/apis/user_api.dart';
import 'package:snippet/apis/auth_api.dart'; // Add this import
import 'package:snippet/core/enums/notification_type_enum.dart';
import 'package:snippet/models/notification_model.dart' as model;
import 'package:snippet/services/push_notification_service.dart';
import 'package:snippet/models/user_model.dart';

final notificationControllerProvider =
    StateNotifierProvider<NotificationController, bool>((ref) {
  return NotificationController(
    notificationAPI: ref.watch(notificationAPIProvider),
    pushNotificationService: ref.watch(pushNotificationServiceProvider),
    userAPI: ref.watch(userAPIProvider),
    authAPI: ref.watch(authAPIProvider), // Add authAPI here
  );
});

final getLatestNotificationProvider = StreamProvider((ref) {
  final notificationAPI = ref.watch(notificationAPIProvider);
  return notificationAPI.getLatestNotification();
});

final getNotificationsProvider = FutureProvider.family((ref, String uid) async {
  final notificationController =
      ref.watch(notificationControllerProvider.notifier);
  return notificationController.getNotifications(uid);
});

class NotificationController extends StateNotifier<bool> {
  final NotificationAPI _notificationAPI;
  final PushNotificationService _pushNotificationService;
  final UserAPI _userAPI;
  final AuthAPI _authAPI; // Add this field

  NotificationController({
    required NotificationAPI notificationAPI,
    required PushNotificationService pushNotificationService,
    required UserAPI userAPI,
    required AuthAPI authAPI, // Add this parameter
  })  : _notificationAPI = notificationAPI,
        _pushNotificationService = pushNotificationService,
        _userAPI = userAPI,
        _authAPI = authAPI, // Initialize the field
        super(false);

  void createNotification({
    required String text,
    required String postId,
    required NotificationType notificationType,
    required String uid,
    UserModel? currentUser, // Current user sending the notification
  }) async {
    final notification = model.Notification(
      text: text,
      postId: postId,
      id: '',
      uid: uid,
      notificationType: notificationType,
    );

    // Create local notification
    final res = await _notificationAPI.createNotification(notification);

    // If local notification was successful, send push notification
    res.fold(
      (l) => null,
      (r) async {
        try {
          // Get user data using the user API
          final userDoc = await _userAPI.getUserData(uid);
          
          // Use the UserModel to properly parse the data
          final user = UserModel.fromMap(userDoc.data);
          
          // Get the OneSignal player ID from the user model
          final oneSignalId = user.oneSignalId;

          if (oneSignalId.isNotEmpty) {
            // If currentUser is null, try to get the sender's profile
            UserModel? senderProfile = currentUser;
            if (senderProfile == null) {
              // Try to get the current user's profile if not provided
              try {
                final currentUserDoc = await _authAPI.currentUserAccount();
                if (currentUserDoc != null) {
                  final senderDoc = await _userAPI.getUserData(currentUserDoc.$id);
                  senderProfile = UserModel.fromMap(senderDoc.data);
                }
              } catch (e) {
                print('Error getting sender profile: $e');
              }
            }

            // Format notification title based on type
            String title = 'snippet Clone';
            switch (notificationType) {
              case NotificationType.like:
                title = senderProfile != null ? "${senderProfile.name} liked your tweet" : 'New Like';
                break;
              case NotificationType.retweet:
                title = senderProfile != null ? "${senderProfile.name} retweeted your tweet" : 'New Retweet';
                break;
              case NotificationType.follow:
                title = senderProfile != null ? "${senderProfile.name} followed you" : 'New Follower';
                break;
              case NotificationType.reply:
                title = senderProfile != null ? "${senderProfile.name} replied to your tweet" : 'New Reply';
                break;
              default:
                title = 'New Notification';
            }

            // Send push notification with sender profile
            await _pushNotificationService.sendNotification(
              targetUserId: oneSignalId,
              title: title,
              content: text,
              type: notificationType,
              postId: postId,
              senderProfile: senderProfile, // Pass sender profile with image
            );
          }
        } catch (e) {
          print('Error sending push notification: $e');
        }
      },
    );
  }

  Future<List<model.Notification>> getNotifications(String uid) async {
    final notifications = await _notificationAPI.getNotifications(uid);
    return notifications
        .map((e) => model.Notification.fromMap(e.data))
        .toList();
  }
}
