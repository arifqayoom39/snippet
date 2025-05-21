import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/common/loading_page.dart';
import 'package:snippet/features/auth/controller/auth_controller.dart';
import 'package:snippet/features/auth/view/login_view.dart';
import 'package:snippet/features/auth/widgets/auth_field.dart';
import 'package:snippet/models/user_model.dart';
import 'package:snippet/theme/pallete.dart';

class UsernameSelectionView extends ConsumerStatefulWidget {
  static route({required UserModel userModel}) => MaterialPageRoute(
        builder: (context) => UsernameSelectionView(userModel: userModel),
      );

  final UserModel userModel;
  const UsernameSelectionView({required this.userModel, Key? key}) : super(key: key);

  @override
  ConsumerState<UsernameSelectionView> createState() => _UsernameSelectionViewState();
}

class _UsernameSelectionViewState extends ConsumerState<UsernameSelectionView> {
  final usernameController = TextEditingController();
  final nameController = TextEditingController();
  bool isUsernameAvailable = true;
  String usernameError = '';

  @override
  void initState() {
    super.initState();
    nameController.text = widget.userModel.name;
  }

  @override
  void dispose() {
    super.dispose();
    usernameController.dispose();
    nameController.dispose();
  }

  void onContinue() {
    if (usernameController.text.isEmpty) {
      setState(() {
        usernameError = 'Username cannot be empty';
        isUsernameAvailable = false;
      });
      return;
    }

    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your name'),
          backgroundColor: const Color(0xFF1D9BF0),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      );
      return;
    }

    if (!isUsernameAvailable) {
      return;
    }

    final updatedUser = widget.userModel.copyWith(
      name: nameController.text.trim(),
      username: usernameController.text.trim(),
    );

    ref.read(authControllerProvider.notifier).updateUserData(
          userModel: updatedUser,
          context: context,
          onSuccess: () {
            Navigator.pushAndRemoveUntil(
              context,
              LoginView.route(),
              (route) => false,
            );
          },
        );
  }

  void checkUsernameAvailability() async {
    final username = usernameController.text.trim();

    if (username.isEmpty) {
      setState(() {
        usernameError = 'Username cannot be empty';
        isUsernameAvailable = false;
      });
      return;
    }

    if (username.contains(' ') || !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      setState(() {
        usernameError = 'Username can only contain letters, numbers, and underscores';
        isUsernameAvailable = false;
      });
      return;
    }

    setState(() {
      isUsernameAvailable = true;
      usernameError = '';
    });

    final available = await ref.read(authControllerProvider.notifier)
        .checkUsernameAvailability(username);

    setState(() {
      isUsernameAvailable = available;
      if (!available) {
        usernameError = 'Username is already taken';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);
    final isDarkMode = ref.watch(themeProvider);

    final backgroundColor = isDarkMode ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    final textColor = isDarkMode ? const Color(0xFFE7E9EA) : const Color(0xFF0F1419);
    final twitterBlue = const Color(0xFF1D9BF0);
    final secondaryTextColor = isDarkMode ? const Color(0xFF71767B) : const Color(0xFF536471);
    final borderColor = isDarkMode ? const Color(0xFF2F3336) : const Color(0xFFEFF3F4);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0.5,
        title: const Text(
          'Create your account',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: borderColor,
            height: 0.5,
          ),
        ),
      ),
      body: isLoading
          ? const Loader()
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'What should we call you?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your @username is unique. You can always change it later.',
                      style: TextStyle(
                        fontSize: 15,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: 'Name',
                            hintStyle: TextStyle(color: secondaryTextColor),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: usernameError.isNotEmpty
                                  ? Colors.red
                                  : borderColor,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: TextField(
                              controller: usernameController,
                              onChanged: (_) => checkUsernameAvailability(),
                              decoration: InputDecoration(
                                hintText: 'Username',
                                hintStyle: TextStyle(color: secondaryTextColor),
                                border: InputBorder.none,
                                prefixText: '@',
                                prefixStyle: TextStyle(color: secondaryTextColor),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              style: TextStyle(color: textColor),
                            ),
                          ),
                        ),
                        if (usernameError.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 2.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    usernameError,
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (usernameController.text.isNotEmpty && isUsernameAvailable && usernameError.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 2.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: twitterBlue,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'This username is available',
                                  style: TextStyle(
                                    color: twitterBlue,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: twitterBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
