import 'package:appwrite/models.dart' as model;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/apis/auth_api.dart';
import 'package:snippet/apis/user_api.dart';
import 'package:snippet/core/utils.dart';
import 'package:snippet/features/auth/view/login_view.dart';
import 'package:snippet/features/auth/view/signup_view.dart';
import 'package:snippet/features/auth/view/username_selection_view.dart';
import 'package:snippet/features/home/view/home_view.dart';
import 'package:snippet/models/user_model.dart';
import 'package:snippet/services/push_notification_service.dart';

final authControllerProvider = StateNotifierProvider<AuthController, bool>((ref) {
  return AuthController(
    authAPI: ref.watch(authAPIProvider),
    userAPI: ref.watch(userAPIProvider),
    pushNotificationService: ref.watch(pushNotificationServiceProvider),
  );
});

final currentUserAccountProvider = FutureProvider((ref) async {
  final authController = ref.watch(authControllerProvider.notifier);
  return authController.currentUser();
});

final currentUserDetailsProvider = FutureProvider((ref) async {
  final authController = ref.watch(authControllerProvider.notifier);
  final current = await authController.currentUser();
  if (current == null) {
    return null;
  } else {
    final currentUserId = current.$id;
    final userDetails = ref.watch(userDetailsProvider(currentUserId));
    return userDetails.value;
  }
});

final userDetailsProvider = FutureProvider.family((ref, String uid) {
  final authController = ref.watch(authControllerProvider.notifier);
  return authController.getUserData(uid);
});

class AuthController extends StateNotifier<bool> {
  final AuthAPI _authAPI;
  final UserAPI _userAPI;
  final PushNotificationService _pushNotificationService;

  AuthController({
    required AuthAPI authAPI,
    required UserAPI userAPI,
    required PushNotificationService pushNotificationService,
  })  : _authAPI = authAPI,
        _userAPI = userAPI,
        _pushNotificationService = pushNotificationService,
        super(false);

  // Fetch the current user
  Future<model.User?> currentUser() => _authAPI.currentUserAccount();

  // Check if username is available
  Future<bool> checkUsernameAvailability(String username) async {
    try {
      final users = await _userAPI.searchUserByUsername(username);
      return users.isEmpty;
    } catch (e) {
      print('Error checking username availability: $e');
      return false;
    }
  }

  // Update user data method
  void updateUserData({
    required UserModel userModel,
    required BuildContext context,
    void Function()? onSuccess,
  }) async {
    state = true;
    final res = await _userAPI.updateUserData(userModel);
    state = false;
    res.fold(
      (l) => showSnackBar(context, l.message),
      (r) {
        if (onSuccess != null) {
          onSuccess();
        }
      },
    );
  }

  // Sign up a new user
  void signUp({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    state = true;
    final res = await _authAPI.signUp(
      email: email,
      password: password,
    );
    state = false;
    res.fold(
      (l) => showSnackBar(context, l.message),
      (r) async {
        // Get the OneSignal Player ID
        final String? playerId = await _pushNotificationService.getPlayerId();

        UserModel userModel = UserModel(
          email: email,
          name: getNameFromEmail(email),
          username: '', // Empty username initially
          followers: const [],
          following: const [],
          profilePic: '',
          bannerPic: '',
          uid: r.$id,
          bio: '',
          istweetBlue: false,
          oneSignalId: playerId ?? '',
        );
        final res2 = await _userAPI.saveUserData(userModel);
        res2.fold(
          (l) => showSnackBar(context, l.message), 
          (r) {
            // Navigate to username selection screen instead of login
            Navigator.push(
              context, 
              UsernameSelectionView.route(userModel: userModel)
            );
          }
        );
      },
    );
  }

  // Log in an existing user
  void login({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    state = true;
    final res = await _authAPI.login(
      email: email,
      password: password,
    );
    state = false;
    res.fold(
      (l) => showSnackBar(context, l.message),
      (r) async {
        try {
          // After successful login, get the current user
          final user = await _authAPI.currentUserAccount();
          if (user != null) {
            // Get latest OneSignal Player ID
            final String? newPlayerId = await _pushNotificationService.getPlayerId();
            
            // Get the user data from database
            final userData = await getUserData(user.$id);
            
            // Check if OneSignal ID needs updating
            if (newPlayerId != null && newPlayerId.isNotEmpty) {
              if (userData.oneSignalId != newPlayerId) {
                print('Updating OneSignal ID: ${userData.oneSignalId} -> $newPlayerId');
                
                // Create updated user model with new OneSignal ID
                final updatedUser = userData.copyWith(oneSignalId: newPlayerId);
                
                // Update user data in database with new OneSignal ID
                final updateResult = await _userAPI.updateUserData(updatedUser);
                
                updateResult.fold(
                  (failure) => print('Failed to update OneSignal ID: ${failure.message}'),
                  (_) => print('Successfully updated OneSignal ID in database')
                );
              } else {
                print('OneSignal ID unchanged: ${userData.oneSignalId}');
              }
              
              // Associate the Appwrite user ID with OneSignal regardless
              await _pushNotificationService.setExternalUserId(user.$id);
            } else if (userData.oneSignalId.isEmpty) {
              // If we couldn't get a new player ID but the user doesn't have one stored,
              // we'll try again later when the app has proper permissions
              print('No OneSignal ID available yet. Will update later when available.');
            }
          }
          
          Navigator.push(context, HomeView.route());
        } catch (e) {
          print('Error during post-login operations: $e');
          // Still navigate to HomeView even if OneSignal operations fail
          Navigator.push(context, HomeView.route());
        }
      },
    );
  }

  // Change password method
  void changePassword({
    required String currentPassword,
    required String newPassword,
    required BuildContext context,
  }) async {
    state = true;
    final res = await _authAPI.updatePassword(
      oldPassword: currentPassword,
      newPassword: newPassword,
    );
    state = false;
    res.fold(
      (l) => showSnackBar(context, l.message),
      (r) {
        showSnackBar(context, 'Password changed successfully');
        Navigator.pop(context);
      },
    );
  }

  // Fetch user data based on UID
  Future<UserModel> getUserData(String uid) async {
    final document = await _userAPI.getUserData(uid);
    final updatedUser = UserModel.fromMap(document.data);
    return updatedUser;
  }

  // Log out the current user
  void logout(BuildContext context) async {
    // Clear OneSignal external user ID before logging out
    await _pushNotificationService.removeExternalUserId();
    
    final res = await _authAPI.logout();
    res.fold((l) => null, (r) {
      Navigator.pushAndRemoveUntil(
        context,
        SignUpView.route(),
        (route) => false,
      );
    });
  }
}
