import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/features/auth/controller/auth_controller.dart';
import 'package:snippet/theme/pallete.dart';

class AccountSettingsPage extends ConsumerStatefulWidget {
  final WidgetRef ref;
  
  const AccountSettingsPage({
    Key? key,
    required this.ref,
  }) : super(key: key);

  @override
  ConsumerState<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends ConsumerState<AccountSettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;
  bool _dataUsageReduced = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // Load user preferences here
    _loadUserPreferences();
  }
  
  Future<void> _loadUserPreferences() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final currentUser = await ref.read(currentUserDetailsProvider.future);
      
      // In a real app, you would load these settings from the user's preferences
      // For now, we'll just use default values
      
      setState(() {
        // These would come from user preferences in a real implementation
        _notificationsEnabled = true;
        _darkModeEnabled = true;
        _dataUsageReduced = false;
      });
    } catch (e) {
      print('Error loading preferences: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _saveNotificationPreference(bool value) async {
    setState(() {
      _notificationsEnabled = value;
      // In a real app, you would save this to the user's preferences
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notification preference updated')),
    );
  }
  
  void _saveDarkModePreference(bool value) async {
    setState(() {
      _darkModeEnabled = value;
      // In a real app, you would save this to the user's preferences and update the theme
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Theme preference updated')),
    );
  }
  
  void _saveDataUsagePreference(bool value) async {
    setState(() {
      _dataUsageReduced = value;
      // In a real app, you would save this to the user's preferences
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data usage preference updated')),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      appBar: AppBar(
        backgroundColor: Pallete.backgroundColor,
        title: Text(
          'Account Settings',
          style: TextStyle(
            color: Pallete.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Pallete.iconColor),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Pallete.blueColor))
          : ListView(
              children: [
                _buildSectionHeader('Privacy'),
                _buildSettingItem(
                  icon: Icons.lock_outline,
                  title: 'Privacy Settings',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Privacy settings coming soon')),
                    );
                  },
                ),
                _buildSettingItem(
                  icon: Icons.visibility_off,
                  title: 'Blocked Accounts',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Blocked accounts coming soon')),
                    );
                  },
                ),
                _buildSettingItem(
                  icon: Icons.history,
                  title: 'Login Activity',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Login activity coming soon')),
                    );
                  },
                ),
                
                _buildSectionHeader('Notifications'),
                SwitchListTile(
                  title: Text(
                    'Enable Notifications',
                    style: TextStyle(
                      color: Pallete.textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  value: _notificationsEnabled,
                  activeColor: Pallete.blueColor,
                  onChanged: _saveNotificationPreference,
                  secondary: Icon(
                    Icons.notifications_none,
                    color: Pallete.iconColor,
                  ),
                ),
                _buildSettingItem(
                  icon: Icons.notifications_active_outlined,
                  title: 'Notification Preferences',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Notification preferences coming soon')),
                    );
                  },
                ),
                
                _buildSectionHeader('Display'),
                SwitchListTile(
                  title: Text(
                    'Dark Mode',
                    style: TextStyle(
                      color: Pallete.textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  value: _darkModeEnabled,
                  activeColor: Pallete.blueColor,
                  onChanged: _saveDarkModePreference,
                  secondary: Icon(
                    Icons.dark_mode_outlined,
                    color: Pallete.iconColor,
                  ),
                ),
                
                _buildSectionHeader('Data & Storage'),
                SwitchListTile(
                  title: Text(
                    'Reduce Data Usage',
                    style: TextStyle(
                      color: Pallete.textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  value: _dataUsageReduced,
                  activeColor: Pallete.blueColor,
                  onChanged: _saveDataUsagePreference,
                  secondary: Icon(
                    Icons.data_usage,
                    color: Pallete.iconColor,
                  ),
                ),
                _buildSettingItem(
                  icon: Icons.storage_outlined,
                  title: 'Storage Usage',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Storage usage coming soon')),
                    );
                  },
                ),
                
                _buildSectionHeader('Support'),
                _buildSettingItem(
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Help center coming soon')),
                    );
                  },
                ),
                _buildSettingItem(
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () {
                    _showAboutDialog();
                  },
                ),
                
                _buildSectionHeader('Account'),
                _buildSettingItem(
                  icon: Icons.delete_outline,
                  title: 'Deactivate Account',
                  textColor: Colors.redAccent,
                  onTap: () {
                    _showDeactivateAccountDialog();
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Pallete.blueColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
  
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: Pallete.iconColor),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Pallete.textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Pallete.greyColor,
      ),
      onTap: onTap,
    );
  }
  
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Pallete.backgroundColor,
        title: Text(
          'About Snippet',
          style: TextStyle(
            color: Pallete.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Snippet - A Twitter-like Social Platform',
              style: TextStyle(color: Pallete.textColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Version: 1.0.0',
              style: TextStyle(color: Pallete.textColor),
            ),
            const SizedBox(height: 16),
            Text(
              '© 2023 Snippet. All rights reserved.',
              style: TextStyle(color: Pallete.greyColor),
            ),
          ],
        ),
        actions: [
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
  
  void _showDeactivateAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Pallete.backgroundColor,
        title: Text(
          'Deactivate Account',
          style: TextStyle(
            color: Pallete.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to deactivate your account? This action cannot be undone.',
          style: TextStyle(color: Pallete.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Pallete.greyColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // In a real app, this would call a method to deactivate the account
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Account deactivation coming soon')),
              );
            },
            child: Text(
              'Deactivate',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
