import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/apis/user_api.dart';
import 'package:snippet/features/auth/controller/auth_controller.dart';
import 'package:snippet/theme/pallete.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

class AudioRoomScreen extends ConsumerStatefulWidget {
  final String audioRoomId;
  final bool isHost;
  final String tweetCreatorUid;

  const AudioRoomScreen({
    super.key,
    required this.audioRoomId,
    required this.tweetCreatorUid,
    this.isHost = false,
  });

  @override
  ConsumerState<AudioRoomScreen> createState() => _AudioRoomScreenState();
}

class _AudioRoomScreenState extends ConsumerState<AudioRoomScreen> {
  Call? _audioRoomCall;
  CallState? _callState;
  bool microphoneEnabled = false;
  bool isInitialized = false;
  bool isError = false;
  String errorMessage = '';
  bool handRaised = false;

  // Cache for user data to avoid repeated fetches
  final Map<String, Map<String, dynamic>> _userDataCache = {};
  // Track users with raised hands
  final Set<String> _participantsWithRaisedHands = {};

  @override
  void initState() {
    super.initState();
    // Fetch host user data
    _fetchHostUserData();

    // Delay to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAudioRoom();
    });
  }

  // Pre-fetch the host user data
  Future<void> _fetchHostUserData() async {
    try {
      final hostData = await _getUserData(widget.tweetCreatorUid);
      if (hostData != null) {
        _userDataCache[widget.tweetCreatorUid] = hostData;
      }
    } catch (e) {
      debugPrint('Error pre-fetching host data: $e');
    }
  }

  Future<void> _initializeAudioRoom() async {
    try {
      // Get the current user's details
      final currentUser = ref.read(currentUserDetailsProvider).value;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Use the current user's information
      final userId = currentUser.uid;
      final userName = currentUser.name;
      final userImage = currentUser.profilePic;

      debugPrint('Initializing audio room with userId: $userId, name: $userName');

      // Create a user with the provided details
      final user = User.guest(
        userId: userId,
        name: userName,
        image: userImage,
      );

      // Reset any existing StreamVideo instance first
      StreamVideo.reset();

      // Initialize Stream Video with user details
      final client = StreamVideo(
        'API KEY', // Replace with your actual Stream API key
        user: user,
      );

      // Connect to get the user token automatically
      final connectResult = await client.connect();
      if (!connectResult.isSuccess) {
        throw Exception('Failed to connect: $connectResult');
      }

      // Set up our call object using the established client
      final call = client.makeCall(
        callType: StreamCallType.audioRoom(),
        id: widget.audioRoomId,
      );

      debugPrint('Attempting to get or create call: ${widget.audioRoomId}');
      final result = await call.getOrCreate();

      if (result.isSuccess) {
        debugPrint('Call created successfully, joining...');
        await call.join();

        if (widget.isHost) {
          debugPrint('User is host, going live and enabling microphone');
          await call.goLive();
          await call.setMicrophoneEnabled(enabled: true);
          setState(() {
            microphoneEnabled = true;
          });
        }

        // Handle permission requests (auto-approve in this example)
        call.onPermissionRequest = (permissionRequest) {
          call.grantPermissions(
            userId: permissionRequest.user.id,
            permissions: permissionRequest.permissions.toList(),
          );
        };

        // Setup reaction handler for raised hands
        call.callEvents.on<StreamCallReactionEvent>((event) {
          if (event.reactionType == 'raised-hand') {
            setState(() {
              if (!_participantsWithRaisedHands.contains(event.user.id)) {
          _participantsWithRaisedHands.add(event.user.id);
          
          // If this user is the host, show notification for raised hand
          if (widget.isHost && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${event.user.name} raised their hand'),
                action: SnackBarAction(
            label: 'Allow to speak',
            onPressed: () {
              _allowParticipantToSpeak(event.user.id);
            },
                ),
              ),
            );
          }
              }
            });
          } else if (event.reactionType == 'lowered-hand') {
            setState(() {
              _participantsWithRaisedHands.remove(event.user.id);
            });
          }
        });

        _audioRoomCall = call;
        _callState = call.state.value;

        setState(() {
          isInitialized = true;
        });

        debugPrint('Audio room initialized successfully');
      } else {
        throw Exception('Failed to create call: $result');
      }
    } catch (e) {
      debugPrint('Error initializing audio room: $e');
      setState(() {
        isError = true;
        errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _leaveAudioRoom();
    super.dispose();
  }

  Future<void> _leaveAudioRoom() async {
    try {
      if (_audioRoomCall != null) {
        await _audioRoomCall!.leave();
      }
    } catch (e) {
      debugPrint('Error leaving audio room: $e');
    }
  }

  // Improved user data fetching with caching
  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    // Return cached data if available
    if (_userDataCache.containsKey(userId)) {
      return _userDataCache[userId];
    }

    try {
      // Extract the actual user ID from Stream's longer format
      final actualUserId = _extractUserIdFromStreamId(userId);

      final userAPI = ref.read(userAPIProvider);
      final userData = await userAPI.getUserData(actualUserId);

      // Cache the result
      _userDataCache[userId] = userData.data;

      return userData.data;
    } catch (e) {
      debugPrint('Error fetching user profile for $userId: $e');

      // Create placeholder data for this user
      final placeholderData = {
        'name': 'Guest User',
        'profilePic': '',
      };

      // Cache the placeholder to avoid repeated failed lookups
      _userDataCache[userId] = placeholderData;

      return placeholderData;
    }
  }

  // Extract the actual Appwrite-compatible user ID from Stream's ID format
  String _extractUserIdFromStreamId(String streamUserId) {
    // Check if this might be our local user
    if (streamUserId == ref.read(currentUserDetailsProvider).value?.uid) {
      return streamUserId;
    }

    // For the host, use the tweet creator UID directly
    if (streamUserId == widget.tweetCreatorUid) {
      return widget.tweetCreatorUid;
    }

    // If it's a guest ID format from Stream (guest-UUID-actualId)
    if (streamUserId.startsWith('guest-')) {
      try {
        // Try to extract the last part which might be our actual ID
        final parts = streamUserId.split('-');
        if (parts.length > 1) {
          // Use the last part which might be the actual user ID
          return parts.last;
        }
      } catch (e) {
        debugPrint('Error extracting user ID: $e');
      }
    }

    // Fallback: if the ID is too long, truncate it to 36 chars
    if (streamUserId.length > 36) {
      return streamUserId.substring(0, 36);
    }

    return streamUserId;
  }

  Future<void> _muteAllParticipants() async {
    try {
      if (_audioRoomCall != null && widget.isHost) {
        await _audioRoomCall!.muteAllUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All participants muted')),
        );
      }
    } catch (e) {
      debugPrint('Error muting all participants: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mute participants: $e')),
      );
    }
  }

  Future<void> _muteParticipant(String userId) async {
    try {
      if (_audioRoomCall != null && widget.isHost) {
        await _audioRoomCall!.muteUsers(userIds: [userId]);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Participant muted')),
        );
      }
    } catch (e) {
      debugPrint('Error muting participant: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mute participant: $e')),
      );
    }
  }

  Future<void> _endAudioRoom() async {
    try {
      if (_audioRoomCall != null && widget.isHost) {
        await _audioRoomCall!.end();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio room ended')),
        );
        // Return to previous screen
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Error ending audio room: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to end audio room: $e')),
      );
    }
  }

  Future<void> _toggleRaiseHand() async {
    try {
      if (_audioRoomCall != null) {
        if (handRaised) {
          // Lower hand
          await _audioRoomCall!.sendReaction(
            reactionType: 'lowered-hand',
            emojiCode: ':lowered-hand:',
          );
        } else {
          // Raise hand
          await _audioRoomCall!.sendReaction(
            reactionType: 'raised-hand',
            emojiCode: ':raised-hand:',
          );
        }
        
        setState(() {
          handRaised = !handRaised;
          // Update local tracking of raised hands
          final currentUser = ref.read(currentUserDetailsProvider).value;
          if (currentUser != null) {
            if (handRaised) {
              _participantsWithRaisedHands.add(currentUser.uid);
            } else {
              _participantsWithRaisedHands.remove(currentUser.uid);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error toggling raised hand: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to ${handRaised ? 'lower' : 'raise'} hand: $e')),
      );
    }
  }

  Future<void> _allowParticipantToSpeak(String userId) async {
    try {
      if (_audioRoomCall != null && widget.isHost) {
        // Grant audio permission to the participant
        await _audioRoomCall!.grantPermissions(
          userId: userId,
          permissions: [CallPermission.sendAudio],
        );
        
        // Remove from raised hands list
        setState(() {
          _participantsWithRaisedHands.remove(userId);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Participant can now speak')),
        );
      }
    } catch (e) {
      debugPrint('Error allowing participant to speak: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to allow participant to speak: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user for UI customization
    final currentUser = ref.watch(currentUserDetailsProvider).value;

    if (isError) {
      return Scaffold(
        backgroundColor: Pallete.backgroundColor,
        appBar: AppBar(
          backgroundColor: Pallete.backgroundColor,
          title: const Text('Audio Room Error'),
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to connect to audio room',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Pallete.blueColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!isInitialized || _audioRoomCall == null || _callState == null) {
      return Scaffold(
        backgroundColor: Pallete.backgroundColor,
        appBar: AppBar(
          backgroundColor: Pallete.backgroundColor,
          title: const Text('Connecting to Audio Room...'),
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Pallete.blueColor),
              const SizedBox(height: 16),
              const Text(
                'Connecting to audio room...',
                style: TextStyle(color: Pallete.whiteColor),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      appBar: AppBar(
        backgroundColor: Pallete.backgroundColor,
        elevation: 0,
        title: Row(
          children: [
            Text(
              'Audio Room',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Pallete.greyColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _callState!.callParticipants.length.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Pallete.whiteColor,
                ),
              ),
            ),
          ],
        ),
        leading: IconButton(
          onPressed: () async {
            await _leaveAudioRoom();
            if (mounted) {
              Navigator.pop(context);
            }
          },
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Pallete.greyColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.keyboard_arrow_down, size: 18),
          ),
        ),
        actions: [
          // Add mute all button for host
          if (widget.isHost)
            IconButton(
              onPressed: _muteAllParticipants,
              tooltip: 'Mute all participants',
              icon: const Icon(Icons.mic_off_outlined),
            ),
          // Add end room button for host
          if (widget.isHost)
            IconButton(
              onPressed: () {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Pallete.backgroundColor,
                    title: Text(
                      'End Audio Room?',
                      style: const TextStyle(color: Pallete.backgroundColorDark),
                    ),
                    content: const Text(
                      'This will end the audio room for all participants.',
                      style: TextStyle(color: Pallete.backgroundColorDark),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Pallete.blueColor),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _endAudioRoom();
                        },
                        child: const Text(
                          'End Room',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'End audio room',
              icon: const Icon(Icons.call_end, color: Colors.red),
            ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Raised hand button
          if (!widget.isHost) // Only show for non-hosts
            Container(
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: 'raiseHand',
                child: Icon(
                  handRaised ? Icons.back_hand : Icons.front_hand,
                  color: Colors.white,
                ),
                backgroundColor: handRaised ? Colors.amber : Colors.grey,
                onPressed: _toggleRaiseHand,
              ),
            ),
          // Microphone button
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: FloatingActionButton(
              heroTag: 'microphone',
              child: Icon(
                microphoneEnabled ? Icons.mic : Icons.mic_off,
                color: Colors.white,
              ),
              backgroundColor: microphoneEnabled ? Pallete.blueColor : Colors.grey,
              onPressed: () {
                if (_audioRoomCall != null) {
                  if (microphoneEnabled) {
                    _audioRoomCall!.setMicrophoneEnabled(enabled: false);
                    setState(() {
                      microphoneEnabled = false;
                    });
                  } else {
                    if (!_audioRoomCall!.hasPermission(CallPermission.sendAudio)) {
                      _audioRoomCall!.requestPermissions(
                        [CallPermission.sendAudio],
                      );
                    }
                    _audioRoomCall!.setMicrophoneEnabled(enabled: true);
                    setState(() {
                      microphoneEnabled = true;
                    });
                  }
                }
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<CallState>(
        initialData: _callState,
        stream: _audioRoomCall!.state.valueStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Cannot fetch call state.',
                style: TextStyle(color: Pallete.whiteColor),
              ),
            );
          }

          if (snapshot.hasData && !snapshot.hasError) {
            final callState = snapshot.data!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room Title Section
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Pallete.backgroundColor,
                        Pallete.backgroundColor.withOpacity(0.9),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Snippet Space',
                        style: TextStyle(
                          color: Pallete.backgroundColorDark,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (widget.isHost)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Pallete.blueColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'HOST',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (widget.isHost) const SizedBox(width: 8),
                          Text(
                            '${callState.callParticipants.length} listening',
                            style: TextStyle(
                              color: Pallete.backgroundColorDark,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Host & Speaker Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Speakers',
                    style: TextStyle(
                      color: Pallete.greyColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Participants Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemBuilder: (BuildContext context, int index) {
                        final participant = callState.callParticipants[index];

                        // Determine if this participant is the host
                        final isParticipantHost = participant.userId == widget.tweetCreatorUid;
                        final isCurrentUser = participant.userId == currentUser?.uid;

                        // Use improved user data fetching with caching
                        return FutureBuilder(
                          future: _getUserData(participant.userId),
                          builder: (context, snapshot) {
                            String name = 'User';
                            String imageUrl = '';

                            // If we have user data from database
                            if (snapshot.hasData && snapshot.data != null) {
                              name = snapshot.data!['name'] ?? 'User';
                              imageUrl = snapshot.data!['profilePic'] ?? '';
                            }
                            // For the current user, we already have the info
                            else if (isCurrentUser && currentUser != null) {
                              name = currentUser.name;
                              imageUrl = currentUser.profilePic;
                            }

                            return _buildParticipantTile(
                              participant,
                              isParticipantHost,
                              isCurrentUser,
                              name: name,
                              imageUrl: imageUrl,
                            );
                          },
                        );
                      },
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: callState.callParticipants.length,
                    ),
                  ),
                ),

                // Bottom safe area padding
                SizedBox(height: MediaQuery.of(context).padding.bottom + 60),
              ],
            );
          }

          return Center(
            child: CircularProgressIndicator(color: Pallete.blueColor),
          );
        },
      ),
    );
  }

  Widget _buildParticipantTile(
    CallParticipantState participant,
    bool isHost,
    bool isCurrentUser, {
    required String name,
    required String imageUrl,
  }) {
    final isMicEnabled = participant.isAudioEnabled;
    final hasRaisedHand = _participantsWithRaisedHands.contains(participant.userId);
    
    // Don't show controls for the host or current user
    final canBeManaged = widget.isHost && !isHost && !isCurrentUser;

    return GestureDetector(
      onLongPress: canBeManaged ? () {
        // Show options menu for host to mute this participant
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Pallete.backgroundColor,
            title: Text(
              'Manage Participant',
              style: TextStyle(color: Pallete.backgroundColorDark),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: Pallete.backgroundColorDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.mic_off,
                    color: Pallete.backgroundColorDark,
                  ),
                  title: const Text(
                    'Mute participant',
                    style: TextStyle(color: Pallete.backgroundColorDark),
                  ),
                  onTap: () {
                    _muteParticipant(participant.userId);
                    Navigator.pop(context);
                  },
                  enabled: isMicEnabled,
                ),
                if (hasRaisedHand)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.record_voice_over,
                      color: Pallete.backgroundColorDark,
                    ),
                    title: const Text(
                      'Allow to speak',
                      style: TextStyle(color: Pallete.backgroundColorDark),
                    ),
                    onTap: () {
                      _allowParticipantToSpeak(participant.userId);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Pallete.blueColor),
                ),
              ),
            ],
          ),
        );
      } : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Profile image with speaking indicator
          Stack(
            children: [
              // Profile container
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: participant.isSpeaking
                      ? Border.all(color: Pallete.blueColor, width: 2.5)
                      : null,
                  boxShadow: participant.isSpeaking
                      ? [
                          BoxShadow(
                            color: Pallete.blueColor.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Pallete.greyColor.withOpacity(0.3),
                            child: Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Pallete.backgroundColorDark,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: Pallete.greyColor.withOpacity(0.3),
                            child: Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Pallete.backgroundColorDark,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: Pallete.greyColor.withOpacity(0.3),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Pallete.whiteColor,
                              ),
                            ),
                          ),
                        ),
                ),
              ),

              // Host badge
              if (isHost)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Pallete.backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Pallete.blueColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.orange,
                        size: 10,
                      ),
                    ),
                  ),
                ),

              // Mic status indicator
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Pallete.backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isMicEnabled ? Pallete.blueColor : Pallete.greyColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isMicEnabled ? Icons.mic : Icons.mic_off,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
              ),

              // Raised hand indicator
              if (hasRaisedHand)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Pallete.backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.front_hand,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // User name
          Text(
            isCurrentUser ? '$name (You)' : name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Pallete.backgroundColorDark,
              fontWeight: isHost ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),

          // Speaking indicator
          if (participant.isSpeaking)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Pallete.blueColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Speaking',
                  style: TextStyle(
                    color: Pallete.blueColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Raised hand indicator text
          if (hasRaisedHand && !participant.isSpeaking)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Hand raised',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
