import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:snippet/common/error_page.dart';
import 'package:snippet/common/loading_page.dart';
import 'package:snippet/constants/constants.dart';
import 'package:snippet/features/auth/controller/auth_controller.dart';
import 'package:snippet/features/tweet/widgets/tweet_card.dart';
import 'package:snippet/features/user_profile/controller/user_profile_controller.dart';
import 'package:snippet/features/user_profile/view/edit_profile_view.dart';
import 'package:snippet/features/user_profile/view/follow_list_view.dart';
import 'package:snippet/features/user_profile/view/user_profile_view.dart';
import 'package:snippet/features/user_profile/widget/follow_count.dart';
import 'package:snippet/features/user_profile/widget/profile_menu.dart';
import 'package:snippet/models/user_model.dart';
import 'package:snippet/theme/pallete.dart';

class UserProfile extends ConsumerWidget {
  final UserModel user;
  final Widget? header; // Add header parameter

  const UserProfile({
    super.key,
    required this.user,
    this.header, // Make it optional
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserDetailsProvider).value;
    final isDarkMode = ref.watch(themeProvider);

    return currentUser == null
        ? const Loader()
        : RefreshIndicator(
            color: Pallete.blueColor,
            onRefresh: () async {
              ref.refresh(getUsertweetsProvider(user.uid));
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildProfileHeader(context, ref, currentUser),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
                    child: Text(
                      'Tweets',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Pallete.textColor,
                      ),
                    ),
                  ),
                ),
                _buildTweetsList(ref),
              ],
            ),
          );
  }

  Widget _buildProfileHeader(BuildContext context, WidgetRef ref, UserModel currentUser) {
    final isDarkMode = ref.watch(themeProvider);
    final isMyProfile = currentUser.uid == user.uid;

    void _showAffiliationModal() {
      if (user.affiliatedUserId.isNotEmpty) {
        ref.read(userProfileControllerProvider.notifier)
           .getUserData(user.affiliatedUserId)
           .then((affiliatedUser) {
              if (affiliatedUser != null) {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Pallete.backgroundColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (context) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pull indicator
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 12),
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Pallete.greyColor.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      
                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Connected Account',
                            style: TextStyle(
                              color: Pallete.textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      
                      // Subtitle with detail
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 4.0, bottom: 10.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: Pallete.greyColor,
                                fontSize: 13,
                              ),
                              children: [
                                TextSpan(
                                  text: '@${user.username.isNotEmpty ? user.username : user.name}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const TextSpan(
                                  text: ' has officially connected their account with this account',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Divider
                      Divider(
                        color: Pallete.greyColor.withOpacity(0.2),
                        height: 1,
                      ),
                      
                      // User item - full width clickable
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, UserProfileView.route(affiliatedUser));
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              // Profile image
                              CircleAvatar(
                                backgroundImage: CachedNetworkImageProvider(affiliatedUser.profilePic),
                                radius: 20,
                              ),
                              const SizedBox(width: 12),
                              
                              // Name and username
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          affiliatedUser.name,
                                          style: TextStyle(
                                            color: Pallete.textColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (affiliatedUser.istweetBlue)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 2.0),
                                            child: SvgPicture.asset(
                                              AssetsConstants.verifiedIcon,
                                              width: 15,
                                              height: 15,
                                            ),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      '@${affiliatedUser.username.isNotEmpty ? affiliatedUser.username : affiliatedUser.name}',
                                      style: TextStyle(
                                        color: Pallete.greyColor,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Subtle chevron
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Pallete.greyColor.withOpacity(0.7),
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Footer text with timestamp
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Account connected · Are member or managing this account',
                          style: TextStyle(
                            color: Pallete.greyColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
           });
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner image with optional menu
        Stack(
          children: [
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Pallete.blueColor, // Fallback color
                image: user.bannerPic.isNotEmpty
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(user.bannerPic),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
            
            // Three dots menu for logout (only for current user)
            if (isMyProfile)
              Positioned(
                top: 40,
                right: 10,
                child: GestureDetector(
                  onTap: () {
                    ProfileMenu.showLogoutMenu(context, ref);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Pallete.backgroundColor.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.more_vert,
                      color: Pallete.iconColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
          ],
        ),
        
        // Profile photo + buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Profile photo with overlay
              Container(
                transform: Matrix4.translationValues(0, -40, 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Pallete.backgroundColor,
                    width: 4,
                  ),
                ),
                child: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(user.profilePic),
                  radius: 40,
                ),
              ),
              
              // Button
              _buildProfileButton(context, ref, currentUser),
            ],
          ),
        ),
        
        // Name, handle, and verified badge
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Pallete.textColor,
                    ),
                  ),
                  if (user.istweetBlue)
                    GestureDetector(
                      onTap: isMyProfile ? () {
                        ProfileMenu.showVerificationMenu(context, ref, user);
                      } : null,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: SvgPicture.asset(
                          AssetsConstants.verifiedIcon,
                          width: 18,
                          height: 18,
                        ),
                      ),
                    ),
                  if (user.affiliatedUserId.isNotEmpty)
                    GestureDetector(
                      onTap: _showAffiliationModal,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: FutureBuilder<String?>(
                          future: ref.read(userProfileControllerProvider.notifier)
                                    .getAffiliatedUserProfilePic(user.affiliatedUserId),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              return CircleAvatar(
                                backgroundImage: CachedNetworkImageProvider(snapshot.data!),
                                radius: 7, // Smaller radius (was 9)
                              );
                            }
                            return const SizedBox(
                              width: 14, // Smaller width (was 18)
                              height: 14, // Smaller height (was 18)
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5, // Thinner stroke (was 2)
                                color: Pallete.greyColor,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                '@${user.username.isNotEmpty ? user.username : user.name}',
                style: const TextStyle(
                  fontSize: 15,
                  color: Pallete.greyColor,
                ),
              ),
            ],
          ),
        ),
        
        // Bio
        if (user.bio.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0),
            child: Text(
              user.bio,
              style: TextStyle(
                fontSize: 15,
                color: Pallete.textColor,
              ),
            ),
          ),
        
        // Joined date
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 12.0, bottom: 4.0),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Pallete.greyColor,
              ),
              const SizedBox(width: 4),
              Text(
                'Joined snippet',
                style: TextStyle(
                  color: Pallete.greyColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        
        // Following/Followers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    FollowListView.route(
                      user: user,
                      type: FollowListType.following,
                    ),
                  );
                },
                child: Text(
                  '${user.following.length} Following',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    FollowListView.route(
                      user: user,
                      type: FollowListType.followers,
                    ),
                  );
                },
                child: Text(
                  '${user.followers.length} Followers',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTweetsList(WidgetRef ref) {
    return ref.watch(getUsertweetsProvider(user.uid)).when(
          data: (tweets) {
            if (tweets.isEmpty) {
              return SliverToBoxAdapter(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.post_add,
                        size: 40,
                        color: Pallete.greyColor,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '@${user.username.isNotEmpty ? user.username : user.name} hasn\'t tweeted yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Pallete.greyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tweet = tweets[index];
                  return tweetCard(tweet: tweet);
                },
                childCount: tweets.length,
              ),
            );
          },
          error: (error, st) => SliverToBoxAdapter(
            child: ErrorText(
              error: error.toString(),
            ),
          ),
          loading: () => const SliverToBoxAdapter(
            child: Loader(),
          ),
        );
  }

  Widget _buildProfileButton(BuildContext context, WidgetRef ref, UserModel currentUser) {
    final bool isMyProfile = currentUser.uid == user.uid;
    final bool isFollowing = currentUser.following.contains(user.uid);
    final isDarkMode = ref.watch(themeProvider);
    
    return Container(
      margin: const EdgeInsets.only(top: 6.0),
      child: OutlinedButton(
        onPressed: () {
          if (isMyProfile) {
            Navigator.push(context, EditProfileView.route());
          } else {
            ref
                .read(userProfileControllerProvider.notifier)
                .followUser(
                  user: user,
                  context: context,
                  currentUser: currentUser,
                );
          }
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: isMyProfile 
              ? Pallete.backgroundColor 
              : isFollowing ? Pallete.backgroundColor : Pallete.whiteColor,
          side: BorderSide(
            color: isMyProfile 
                ? Pallete.greyColor 
                : isFollowing ? Pallete.greyColor : Colors.transparent,
            width: 1.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(
          isMyProfile
              ? 'Edit profile'
              : isFollowing
                  ? 'Following'
                  : 'Follow',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isMyProfile || isFollowing 
                ? Pallete.textColor 
                : isDarkMode ? Pallete.backgroundColorDark : Pallete.textColorLight,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

