import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:snippet/common/loading_page.dart';
import 'package:snippet/constants/assets_constants.dart';
import 'package:snippet/features/auth/controller/auth_controller.dart';
import 'package:snippet/features/explore/controller/explore_controller.dart';
import 'package:snippet/features/user_profile/controller/user_profile_controller.dart';
import 'package:snippet/features/user_profile/view/user_profile_view.dart';
import 'package:snippet/models/user_model.dart';
import 'package:snippet/theme/pallete.dart';

// Replace the current provider with this one that uses our new algorithm
final filteredSuggestedUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  // Use our recommendation algorithm instead of random users
  final recommendedUsers = await ref.watch(getRecommendedUsersProvider.future);
  
  // Fall back to regular suggestions if recommendations are empty
  if (recommendedUsers.isEmpty) {
    final suggestedUsers = await ref.watch(suggestedUsersProvider.future);
    final currentUser = ref.watch(currentUserDetailsProvider).value;

    if (currentUser == null) return suggestedUsers;
    return suggestedUsers.where((user) => user.uid != currentUser.uid).toList();
  }
  
  print('DEBUG: Showing ${recommendedUsers.length} algorithm-based user recommendations');
  return recommendedUsers;
});

class WhoToFollowSection extends ConsumerWidget {
  const WhoToFollowSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestedUsers = ref.watch(filteredSuggestedUsersProvider);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Pallete.backgroundColor,
        border: Border(
          top: BorderSide(color: Pallete.greyColor.withOpacity(0.3), width: 0.5),
          bottom: BorderSide(color: Pallete.greyColor.withOpacity(0.3), width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Text(
                  'Who to follow',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Pallete.textColor,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.auto_awesome, color: Pallete.blueColor, size: 16),
                const Spacer(),
                Text(
                  'Based on your interests',
                  style: TextStyle(
                    fontSize: 12,
                    color: Pallete.greyColor,
                  ),
                ),
              ],
            ),
          ),
          suggestedUsers.when(
            data: (users) {
              if (users.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No suggestions available',
                    style: TextStyle(color: Pallete.greyColor),
                  ),
                );
              }
              
              return SizedBox(
                height: 220, // Increased height for banner
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return UserFollowCard(user: user);
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 220,
              child: Center(child: Loader()),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error loading suggestions',
                style: TextStyle(color: Pallete.redColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UserFollowCard extends ConsumerWidget {
  final UserModel user;
  
  const UserFollowCard({
    Key? key,
    required this.user,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserDetailsProvider).value;
    final isFollowing = currentUser != null && 
                         currentUser.following.contains(user.uid);
    
    // Extract recommendation reason if present (we added it to the bio field)
    String? recommendationReason;
    String displayBio = user.bio;
    
    if (user.bio.contains('\n\n')) {
      final parts = user.bio.split('\n\n');
      displayBio = parts.first;
      if (parts.length > 1) {
        recommendationReason = parts.last;
      }
    }
    
    return Container(
      width: 160,
      height: 202, // Exact match to available constraints height
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Pallete.backgroundColor,
        border: Border.all(color: Pallete.greyColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, UserProfileView.route(user)),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner image at top with reduced height
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Banner background
                Container(
                  height: 50, // Reduced from 60
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Pallete.blueColor.withOpacity(0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    image: user.bannerPic.isNotEmpty
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(user.bannerPic),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                ),
                
                // Profile image positioned to overlap
                Positioned(
                  bottom: -18, // Reduced from -20
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Pallete.backgroundColor,
                          width: 2, // Reduced from 3
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundImage: CachedNetworkImageProvider(user.profilePic),
                        radius: 20, // Reduced from 22
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // User info with reduced padding
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 22, 10, 0), // Reduced from 25 to 22
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13, // Reduced from 14
                            color: Pallete.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (user.istweetBlue)
                        Padding(
                          padding: const EdgeInsets.only(left: 2.0),
                          child: SvgPicture.asset(
                            AssetsConstants.verifiedIcon,
                            width: 11, // Reduced from 12
                            height: 11, // Reduced from 12
                          ),
                        ),
                    ],
                  ),
                  Text(
                    '@${user.name}',
                    style: TextStyle(
                      fontSize: 11, // Reduced from 12
                      color: Pallete.greyColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Bio section with smaller fixed height
            SizedBox(
              height: 32, // Reduced from 35
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Center(
                  child: Text(
                    displayBio,
                    style: TextStyle(
                      fontSize: 11, // Reduced from 12
                      color: Pallete.textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            
            // Add recommendation reason if available (with smaller fixed height)
            if (recommendationReason != null)
              SizedBox(
                height: 14, // Reduced from 16
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), // Reduced padding
                      decoration: BoxDecoration(
                        color: Pallete.blueColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        recommendationReason,
                        style: TextStyle(
                          fontSize: 9, // Reduced from 10
                          color: Pallete.blueColor,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Spacer to push the button to the bottom
            const Spacer(),
            
            // Follow/Unfollow button with fixed position at bottom
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 6.0, top: 2.0), // Further reduced padding
              child: SizedBox(
                width: double.infinity,
                height: 28, // Reduced from 30
                child: OutlinedButton(
                  onPressed: () {
                    if (currentUser != null) {
                      ref.read(userProfileControllerProvider.notifier).followUser(
                        user: user,
                        context: context,
                        currentUser: currentUser,
                      );
                    }
                  },
                  style: isFollowing 
                    ? OutlinedButton.styleFrom(
                        foregroundColor: Pallete.textColor,
                        side: BorderSide(color: Pallete.greyColor.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 0),
                      )
                    : ElevatedButton.styleFrom(
                        backgroundColor: Pallete.textColor,
                        foregroundColor: Pallete.backgroundColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                  child: Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12, // Reduced from 13
                      color: isFollowing ? Pallete.textColor : Pallete.backgroundColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
