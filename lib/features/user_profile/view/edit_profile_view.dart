// ignore_for_file: prefer_const_constructors

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/common/loading_page.dart';
import 'package:snippet/core/utils.dart';
import 'package:snippet/features/auth/controller/auth_controller.dart';
import 'package:snippet/features/user_profile/controller/user_profile_controller.dart';
import 'package:snippet/theme/theme.dart';

class EditProfileView extends ConsumerStatefulWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const EditProfileView(),
      );
  const EditProfileView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _EditProfileViewState();
}

class _EditProfileViewState extends ConsumerState<EditProfileView> {
  late TextEditingController nameController;
  late TextEditingController bioController;
  File? profileFile;
  File? bannerFile;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: ref.read(currentUserDetailsProvider).value?.name ?? '',
    );
    bioController = TextEditingController(
      text: ref.read(currentUserDetailsProvider).value?.bio ?? '',
    );
  }

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
    bioController.dispose();
  }

  void selectProfileImage() async {
    final profileImage = await pickImage();
    if (profileImage != null) {
      setState(() {
        profileFile = profileImage;
      });
    }
  }

  void selectBannerImage() async {
    final bannerImage = await pickImage();
    if (bannerImage != null) {
      setState(() {
        bannerFile = bannerImage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserDetailsProvider).value;
    final isLoading = ref.watch(userProfileControllerProvider);
    final isDarkMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      appBar: AppBar(
        backgroundColor: Pallete.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Pallete.iconColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: Pallete.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {
              ref
                  .read(userProfileControllerProvider.notifier)
                  .updateUserProfile(
                    userModel: user!.copyWith(
                      bio: bioController.text,
                      name: nameController.text,
                    ),
                    context: context,
                    profileFile: profileFile,
                    bannerFile: bannerFile,
                  );
            },
            child: Text(
              'Save',
              style: TextStyle(
                color: Pallete.blueColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: isLoading || user == null
          ? const Loader()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Image
                  GestureDetector(
                    onTap: selectBannerImage,
                    child: Stack(
                      children: [
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Pallete.blueColor,
                            image: bannerFile != null
                                ? DecorationImage(
                                    image: FileImage(bannerFile!),
                                    fit: BoxFit.cover,
                                  )
                                : user.bannerPic.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(user.bannerPic),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Pallete.backgroundColor.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Pallete.whiteColor,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: selectProfileImage,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  backgroundImage: profileFile != null
                                      ? FileImage(profileFile!)
                                      : NetworkImage(user.profilePic) as ImageProvider,
                                  radius: 50,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Pallete.blueColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildCustomTextField(
                          controller: nameController,
                          labelText: 'Name',
                          hintText: 'Enter your name',
                        ),
                        const SizedBox(height: 20),
                        _buildCustomTextField(
                          controller: bioController,
                          labelText: 'Bio',
                          hintText: 'Describe yourself',
                          maxLength: 400,
                          maxLines: 5,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Pallete.greyColor),
        hintText: hintText,
        hintStyle: TextStyle(color: Pallete.greyColor.withOpacity(0.7)),
        counterText: '', // Hide the character counter
        filled: true,
        fillColor: Pallete.backgroundColor, // Use theme color instead of hardcoded black
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: Pallete.greyColor.withOpacity(0.3), // Use theme color with opacity
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: Pallete.blueColor, // Use blue color when focused
            width: 2,
          ),
        ),
      ),
      style: TextStyle(
        color: Pallete.textColor, // Use theme text color
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
