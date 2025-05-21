import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:snippet/constants/assets_constants.dart';
import 'package:snippet/features/user_profile/view/user_profile_view.dart';
import 'package:snippet/models/user_model.dart';
import 'package:snippet/theme/pallete.dart';

class SearchTile extends ConsumerWidget {
  final UserModel userModel;
  final bool showRecommendationReason;
  
  const SearchTile({
    super.key,
    required this.userModel,
    this.showRecommendationReason = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Explicitly watch the theme to rebuild when it changes
    final isDarkMode = ref.watch(themeProvider);
    
    // Extract recommendation reason if present
    String? recommendationReason;
    String displayBio = userModel.bio;
    
    if (showRecommendationReason && userModel.bio.contains('\n\n')) {
      final parts = userModel.bio.split('\n\n');
      displayBio = parts.first;
      if (parts.length > 1) {
        recommendationReason = parts.last;
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: Pallete.backgroundColor,
          child: ListTile(
            tileColor: Pallete.backgroundColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            onTap: () {
              Navigator.push(
                context,
                UserProfileView.route(userModel),
              );
            },
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(userModel.profilePic),
              radius: 24,
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    userModel.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Pallete.textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (userModel.istweetBlue)
                  Padding(
                    padding: const EdgeInsets.only(left: 2.0),
                    child: SvgPicture.asset(
                      AssetsConstants.verifiedIcon,
                      width: 14,
                      height: 14,
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              '@${userModel.name}',
              style: TextStyle(
                fontSize: 14,
                color: Pallete.greyColor,
              ),
            ),
            trailing: Icon(
              Icons.keyboard_arrow_right,
              size: 18,
              color: Pallete.greyColor,
            ),
          ),
        ),
        
        // Show recommendation reason if available
        if (recommendationReason != null)
          Padding(
            padding: const EdgeInsets.only(left: 60.0, right: 16.0, bottom: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Pallete.blueColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                recommendationReason,
                style: TextStyle(
                  fontSize: 12,
                  color: Pallete.blueColor,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }
}
