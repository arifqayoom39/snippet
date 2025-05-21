import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:snippet/core/enums/notification_type_enum.dart';
import 'package:snippet/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:snippet/core/utils.dart';

// OneSignal App ID
const String oneSignalAppId = '-------App ID-------';
// OneSignal REST API Key
const String oneSignalRestApiKey = '-------------OneSignal Api Key-----------------';

// Android channel definitions
const String DEFAULT_ANDROID_CHANNEL_ID = 'snippet_default_channel';
const String DEFAULT_ANDROID_CHANNEL_NAME = 'snippet Notifications';

// Configuration for production scalability
const int maxRetries = 3;
const int batchSize = 100; // For bulk notifications
const Duration throttleWindow = Duration(seconds: 2); // Throttle notifications
const Duration backoffDuration = Duration(seconds: 1); // Exponential backoff

final pushNotificationServiceProvider = Provider((ref) {
  return PushNotificationService();
});

class PushNotificationService {
  
  // Queue for batching notifications
  final List<Map<String, dynamic>> _notificationQueue = [];
  Timer? _batchTimer;
  
  // Throttling mechanism
  
  // Analytics tracking
  int _successfulNotifications = 0;
  int _failedNotifications = 0;

  Future<void> initializeOneSignal() async {
    // Set log level for debugging
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.Debug.setAlertLevel(OSLogLevel.none);
    
    // Initialize OneSignal
    OneSignal.initialize(oneSignalAppId);
    
    // Set up Android notification channels
    await _setupNotificationChannels();
    
    // Request permission
    await OneSignal.Notifications.requestPermission(true);
    
    // Setup user subscription observers
    OneSignal.User.pushSubscription.addObserver((state) {
      print("Push subscription state changed:");
      print("Opted in: ${OneSignal.User.pushSubscription.optedIn}");
      print("User ID: ${OneSignal.User.pushSubscription.id}");
      print("Token: ${OneSignal.User.pushSubscription.token}");
    });
    
    // Set user observer
    OneSignal.User.addObserver((state) {
      var userState = state.jsonRepresentation();
      print('OneSignal user changed: $userState');
    });
    
    // Set permission observer
    OneSignal.Notifications.addPermissionObserver((state) {
      print("Push notification permission changed: $state");
    });
    
    // Set notification click handler
    OneSignal.Notifications.addClickListener((event) {
      print('NOTIFICATION CLICKED: ${event.notification.jsonRepresentation()}');
      
      // Handle notification click based on type
      _handleNotificationClick(event);
    });
    
    // Set foreground notification handler
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print('NOTIFICATION WILL DISPLAY: ${event.notification.jsonRepresentation()}');
      
      // You can prevent the notification from displaying
      // event.preventDefault();
      
      // Or allow it to display
      event.notification.display();
      
    });
    
    // Setup in-app message handlers
    OneSignal.InAppMessages.addClickListener((event) {
      print('In-App Message clicked: ${event.result.jsonRepresentation()}');
    });
    
    OneSignal.InAppMessages.addWillDisplayListener((event) {
      print("Will display in-app message: ${event.message.messageId}");
    });
    
    OneSignal.InAppMessages.addDidDisplayListener((event) {
      print("Did display in-app message: ${event.message.messageId}");
    });
    
    OneSignal.InAppMessages.addWillDismissListener((event) {
      print("Will dismiss in-app message: ${event.message.messageId}");
    });
    
    OneSignal.InAppMessages.addDidDismissListener((event) {
      print("Did dismiss in-app message: ${event.message.messageId}");
    });
  }

  // Set up Android notification channels
  Future<void> _setupNotificationChannels() async {
    try {
      // Create default notification channel
      // NOTE: This is only needed for Flutter implementation; 
      // for actual OneSignal implementation, channels should be created in the OneSignal dashboard
      print('Setting up Android notification channels');
    } catch (e) {
      print('Error setting up notification channels: $e');
    }
  }

  // Handle notification clicks based on type
  void _handleNotificationClick(OSNotificationClickEvent event) {
    // Extract data from the notification
    final data = event.notification.additionalData;
    if (data != null) {
      // Check for notification type
      final typeString = data['type'];
      final postId = data['postId'];
      
      // Here you could navigate to different screens based on the notification type
      // For example, if it's a like notification, navigate to the specific post
      if (typeString != null && postId != null) {
        // Example navigation logic (implement actual navigation in your app)
        print('Should navigate to post: $postId for notification type: $typeString');
      }
    }
  }

  // Set user ID from app to OneSignal for targeting
  Future<void> setExternalUserId(String uid) async {
    // Don't try to use the result of login()
    await OneSignal.login(uid);
    print('Set external user ID: $uid');
    
    // You can also add aliases for the user if needed
    // await OneSignal.User.addAlias("snippet_id", uid);
  }
  
  // Remove external user ID when logging out
  Future<void> removeExternalUserId() async {
    // Don't try to use the result of logout()
    await OneSignal.logout();
    print('Removed external user ID');
  }

  // Get OneSignal user ID
  Future<String?> getOneSignalUserId() async {
    return await OneSignal.User.getOnesignalId();
  }

  // Get current OneSignal player ID - this is what we need to store for notifications
  Future<String?> getPlayerId() async {
    try {
      // Get the current subscription state
      String? playerId = OneSignal.User.pushSubscription.id;
      print('Current OneSignal Player ID: $playerId');
      return playerId;
    } catch (e) {
      print('Error getting OneSignal player ID: $e');
      return null;
    }
  }
  
  // Helper method to check if push notifications are permitted
  Future<bool?> arePushNotificationsEnabled() async {
    try {
      return OneSignal.User.pushSubscription.optedIn;
    } catch (e) {
      print('Error checking push notification status: $e');
      return false;
    }
  }

  // Send notification to a specific user using the OneSignal REST API
  Future<bool> sendNotification({
    required String targetUserId, 
    required String title,
    required String content,
    required NotificationType type,
    String? postId,
    UserModel? senderProfile,
  }) async {
    try {
      // Create notification payload according to OneSignal REST API format
      final Map<String, dynamic> notificationData = {
        'app_id': oneSignalAppId,
        'include_player_ids': [targetUserId],
        'headings': {'en': title},
        'contents': {'en': content},
        'data': {
          'type': type.toString(),
          'postId': postId,
          'senderId': senderProfile?.uid,
          'senderName': senderProfile?.name,
        },
      };

      // Add profile image if available - ensure the URLs are publicly accessible
      if (senderProfile != null && senderProfile.profilePic.isNotEmpty) {
        // Make sure the URL is valid and accessible externally
        final String imageUrl = _ensureValidImageUrl(senderProfile.profilePic);
        
        print('Using profile image URL: $imageUrl');
        
        // IMPORTANT: Don't specify android_channel_id here; let OneSignal use the default channel
        // Instead, just specify the notification properties
        notificationData['large_icon'] = imageUrl;
        
        // For expandable image in notifications
        notificationData['big_picture'] = imageUrl;
        
        // For iOS: Add attachments
        notificationData['ios_attachments'] = {
          'id1': imageUrl
        };
        
        // Add image directly to content for services that support it
        notificationData['chrome_web_icon'] = imageUrl;
        notificationData['firefox_icon'] = imageUrl;
      }

      print('Sending notification to player ID: $targetUserId');
      print('Notification payload: ${json.encode(notificationData)}');
      
      // Send notification using HTTP POST to OneSignal API
      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $oneSignalRestApiKey',
        },
        body: json.encode(notificationData),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Successfully sent notification to user: $targetUserId');
        print('Response: ${response.body}');
        return true;
      } else {
        print('Failed to send notification: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending push notification: $e');
      return false;
    }
  }
  
  // Make sure image URLs are properly formatted and accessible
  String _ensureValidImageUrl(String url) {
    // If it's already a full URL, return it
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    
    // If it's an Appwrite storage URL, make sure it's publicly accessible
    if (url.contains('storage')) {
      // For Appwrite storage URLs, make sure they have the right format
      // This depends on your Appwrite setup and might need adjustment
      return url;
    }
    
    // Fallback to a default image if the URL is invalid
    return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent("snippet User")}&background=random';
  }
  
  // Batch send notifications (for multiple recipients)
  Future<bool> sendBatchNotifications({
    required List<String> targetUserIds,
    required String title,
    required String content,
    required NotificationType type,
    String? postId,
    UserModel? senderProfile,
  }) async {
    if (targetUserIds.isEmpty) return true;
    
    try {
      // Process in batches for scalability
      final totalBatches = (targetUserIds.length / batchSize).ceil();
      var successCount = 0;
      
      for (var i = 0; i < totalBatches; i++) {
        final start = i * batchSize;
        final end = (start + batchSize < targetUserIds.length) 
            ? start + batchSize 
            : targetUserIds.length;
        
        final batchIds = targetUserIds.sublist(start, end);
        
        // Prepare batch notification
        final Map<String, dynamic> batchNotification = {
          'app_id': oneSignalAppId,
          'include_player_ids': batchIds,
          'headings': {'en': title},
          'contents': {'en': content},
          'data': {
            'type': type.toString(),
            'postId': postId,
            'senderId': senderProfile?.uid,
            'senderName': senderProfile?.name,
          },
        };
        
        if (senderProfile != null && senderProfile.profilePic.isNotEmpty) {
          batchNotification['large_icon'] = senderProfile.profilePic;
          batchNotification['ios_attachments'] = {'profile_img': senderProfile.profilePic};
        }
        
        final success = await _sendNotificationWithRetry(batchNotification);
        if (success) successCount++;
        
        // Respect rate limits with a small delay between batches
        if (i < totalBatches - 1) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
      
      // Return true if all batches were successful
      return successCount == totalBatches;
    } catch (e) {
      print('Error in batch notification: $e');
      _failedNotifications++;
      return false;
    }
  }
  
  // Notification queueing for throttling
  bool _addToQueue(
    String targetUserId,
    String title,
    String content,
    NotificationType type,
    String? postId,
    UserModel? senderProfile,
  ) {
    _notificationQueue.add({
      'targetUserId': targetUserId,
      'title': title,
      'content': content,
      'type': type,
      'postId': postId,
      'senderProfile': senderProfile,
    });
    
    // Start timer to process queue if not already running
    _batchTimer ??= Timer(const Duration(seconds: 3), _processQueue);
    
    return true;
  }
  
  // Process queued notifications
  Future<void> _processQueue() async {
    if (_notificationQueue.isEmpty) {
      _batchTimer = null;
      return;
    }
    
    print('Processing ${_notificationQueue.length} queued notifications');
    
    // Group notifications by user for efficiency
    final Map<String, List<Map<String, dynamic>>> userNotifications = {};
    
    for (var notification in _notificationQueue) {
      final userId = notification['targetUserId'] as String;
      userNotifications[userId] ??= [];
      userNotifications[userId]!.add(notification);
    }
    
    // Process each user's notifications
    for (var entry in userNotifications.entries) {
      final userId = entry.key;
      final notifications = entry.value;
      
      if (notifications.length == 1) {
        // Single notification
        final notification = notifications.first;
        await sendNotification(
          targetUserId: notification['targetUserId'],
          title: notification['title'],
          content: notification['content'],
          type: notification['type'],
          postId: notification['postId'],
          senderProfile: notification['senderProfile'],
        );
      } else {
        // Batch notification with summary
        await sendNotification(
          targetUserId: userId,
          title: 'Multiple new notifications',
          content: 'You have ${notifications.length} new notifications',
          type: NotificationType.follow, // Generic type
          senderProfile: null,
        );
      }
      
      // Respect throttling
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // Clear queue and reset timer
    _notificationQueue.clear();
    _batchTimer = null;
  }
  
  // Send with retry logic for reliability
  Future<bool> _sendNotificationWithRetry(Map<String, dynamic> notificationData, {int attempt = 1}) async {
    try {
      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $oneSignalRestApiKey',
        },
        body: json.encode(notificationData),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Successfully sent notification (attempt $attempt)');
        _successfulNotifications++;
        return true;
      } else {
        print('Failed to send notification (attempt $attempt): ${response.body}');
        
        // Retry logic with exponential backoff
        if (attempt < maxRetries) {
          final backoff = Duration(milliseconds: backoffDuration.inMilliseconds * (1 << (attempt - 1)));
          print('Retrying after $backoff...');
          await Future.delayed(backoff);
          return _sendNotificationWithRetry(notificationData, attempt: attempt + 1);
        } else {
          _failedNotifications++;
          return false;
        }
      }
    } catch (e) {
      print('Error during notification attempt $attempt: $e');
      
      // Retry on network errors
      if (attempt < maxRetries) {
        final backoff = Duration(milliseconds: backoffDuration.inMilliseconds * (1 << (attempt - 1)));
        print('Retrying after $backoff...');
        await Future.delayed(backoff);
        return _sendNotificationWithRetry(notificationData, attempt: attempt + 1);
      } else {
        _failedNotifications++;
        return false;
      }
    }
  }
  
  // Get notification analytics
  Map<String, dynamic> getNotificationAnalytics() {
    return {
      'successful': _successfulNotifications,
      'failed': _failedNotifications,
      'success_rate': _successfulNotifications + _failedNotifications > 0
          ? (_successfulNotifications / (_successfulNotifications + _failedNotifications) * 100).toStringAsFixed(2) + '%'
          : 'N/A',
    };
  }
  
  // Clear analytics counters
  void resetAnalytics() {
    _successfulNotifications = 0;
    _failedNotifications = 0;
  }

  // Add tags to segment users
  Future<void> addTag(String key, String value) async {
    await OneSignal.User.addTagWithKey(key, value);
  }
  
  // Add multiple tags
  Future<void> addTags(Map<String, String> tags) async {
    await OneSignal.User.addTags(tags);
  }
  
  // Remove a specific tag
  Future<void> removeTag(String key) async {
    await OneSignal.User.removeTag(key);
  }
  
  // Remove multiple tags
  Future<void> removeTags(List<String> keys) async {
    await OneSignal.User.removeTags(keys);
  }
  
  // Get all user tags
  Future<Map<String, dynamic>?> getTags() async {
    return await OneSignal.User.getTags();
  }
  
  // Set user language
  Future<void> setLanguage(String languageCode) async {
    await OneSignal.User.setLanguage(languageCode);
  }
  
  // Opt in to notifications
  Future<void> optIn() async {
    await OneSignal.User.pushSubscription.optIn();
  }
  
  // Opt out of notifications
  Future<void> optOut() async {
    await OneSignal.User.pushSubscription.optOut();
  }
  
  // Track custom events for analytics
  Future<void> addOutcome(String name) async {
    await OneSignal.Session.addOutcome(name);
  }
  
  // Track unique outcome events
  Future<void> addUniqueOutcome(String name) async {
    await OneSignal.Session.addUniqueOutcome(name);
  }
  
  // Track outcome events with value
  Future<void> addOutcomeWithValue(String name, double value) async {
    await OneSignal.Session.addOutcomeWithValue(name, value);
  }
}
