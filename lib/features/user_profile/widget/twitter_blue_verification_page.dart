import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/apis/user_api.dart';
import 'package:snippet/constants/appwrite_constants.dart';
import 'package:snippet/theme/pallete.dart';
import 'package:snippet/models/user_model.dart';
import 'package:snippet/features/auth/controller/auth_controller.dart';
import 'package:snippet/features/user_profile/controller/user_profile_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SnippetBlueVerificationPage extends StatefulWidget {
  final WidgetRef ref;

  const SnippetBlueVerificationPage({Key? key, required this.ref}) : super(key: key);

  @override
  State<SnippetBlueVerificationPage> createState() => _SnippetBlueVerificationPageState();
}

class _SnippetBlueVerificationPageState extends State<SnippetBlueVerificationPage> {
  int _selectedPlan = 1; // 0: Monthly, 1: Annual
  final ScrollController _scrollController = ScrollController();
  bool _showElevation = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 0 && !_showElevation) {
        setState(() => _showElevation = true);
      } else if (_scrollController.offset <= 0 && _showElevation) {
        setState(() => _showElevation = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      appBar: AppBar(
        backgroundColor: Pallete.backgroundColor,
        elevation: _showElevation ? 1 : 0,
        centerTitle: true,
        title: Text(
          'Snippet Blue',
          style: TextStyle(
            color: Pallete.blueColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Pallete.iconColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        controller: _scrollController,
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(),
          _buildPlansSection(),
          _buildFeaturesSection(),
          _buildFooterSection(),
          const SizedBox(height: 100),
        ],
      ),
      bottomSheet: _buildBottomSheet(),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: Pallete.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 160,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.bottomLeft,
              children: [
                CachedNetworkImage(
                  imageUrl: 'https://images.unsplash.com/photo-1630569579526-9b0e5efef1c9?q=80&w=2344&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 160,
                    color: Pallete.blueColor.withOpacity(0.2),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 160,
                    color: Pallete.blueColor.withOpacity(0.2),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Pallete.backgroundColor],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Pallete.blueColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Snippet Blue',
                      style: TextStyle(
                        color: Pallete.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      'The premium experience',
                      style: TextStyle(
                        color: Pallete.greyColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 0.5, color: Pallete.greyColor.withOpacity(0.2)),
        ],
      ),
    );
  }

  Widget _buildPlansSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose a plan',
            style: TextStyle(
              color: Pallete.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),

          // Annual Plan
          _buildPlanCard(
            title: 'Annual',
            price: '₹6,999.00',
            period: 'per year',
            caption: 'Save 12% compared to monthly',
            isSelected: _selectedPlan == 1,
            index: 1,
            isRecommended: true,
          ),

          const SizedBox(height: 12),

          // Monthly Plan
          _buildPlanCard(
            title: 'Monthly',
            price: '₹699.00',
            period: 'per month',
            caption: '',
            isSelected: _selectedPlan == 0,
            index: 0,
            isRecommended: false,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    required String caption,
    required bool isSelected,
    required int index,
    required bool isRecommended,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPlan = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Pallete.backgroundColor,
          border: Border.all(
            color: isSelected
                ? Pallete.blueColor
                : Pallete.greyColor.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Pallete.blueColor
                      : Pallete.greyColor,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Pallete.blueColor,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Pallete.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Pallete.blueColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'RECOMMENDED',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          color: Pallete.textColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        period,
                        style: TextStyle(
                          color: Pallete.greyColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (caption.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      caption,
                      style: TextStyle(
                        color: Pallete.blueColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Features included',
            style: TextStyle(
              color: Pallete.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),

          // Features list
          _buildFeatureRow(
            icon: Icons.verified,
            text: 'Blue Verification Checkmark',
          ),
          _buildFeatureRow(
            icon: Icons.edit,
            text: 'Edit posts',
          ),
          _buildFeatureRow(
            icon: Icons.format_size,
            text: 'Longer posts (4,000 characters)',
          ),
          _buildFeatureRow(
            icon: Icons.reply_all,
            text: 'Prioritized replies',
          ),
          _buildFeatureRow(
            icon: Icons.access_time,
            text: 'Longer video uploads (60 min)',
          ),
          _buildFeatureRow(
            icon: Icons.bookmark_border,
            text: 'Bookmark folders',
          ),
          _buildFeatureRow(
            icon: Icons.format_list_bulleted,
            text: 'Reader Mode',
          ),
          _buildFeatureRow(
            icon: Icons.palette_outlined,
            text: 'App Icons & Themes',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: Pallete.blueColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Pallete.textColor,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Terms & conditions',
            style: TextStyle(
              color: Pallete.textColor,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Snippet Blue is a paid subscription that adds a verified checkmark to your account and offers early access to select features. Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period. Prices may vary by region.',
            style: TextStyle(
              color: Pallete.greyColor,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Pallete.backgroundColor,
        border: Border(
          top: BorderSide(
            color: Pallete.greyColor.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedPlan == 1 ? '₹6,999.00/year' : '₹699.00/month',
                  style: TextStyle(
                    color: Pallete.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Cancel anytime',
                  style: TextStyle(
                    color: Pallete.greyColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                _showLoadingDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Pallete.blueColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                'Subscribe',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Pallete.backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Pallete.blueColor),
              const SizedBox(height: 16),
              Text(
                'Processing payment...',
                style: TextStyle(
                  color: Pallete.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Simulate payment processing
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close loading dialog
      _showSuccessDialog();
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Pallete.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  color: Pallete.blueColor,
                  size: 40,
                ),
                const SizedBox(height: 16),
                Text(
                  "You're verified!",
                  style: TextStyle(
                    color: Pallete.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Snippet Blue subscription has been activated.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Pallete.greyColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Close success dialog
                    Navigator.pop(context);
                    // Show high volume popup instead of updating database
                    _showHighVolumePopup();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Pallete.blueColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: const Size(double.infinity, 36),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // New method to show high volume popup
  void _showHighVolumePopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Pallete.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 40,
                ),
                const SizedBox(height: 16),
                Text(
                  "Verification Delayed",
                  style: TextStyle(
                    color: Pallete.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Due to high volume of data requests, we have temporarily blocked all updates of verification badges. Please try again later.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Pallete.greyColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to profile
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Pallete.blueColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: const Size(double.infinity, 36),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Update the user's Twitter Blue status without context
  void _updateUserBlueStatusWithoutContext() async {
    try {
      // Instead of updating the database, log the attempt
      print('Twitter Blue verification update blocked due to high volume of requests');
      
      // Database update code is commented out to prevent updates
      /*
      // Get the current user ID from the auth controller
      final currentUserId = widget.ref.read(currentUserAccountProvider).value?.$id;

      if (currentUserId == null) {
        print('Error: No current user found');
        return;
      }

      // Get latest user data directly from repository
      final userData = await widget.ref.read(userAPIProvider).getUserData(currentUserId);
      final user = UserModel.fromMap(userData.data);

      // Update the Twitter Blue status
      final updatedUser = user.copyWith(istweetBlue: true);

      // Update using the API directly to avoid context dependency
      await widget.ref.read(userAPIProvider).updateUserData(updatedUser);
      */
    } catch (e) {
      print('Error in Twitter Blue status update process: $e');
    }
  }
}
