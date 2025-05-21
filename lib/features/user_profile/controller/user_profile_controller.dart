import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/apis/storage_api.dart';
import 'package:snippet/apis/tweet_api.dart';
import 'package:snippet/apis/user_api.dart';
import 'package:snippet/core/enums/notification_type_enum.dart';
import 'package:snippet/core/recommendation/recommendation_service.dart';
import 'package:snippet/core/utils.dart';
import 'package:snippet/features/auth/controller/auth_controller.dart';
import 'package:snippet/features/notifications/controller/notification_controller.dart';
import 'package:snippet/features/tweet/controller/tweet_controller.dart';
import 'package:snippet/models/tweet_model.dart';
import 'package:snippet/models/user_model.dart';

final userProfileControllerProvider =
    StateNotifierProvider<UserProfileController, bool>((ref) {
  return UserProfileController(
    ref: ref,
    tweetAPI: ref.watch(tweetAPIProvider),
    storageAPI: ref.watch(storageAPIProvider),
    userAPI: ref.watch(userAPIProvider),
    notificationController: ref.watch(notificationControllerProvider.notifier),
  );
});

final getUsertweetsProvider = FutureProvider.family((ref, String uid) async {
  final userProfileController =
      ref.watch(userProfileControllerProvider.notifier);
  return userProfileController.getUsertweets(uid);
});

final getLatestUserProfileDataProvider = StreamProvider((ref) {
  final userAPI = ref.watch(userAPIProvider);
  return userAPI.getLatestUserProfileData();
});

final getUserFollowListProvider = FutureProvider.autoDispose.family<List<UserModel>, String>(
  (ref, param) async {
    print('DEBUG: getUserFollowListProvider called with param: $param');
    
    // Parse the parameter (format: "userId:type")
    final parts = param.split(':');
    final userId = parts[0];
    final type = parts[1];
    
    final userProfileController = ref.watch(userProfileControllerProvider.notifier);
    
    // Keep the provider alive for 2 minutes to avoid unnecessary refetching
    ref.keepAlive();
    
    return userProfileController.getUserFollowList(
      userId: userId,
      type: type,
    );
  },
);

// Add this provider for interest-based user recommendations
final getRecommendedUsersProvider = FutureProvider.autoDispose((ref) async {
  final userProfileController = ref.watch(userProfileControllerProvider.notifier);
  return userProfileController.getRecommendedUsers();
});

class UserProfileController extends StateNotifier<bool> {
  final ItweetAPI _tweetAPI;
  final StorageAPI _storageAPI;
  final UserAPI _userAPI;
  final NotificationController _notificationController;
  final Ref _ref; // Add this line

  UserProfileController({
    required ItweetAPI tweetAPI,
    required StorageAPI storageAPI,
    required UserAPI userAPI,
    required NotificationController notificationController,
    required Ref ref, // Add this parameter
  })  : _tweetAPI = tweetAPI,
        _storageAPI = storageAPI,
        _userAPI = userAPI,
        _notificationController = notificationController,
        _ref = ref, // Initialize the field
        super(false);

  Future<List<Tweet>> getUsertweets(String uid) async {
    final tweets = await _tweetAPI.getUsertweets(uid);
    return tweets.map((e) => Tweet.fromMap(e.data)).toList();
  }

  void updateUserProfile({
    required UserModel userModel,
    required BuildContext context,
    required File? bannerFile,
    required File? profileFile,
  }) async {
    state = true;
    if (bannerFile != null) {
      final bannerUrl = await _storageAPI.uploadImage([bannerFile]);
      userModel = userModel.copyWith(
        bannerPic: bannerUrl[0],
      );
    }

    if (profileFile != null) {
      final profileUrl = await _storageAPI.uploadImage([profileFile]);
      userModel = userModel.copyWith(
        profilePic: profileUrl[0],
      );
    }

    final res = await _userAPI.updateUserData(userModel);
    state = false;
    res.fold(
      (l) => showSnackBar(context, l.message),
      (r) => Navigator.pop(context),
    );
  }

  void followUser({
    required UserModel user,
    required BuildContext context,
    required UserModel currentUser,
  }) async {
    // already following
    if (currentUser.following.contains(user.uid)) {
      user.followers.remove(currentUser.uid);
      currentUser.following.remove(user.uid);
    } else {
      user.followers.add(currentUser.uid);
      currentUser.following.add(user.uid);
    }

    user = user.copyWith(followers: user.followers);
    currentUser = currentUser.copyWith(
      following: currentUser.following,
    );

    final res = await _userAPI.followUser(user);
    res.fold((l) => showSnackBar(context, l.message), (r) async {
      final res2 = await _userAPI.addToFollowing(currentUser);
      res2.fold((l) => showSnackBar(context, l.message), (r) {
        _notificationController.createNotification(
          text: '${currentUser.name} followed you!',
          postId: '',
          notificationType: NotificationType.follow,
          uid: user.uid,
        );
      });
    });
  }

  Future<List<UserModel>> getUserFollowList({
    required String userId,
    required String type,
  }) async {
    print('DEBUG: getUserFollowList method called with userId: $userId, type: $type');
    try {
      print('DEBUG: Fetching user data for userId: $userId');
      final userData = await _userAPI.getUserData(userId);
      print('DEBUG: User data fetched successfully');
      
      final user = UserModel.fromMap(userData.data);
      print('DEBUG: User model created, name: ${user.name}');
      
      final List<String> userIds = type == 'followers' ? user.followers : user.following;
      print('DEBUG: Found ${userIds.length} ${type} IDs: $userIds');
      
      List<UserModel> userList = [];
      for (final id in userIds) {
        print('DEBUG: Fetching data for ${type} with ID: $id');
        try {
          final userDoc = await _userAPI.getUserData(id);
          print('DEBUG: Successfully fetched data for user with ID: $id');
          final userModel = UserModel.fromMap(userDoc.data);
          userList.add(userModel);
        } catch (e) {
          print('DEBUG: Error fetching data for user $id: $e');
          // Skip this user and continue with others
          continue;
        }
      }
      
      print('DEBUG: Returning ${userList.length} users');
      return userList;
    } catch (e, stackTrace) {
      print('DEBUG: Error in getUserFollowList: $e');
      print('DEBUG: Stack trace: $stackTrace');
      // Return empty list instead of throwing to avoid provider errors
      return [];
    }
  }

  // Add this method to get recommended users based on interests
  Future<List<UserModel>> getRecommendedUsers() async {
    try {
      final currentUser = await _ref.read(currentUserDetailsProvider.future);
      if (currentUser == null) {
        return [];
      }
      
      final recommendationService = _ref.read(recommendationServiceProvider);
      
      // Get user's liked tweets to infer interests
      final tweetController = _ref.read(tweetControllerProvider.notifier);
      final userLikedTweets = await tweetController.getUserLikedTweets(currentUser.uid);
      
      // Infer interests from liked tweets
      final interests = recommendationService.inferUserInterests(currentUser, userLikedTweets);
      
      // Get recommended users
      return recommendationService.getRecommendedUsersToFollow(
        currentUser, 
        interests,
        limit: 20,
      );
    } catch (e) {
      print('Error getting recommended users: $e');
      return [];
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    final document = await _userAPI.getUserData(uid);
    if (document != null) {
      return UserModel.fromMap(document.data);
    }
    return null;
  }

  Future<String?> getAffiliatedUserProfilePic(String affiliatedUserId) async {
    if (affiliatedUserId.isEmpty) return null;
    
    final userData = await getUserData(affiliatedUserId);
    return userData?.profilePic;
  }
}
