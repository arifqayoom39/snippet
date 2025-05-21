import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:snippet/common/common.dart';
import 'package:snippet/features/auth/controller/auth_controller.dart';
import 'package:snippet/services/push_notification_service.dart';
import 'package:snippet/theme/pallete.dart';

class OneSignalStatusView extends ConsumerStatefulWidget {
  const OneSignalStatusView({Key? key}) : super(key: key);

  static route() => MaterialPageRoute(
        builder: (context) => const OneSignalStatusView(),
      );

  @override
  ConsumerState<OneSignalStatusView> createState() => _OneSignalStatusViewState();
}

class _OneSignalStatusViewState extends ConsumerState<OneSignalStatusView> {
  String? _playerId;
  String? _onesignalId;
  String? _externalId;
  bool _hasPermission = false;
  bool _optedIn = false;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadOneSignalStatus();
  }
  
  Future<void> _loadOneSignalStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get player ID
      _playerId = await ref.read(pushNotificationServiceProvider).getPlayerId();
      
      // Get OneSignal ID
      _onesignalId = await OneSignal.User.getOnesignalId();
      
      // Check permission
      _hasPermission = await OneSignal.Notifications.permission;
      
      // Check if opted in
      _optedIn = OneSignal.User.pushSubscription.optedIn!;
      
      // Get current user
      final user = await ref.read(authControllerProvider.notifier).currentUser();
      _externalId = user?.$id;
    } catch (e) {
      print('Error loading OneSignal status: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _requestPermission() async {
    await OneSignal.Notifications.requestPermission(true);
    _loadOneSignalStatus();
  }
  
  Future<void> _optIn() async {
    await OneSignal.User.pushSubscription.optIn();
    _loadOneSignalStatus();
  }
  
  Future<void> _optOut() async {
    await OneSignal.User.pushSubscription.optOut();
    _loadOneSignalStatus();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      appBar: AppBar(
        backgroundColor: Pallete.backgroundColor,
        elevation: 0,
        title: Text(
          'OneSignal Status',
          style: TextStyle(color: Pallete.textColor),
        ),
        iconTheme: IconThemeData(color: Pallete.iconColor),
        actions: [
          IconButton(
            onPressed: _loadOneSignalStatus,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Loader()
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(
                      title: 'Device Player ID',
                      value: _playerId ?? 'Not available',
                      description:
                          'This is the ID used to target this device for notifications.',
                    ),
                    _buildStatusCard(
                      title: 'OneSignal User ID',
                      value: _onesignalId ?? 'Not available',
                      description:
                          'This is your OneSignal user ID.',
                    ),
                    _buildStatusCard(
                      title: 'External User ID',
                      value: _externalId ?? 'Not logged in',
                      description:
                          'This is your Appwrite user ID linked to OneSignal.',
                    ),
                    _buildStatusCard(
                      title: 'Notification Permission',
                      value: _hasPermission ? 'Granted' : 'Not Granted',
                      description:
                          'Permission to show notifications on this device.',
                      actionButton: !_hasPermission
                          ? ElevatedButton(
                              onPressed: _requestPermission,
                              child: const Text('Request Permission'),
                            )
                          : null,
                    ),
                    _buildStatusCard(
                      title: 'Push Subscription Status',
                      value: _optedIn ? 'Opted In' : 'Opted Out',
                      description:
                          'Whether you are subscribed to push notifications.',
                      actionButton: Row(
                        children: [
                          ElevatedButton(
                            onPressed: _optIn,
                            child: const Text('Opt In'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _optOut,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Opt Out'),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusCard(
                      title: 'Notification Troubleshooting',
                      value: '',
                      description:
                          'If you are not receiving notifications:\n'
                          '1. Make sure permission is granted\n'
                          '2. Make sure you are opted in\n'
                          '3. Verify your device player ID is saved correctly\n'
                          '4. Check that the app is not in focus (foreground notifications work differently)\n'
                          '5. On some devices, battery optimization can block notifications',
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String value,
    required String description,
    Widget? actionButton,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Pallete.textColor,
              ),
            ),
            const SizedBox(height: 8),
            value.isNotEmpty
                ? SelectableText(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: Pallete.textColor,
                    ),
                  )
                : const SizedBox.shrink(),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Pallete.greyColor,
              ),
            ),
            if (actionButton != null) ...[
              const SizedBox(height: 16),
              actionButton,
            ],
          ],
        ),
      ),
    );
  }
}
