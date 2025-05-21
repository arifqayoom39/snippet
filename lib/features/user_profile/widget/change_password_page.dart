import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/features/auth/controller/auth_controller.dart';
import 'package:snippet/theme/pallete.dart';
import 'package:snippet/common/rounded_button.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  final WidgetRef ref;
  
  const ChangePasswordPage({
    Key? key,
    required this.ref,
  }) : super(key: key);

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  
  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  void _changePassword() {
    // Validate passwords
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required')),
      );
      return;
    }
    
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    if (_newPasswordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters')),
      );
      return;
    }
    
    // Call the actual password change method in AuthController
    ref.read(authControllerProvider.notifier).changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);
    
    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      appBar: AppBar(
        backgroundColor: Pallete.backgroundColor,
        title: Text(
          'Change Password',
          style: TextStyle(
            color: Pallete.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Pallete.iconColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your current password and a new password to update your account.',
              style: TextStyle(color: Pallete.greyColor),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrentPassword,
              enabled: !isLoading,
              decoration: InputDecoration(
                labelText: 'Current Password',
                labelStyle: TextStyle(color: Pallete.greyColor),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Pallete.greyColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Pallete.blueColor),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                    color: Pallete.greyColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureCurrentPassword = !_obscureCurrentPassword;
                    });
                  },
                ),
              ),
              style: TextStyle(color: Pallete.textColor),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              enabled: !isLoading,
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(color: Pallete.greyColor),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Pallete.greyColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Pallete.blueColor),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                    color: Pallete.greyColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
                helperText: 'Password must be at least 8 characters',
                helperStyle: TextStyle(color: Pallete.greyColor),
              ),
              style: TextStyle(color: Pallete.textColor),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              enabled: !isLoading,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                labelStyle: TextStyle(color: Pallete.greyColor),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Pallete.greyColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Pallete.blueColor),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    color: Pallete.greyColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              style: TextStyle(color: Pallete.textColor),
            ),
            const SizedBox(height: 32),
            RoundedButton(
              onTap: isLoading ? () {} : _changePassword,
              label: 'Update Password',
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
