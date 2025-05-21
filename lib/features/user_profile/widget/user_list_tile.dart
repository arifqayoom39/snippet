import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:snippet/constants/assets_constants.dart';
import 'package:snippet/features/auth/controller/auth_controller.dart';
import 'package:snippet/features/user_profile/controller/user_profile_controller.dart';
import 'package:snippet/features/user_profile/view/user_profile_view.dart';
import 'package:snippet/models/user_model.dart';
import 'package:snippet/theme/pallete.dart';

class UserListTile extends ConsumerWidget {
  final UserModel user;

  const UserListTile({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserDetailsProvider).value;

    void _showAffiliationModal() {
      if (user.affiliatedUserId.isNotEmpty) {
        ref.read(userProfileControllerProvider.notifier)
           .getUserData(user.affiliatedUserId)
           .then((affiliatedUser) {
              if (affiliatedUser != null) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Pallete.backgroundColor,
                    title: Text(
                      'Account Affiliation',
                      style: TextStyle(
                        color: Pallete.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'This account is affiliated with:',
                          style: TextStyle(color: Pallete.textColor),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(affiliatedUser.profilePic),
                              radius: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    affiliatedUser.name,
                                    style: TextStyle(
                                      color: Pallete.textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '@${affiliatedUser.username.isNotEmpty ? affiliatedUser.username : affiliatedUser.name}',
                                    style: TextStyle(
                                      color: Pallete.greyColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(context, UserProfileView.route(affiliatedUser));
                        },
                        child: Text(
                          'View Profile',
                          style: TextStyle(color: Pallete.blueColor),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Close',
                          style: TextStyle(color: Pallete.blueColor),
                        ),
                      ),
                    ],
                  ),
                );
              }
           });
      }
    }

    return currentUser == null
        ? const SizedBox()
        : GestureDetector(
            onTap: () {
              Navigator.push(context, UserProfileView.route(user));
            },
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(user.profilePic),
                radius: 25,
              ),
              title: Row(
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (user.istweetBlue)
                    Padding(
                      padding: const EdgeInsets.only(left: 2.0),
                      child: SvgPicture.asset(
                        AssetsConstants.verifiedIcon,
                        width: 14,
                        height: 14,
                      ),
                    ),
                  if (user.affiliatedUserId.isNotEmpty)
                    GestureDetector(
                      onTap: _showAffiliationModal,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 2.0),
                        child: FutureBuilder<String?>(
                          future: ref.read(userProfileControllerProvider.notifier)
                                    .getAffiliatedUserProfilePic(user.affiliatedUserId),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              return CircleAvatar(
                                backgroundImage: CachedNetworkImageProvider(snapshot.data!),
                                radius: 5, // Smaller radius (was 7)
                              );
                            }
                            return const SizedBox(width: 5, height: 10); // Smaller size
                          },
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Text(
                '@${user.username.isNotEmpty ? user.username : user.name}',
                style: TextStyle(
                  color: Pallete.greyColor,
                ),
              ),
              trailing: currentUser.uid != user.uid
                  ? OutlinedButton(
                      onPressed: () {
                        ref.read(userProfileControllerProvider.notifier).followUser(
                              user: user,
                              context: context,
                              currentUser: currentUser,
                            );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: currentUser.following.contains(user.uid)
                              ? Pallete.greyColor
                              : Pallete.blueColor,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                      ),
                      child: Text(
                        currentUser.following.contains(user.uid) ? 'Unfollow' : 'Follow',
                        style: TextStyle(
                          color: currentUser.following.contains(user.uid)
                              ? Pallete.textColor
                              : Pallete.blueColor,
                        ),
                      ),
                    )
                  : null,
            ),
          );
  }
}
