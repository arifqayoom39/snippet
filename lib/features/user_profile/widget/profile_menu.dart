import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/constants/constants.dart';
import 'package:snippet/features/auth/controller/auth_controller.dart';
import 'package:snippet/features/bookmark/view/bookmarks_view.dart';
import 'package:snippet/features/user_profile/widget/twitter_blue_verification_page.dart';
import 'package:snippet/features/user_profile/widget/change_password_page.dart';
import 'package:snippet/features/user_profile/widget/upi_payment_page.dart';
import 'package:snippet/models/user_model.dart';
import 'package:snippet/theme/pallete.dart';

class ProfileMenu {
  static void showLogoutMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Pallete.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: 8.0),
                decoration: BoxDecoration(
                  color: Pallete.greyColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Consumer(
                builder: (context, ref, child) {
                  final isDarkMode = ref.watch(themeProvider);
                  return ListTile(
                    leading: Icon(
                      isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      color: Pallete.iconColor
                    ),
                    title: Text(
                      isDarkMode ? 'Light Mode' : 'Dark Mode',
                      style: TextStyle(
                        color: Pallete.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      ref.read(themeProvider.notifier).toggleTheme();
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.password, color: Pallete.iconColor),
                title: Text(
                  'Change Password',
                  style: TextStyle(
                    color: Pallete.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToChangePassword(context, ref);
                },
              ),
              ListTile(
                leading: Icon(Icons.qr_code, color: Pallete.iconColor),
                title: Text(
                  'UPI Payments',
                  style: TextStyle(
                    color: Pallete.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToUpiPayment(context, ref);
                },
              ),
              ListTile(
                leading: Icon(Icons.bookmark, color: Pallete.iconColor),
                title: Text(
                  'Bookmarks',
                  style: TextStyle(
                    color: Pallete.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToBookmarks(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.verified, color: Pallete.blueColor),
                title: Text(
                  'Apply for verification',
                  style: TextStyle(
                    color: Pallete.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showVerificationDialog(context, ref);
                },
              ),
              ListTile(
                leading: Icon(Icons.logout, color: Pallete.iconColor),
                title: Text(
                  'Log out',
                  style: TextStyle(
                    color: Pallete.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(authControllerProvider.notifier).logout(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static void _showVerificationDialog(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SnippetBlueVerificationPage(ref: ref)),
    );
  }
  
  static void _navigateToChangePassword(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChangePasswordPage(ref: ref)),
    );
  }
  
  static void _navigateToUpiPayment(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UpiPaymentPage(ref: ref)),
    );
  }
  
  static void _navigateToBookmarks(BuildContext context) {
    Navigator.push(
      context,
      BookmarksView.route(),
    );
  }

  static void showVerificationMenu(BuildContext context, WidgetRef ref, UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Pallete.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: 8.0),
                decoration: BoxDecoration(
                  color: Pallete.greyColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.verified, color: Pallete.blueColor),
                title: Text(
                  user.istweetBlue 
                      ? 'Cancel verification' 
                      : 'Apply for verification',
                  style: TextStyle(
                    color: Pallete.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showVerificationDialog(context, ref);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
