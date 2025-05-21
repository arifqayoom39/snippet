import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:snippet/constants/constants.dart';
import 'package:snippet/features/tweet/views/create_tweet_view.dart';
import 'package:snippet/features/user_profile/view/user_profile_view.dart';
import 'package:snippet/theme/pallete.dart';
import 'package:snippet/features/auth/controller/auth_controller.dart';
import 'package:snippet/features/bookmark/view/bookmarks_view.dart';

class HomeView extends ConsumerStatefulWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const HomeView(),
      );
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  int _page = 0;
  final appBar = UIConstants.appBar();

  // Hold the UserProfileView lazily
  Widget? userProfileView;

  @override
  void initState() {
    super.initState();
    // Theme initialization is now handled in main.dart
  }

  void onPageChange(int index) {
    if (index == 2) {
      onCreatetweet();
    } else {
      setState(() {
        _page = index;
        if (index == 4 && userProfileView == null) {
          // Initialize UserProfileView only when the profile tab is selected
          final currentUser = ref.read(currentUserDetailsProvider).value;
          if (currentUser != null) {
            userProfileView = UserProfileView(userModel: currentUser);
          }
        }
      });
    }
  }

  onCreatetweet() {
    Navigator.push(context, CreatetweetScreen.route());
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final currentUser = ref.watch(currentUserDetailsProvider).value;
    
    return Scaffold(
      appBar: _page == 0 ? appBar : null,
      body: IndexedStack(
        index: _page,
        children: [
          UIConstants.bottomTabBarPages[0], // Home
          UIConstants.bottomTabBarPages[1], // Search
          Container(), // Empty container for the middle tab (Create tweet)
          UIConstants.bottomTabBarPages[2], // Notifications
          userProfileView ?? Container(), // Profile, initialized lazily
        ],
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: _page,
        onTap: onPageChange,
        backgroundColor: Pallete.backgroundColor,
        items: [
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              _page == 0 
                ? AssetsConstants.homeFilledIcon 
                : AssetsConstants.homeOutlinedIcon,
              colorFilter: ColorFilter.mode(Pallete.iconColor, BlendMode.srcIn),
            ),
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              AssetsConstants.searchIcon,
              colorFilter: ColorFilter.mode(Pallete.iconColor, BlendMode.srcIn),
            ),
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              AssetsConstants.addIcon,
              colorFilter: ColorFilter.mode(Pallete.iconColor, BlendMode.srcIn),
              height: 35, // Maintain the larger size for emphasis
            ),
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              _page == 3 
                ? AssetsConstants.notifFilledIcon 
                : AssetsConstants.notifOutlinedIcon,
              colorFilter: ColorFilter.mode(Pallete.iconColor, BlendMode.srcIn),
            ),
          ),
          BottomNavigationBarItem(
            icon: currentUser != null && currentUser.profilePic.isNotEmpty
                ? Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: _page == 4 
                          ? Border.all(color: Pallete.blueColor, width: 2) 
                          : null,
                    ),
                    child: CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(currentUser.profilePic),
                      radius: 14,
                      backgroundColor: Pallete.backgroundColor,
                    ),
                  )
                : SvgPicture.asset(
                    _page == 4 
                      ? AssetsConstants.profileFilledIcon 
                      : AssetsConstants.profileOutlinedIcon,
                    colorFilter: ColorFilter.mode(Pallete.iconColor, BlendMode.srcIn),
                  ),
          ),
        ],
      ),
      // Add a drawer for easier access to user profile and settings
      drawer: currentUser != null ? _buildDrawer(currentUser) : null,
    );
  }
  
  Widget _buildDrawer(user) {
    return Drawer(
      backgroundColor: Pallete.backgroundColor,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Pallete.backgroundColor,
            ),
            accountName: Text(
              user.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Pallete.textColor,
              ),
            ),
            accountEmail: Text(
              '@${user.name}',
              style: TextStyle(
                color: Pallete.greyColor,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(user.profilePic),
              radius: 30,
            ),
          ),
          ListTile(
            leading: Icon(Icons.person, color: Pallete.iconColor),
            title: Text('Profile', style: TextStyle(color: Pallete.textColor)),
            onTap: () {
              Navigator.pop(context);
              onPageChange(4);
            },
          ),
          // Add bookmarks option
          ListTile(
            leading: Icon(Icons.bookmark, color: Pallete.iconColor),
            title: Text('Bookmarks', style: TextStyle(color: Pallete.textColor)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, BookmarksView.route());
            },
          ),
          ListTile(
            leading: Icon(Icons.settings, color: Pallete.iconColor),
            title: Text('Settings', style: TextStyle(color: Pallete.textColor)),
            onTap: () {
              Navigator.pop(context);
              // Handle settings navigation
            },
          ),
          const Spacer(),
          ListTile(
            leading: Icon(Icons.logout, color: Pallete.iconColor),
            title: Text('Log out', style: TextStyle(color: Pallete.textColor)),
            onTap: () {
              Navigator.pop(context);
              ref.read(authControllerProvider.notifier).logout(context);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
