import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/common/error_page.dart';
import 'package:snippet/common/loading_page.dart';
import 'package:snippet/constants/constants.dart';
import 'package:snippet/features/auth/controller/auth_controller.dart';
import 'package:snippet/features/user_profile/controller/user_profile_controller.dart';
import 'package:snippet/features/user_profile/widget/user_profile.dart';
import 'package:snippet/models/user_model.dart';
import 'package:snippet/theme/pallete.dart';

class UserProfileView extends ConsumerWidget {
  static route(UserModel userModel) => MaterialPageRoute(
        builder: (context) => UserProfileView(
          userModel: userModel,
        ),
      );
  final UserModel userModel;
  const UserProfileView({
    super.key,
    required this.userModel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    UserModel copyOfUser = userModel;
    final bool canGoBack = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      body: Stack(
        children: [
          ref.watch(getLatestUserProfileDataProvider).when(
                data: (data) {
                  if (data.events.contains(
                    'databases.*.collections.${AppwriteConstants.usersCollection}.documents.${copyOfUser.uid}.update',
                  )) {
                    copyOfUser = UserModel.fromMap(data.payload);
                  }
                  return UserProfile(
                    user: copyOfUser,
                    header: null,
                  );
                },
                error: (error, st) => ErrorText(
                  error: error.toString(),
                ),
                loading: () {
                  return UserProfile(
                    user: copyOfUser,
                    header: null,
                  );
                },
              ),
          if (canGoBack)
            Positioned(
              top: 40,
              left: 10,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Pallete.backgroundColor.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Pallete.iconColor,
                    size: 24,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
