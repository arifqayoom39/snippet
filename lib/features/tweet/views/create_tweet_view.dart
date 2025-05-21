import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snippet/common/loading_page.dart';
import 'package:snippet/common/rounded_small_button.dart';
import 'package:snippet/constants/assets_constants.dart';
import 'package:snippet/core/enums/tweet_type_enum.dart';
import 'package:snippet/core/utils.dart';
import 'package:snippet/features/audio_room/views/audio_room_screen.dart';
import 'package:snippet/features/auth/controller/auth_controller.dart';
import 'package:snippet/features/tweet/controller/tweet_controller.dart';
import 'package:snippet/theme/pallete.dart';
import 'package:video_player/video_player.dart';

class CreatetweetScreen extends ConsumerStatefulWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const CreatetweetScreen(),
      );
  const CreatetweetScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CreatetweetScreenState();
}

class _CreatetweetScreenState extends ConsumerState<CreatetweetScreen> {
  final tweetTextController = TextEditingController();
  List<File> images = [];
  File? videoFile;
  File? audioFile;
  String? selectedGifUrl;
  bool showPollOptions = false;
  bool showLocationPicker = false;
  bool showAudioRoom = false;
  List<TextEditingController> pollOptionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  int pollDurationHours = 24; // Default 24 hours
  Map<String, dynamic>? locationData;
  VideoPlayerController? _videoPreviewController;

  @override
  void dispose() {
    tweetTextController.dispose();
    for (var controller in pollOptionControllers) {
      controller.dispose();
    }
    _videoPreviewController?.dispose();
    super.dispose();
  }

  void sharetweet() async {
    if (tweetTextController.text.trim().isEmpty && 
        images.isEmpty && 
        videoFile == null && 
        selectedGifUrl == null &&
        audioFile == null && 
        !showPollOptions &&
        !showAudioRoom &&
        locationData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter text or add media')),
      );
      return;
    }
    
    bool success = false;
    
    // Handle different tweet types
    if (showAudioRoom) {
      final String audioRoomId = DateTime.now().millisecondsSinceEpoch.toString();
      success = await ref.read(tweetControllerProvider.notifier).shareAudioRoomTweet(
        audioRoomId: audioRoomId,
        text: tweetTextController.text,
        context: context,
        repliedTo: '',
        repliedToUserId: '',
      );
      
      
    } else if (videoFile != null) {
      success = await ref.read(tweetControllerProvider.notifier).shareVideoTweet(
        video: videoFile!,
        text: tweetTextController.text,
        context: context,
        repliedTo: '',
        repliedToUserId: '',
      );
    } else if (selectedGifUrl != null) {
      success = await ref.read(tweetControllerProvider.notifier).shareGifTweet(
        gifUrl: selectedGifUrl!,
        text: tweetTextController.text,
        context: context,
        repliedTo: '',
        repliedToUserId: '',
      );
    } else if (showPollOptions) {
      // Get non-empty poll options
      final options = pollOptionControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
      
      if (options.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least 2 poll options')),
        );
        return;
      }
      
      success = await ref.read(tweetControllerProvider.notifier).sharePollTweet(
        text: tweetTextController.text,
        pollOptions: options,
        pollDuration: Duration(hours: pollDurationHours),
        context: context,
        repliedTo: '',
        repliedToUserId: '',
      );
    } else if (audioFile != null) {
      success = await ref.read(tweetControllerProvider.notifier).shareAudioTweet(
        audio: audioFile!,
        text: tweetTextController.text,
        context: context,
        repliedTo: '',
        repliedToUserId: '',
      );
    } else if (locationData != null) {
      success = await ref.read(tweetControllerProvider.notifier).shareLocationTweet(
        locationData: locationData!,
        text: tweetTextController.text,
        context: context,
        repliedTo: '',
        repliedToUserId: '',
      );
    } else if (images.isNotEmpty) {
      // Regular image tweet
      success = await ref.read(tweetControllerProvider.notifier).shareTweet(
        images: images,
        text: tweetTextController.text,
        context: context,
        repliedTo: '',
        repliedToUserId: '',
      );
    } else {
      // Regular text tweet
      success = await ref.read(tweetControllerProvider.notifier).shareTweet(
        images: [],
        text: tweetTextController.text,
        context: context,
        repliedTo: '',
        repliedToUserId: '',
      );
    }
    
    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  void onPickImages() async {
    // Reset other media types
    videoFile = null;
    audioFile = null;
    selectedGifUrl = null;
    showPollOptions = false;
    showLocationPicker = false;
    showAudioRoom = false;
    
    images = await pickImages();
    setState(() {});
  }

  void onPickVideo() async {
    // Reset other media types
    images = [];
    audioFile = null;
    selectedGifUrl = null;
    showPollOptions = false;
    showLocationPicker = false;
    showAudioRoom = false;
    
    final picker = ImagePicker();
    final pickedVideo = await picker.pickVideo(source: ImageSource.gallery);
    
    if (pickedVideo != null) {
      videoFile = File(pickedVideo.path);
      
      // Initialize video preview
      _videoPreviewController?.dispose();
      _videoPreviewController = VideoPlayerController.file(videoFile!);
      await _videoPreviewController!.initialize();
      await _videoPreviewController!.setLooping(true);
      
      setState(() {});
    }
  }

  void onPickAudio() async {
    // Reset other media types
    images = [];
    videoFile = null;
    selectedGifUrl = null;
    showPollOptions = false;
    showLocationPicker = false;
    showAudioRoom = false;
    
    // Simulate audio selection for now
    // In a real app, you'd use a file picker package to select audio files
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Audio'),
        content: const Text('This would open an audio recorder in a real app.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Simulate a recorded audio file
              audioFile = File('dummy_audio.mp3');
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Simulate Recording'),
          ),
        ],
      ),
    );
  }

  void onPickGif() async {
    // Reset other media types
    images = [];
    videoFile = null;
    audioFile = null;
    showPollOptions = false;
    showLocationPicker = false;
    showAudioRoom = false;
    
    // Show a dialog with some sample GIFs
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text(
                    'Select a GIF',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(8),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  // Sample GIFs - in a real app, you'd integrate with a GIF service API
                  _buildGifTile('https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExZDAxN2ZjZmU4Yzc4MTlmMzQ0Yzk0MmQwZjVhNDE1YmMyYzNmYzk1YSZlcD12MV9pbnRlcm5hbF9naWZzX2dpZklkJmN0PWc/C9x8gX02SnMIoAClXa/giphy.gif'),
                  _buildGifTile('https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNDRlMmJjN2ZjYTk4YmVkM2FhNDhmOGIxMzVlNmNmZDQzYTE5NTFiOSZlcD12MV9pbnRlcm5hbF9naWZzX2dpZklkJmN0PWc/hryis7A55RVZM2prV3/giphy.gif'),
                  _buildGifTile('https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExYTljZDg3OTcxYjI2MDRkMTU0ODVjOTQ4MWQzZmI1MGE0MWYzZDFkNCZlcD12MV9pbnRlcm5hbF9naWZzX2dpZklkJmN0PWc/XreQmk7ETCak0/giphy.gif'),
                  _buildGifTile('https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExODNhYThiOGUyYTg2YWQ1NWYxMWUwZDczMWI3NzU1OWYzNzFhZDBhOCZlcD12MV9pbnRlcm5hbF9naWZzX2dpZklkJmN0PWc/scZPhLqaVOM1qG4lT9/giphy.gif'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGifTile(String gifUrl) {
    return GestureDetector(
      onTap: () {
        selectedGifUrl = gifUrl;
        setState(() {});
        Navigator.pop(context);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: gifUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Pallete.greyColor.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Pallete.greyColor.withOpacity(0.3),
            child: const Center(
              child: Icon(Icons.error),
            ),
          ),
        ),
      ),
    );
  }

  void togglePollOptions() {
    // Reset other media types
    images = [];
    videoFile = null;
    audioFile = null;
    selectedGifUrl = null;
    showLocationPicker = false;
    showAudioRoom = false;
    
    setState(() {
      showPollOptions = !showPollOptions;
    });
  }

  void toggleLocationPicker() {
    // Reset other media types
    images = [];
    videoFile = null;
    audioFile = null;
    selectedGifUrl = null;
    showPollOptions = false;
    showAudioRoom = false;
    
    setState(() {
      showLocationPicker = !showLocationPicker;
      if (showLocationPicker) {
        // For demonstration purposes, set dummy location data
        locationData = {
          'name': 'Snippet HQ',
          'latitude': 37.7749,
          'longitude': -122.4194,
        };
      } else {
        locationData = null;
      }
    });
  }

  void toggleAudioRoom() async {
    // Only allow Twitter Blue users to create audio rooms
    final currentUser = ref.read(currentUserDetailsProvider).value;
    if (currentUser != null && !currentUser.istweetBlue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio rooms are only available for Snippet Blue subscribers'),
          backgroundColor: Pallete.redColor,
        ),
      );
      return;
    }
    
    // Reset other media types
    images = [];
    videoFile = null;
    audioFile = null;
    selectedGifUrl = null;
    showPollOptions = false;
    showLocationPicker = false;
    
    setState(() {
      showAudioRoom = !showAudioRoom;
    });
  }

  void addPollOption() {
    if (pollOptionControllers.length < 4) { // Maximum 4 options
      setState(() {
        pollOptionControllers.add(TextEditingController());
      });
    }
  }

  Widget _buildAudioRoomPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Pallete.blueColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Pallete.blueColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.spatial_audio,
                    color: Pallete.blueColor,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Audio Room',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  setState(() {
                    showAudioRoom = false;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You are creating a live audio room',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'When you tweet, a live audio room will be created and you\'ll be the host. Others will be able to join your room.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Audio rooms are public and anyone can join',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserDetailsProvider).value;
    final isLoading = ref.watch(tweetControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, size: 20, color: Colors.black),
        ),
        title: const Text(
          'New Tweet',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: sharetweet,
              style: TextButton.styleFrom(
                backgroundColor: tweetTextController.text.isNotEmpty || 
                                 images.isNotEmpty || 
                                 videoFile != null || 
                                 selectedGifUrl != null ||
                                 showPollOptions ||
                                 showAudioRoom ||
                                 locationData != null
                    ? const Color(0xFF1DA1F2)
                    : const Color(0xFF8ECDF8),
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Tweet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: isLoading || currentUser == null
          ? const Loader()
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundImage: CachedNetworkImageProvider(currentUser.profilePic),
                            radius: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: tweetTextController,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                              ),
                              decoration: const InputDecoration(
                                hintText: "What's happening?",
                                hintStyle: TextStyle(
                                  color: Color(0xFF687684),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                              ),
                              maxLines: null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Display selected media
                    if (images.isNotEmpty)
                      _buildImagePreview(),
                    if (videoFile != null)
                      _buildVideoPreview(),
                    if (selectedGifUrl != null)
                      _buildGifPreview(),
                    if (showPollOptions)
                      _buildPollCreator(),
                    if (audioFile != null)
                      _buildAudioPreview(),
                    if (locationData != null)
                      _buildLocationPreview(),
                    if (showAudioRoom)
                      _buildAudioRoomPreview(),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey[200]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Image picker
            IconButton(
              onPressed: onPickImages,
              icon: Icon(
                Icons.photo_outlined,
                color: images.isNotEmpty ? Pallete.blueColor : const Color(0xFF1DA1F2),
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            // GIF picker
            IconButton(
              onPressed: onPickGif,
              icon: Icon(
                Icons.gif_box_outlined,
                color: selectedGifUrl != null ? Pallete.blueColor : const Color(0xFF1DA1F2),
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            // Poll
            IconButton(
              onPressed: togglePollOptions,
              icon: Icon(
                Icons.poll_outlined,
                color: showPollOptions ? Pallete.blueColor : const Color(0xFF1DA1F2),
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            // Video picker
            IconButton(
              onPressed: onPickVideo,
              icon: Icon(
                Icons.videocam_outlined,
                color: videoFile != null ? Pallete.blueColor : const Color(0xFF1DA1F2),
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            // Audio Room - only active for Twitter Blue users
            IconButton(
              onPressed: toggleAudioRoom,
              icon: Icon(
                Icons.spatial_audio_off,
                color: showAudioRoom 
                    ? Pallete.blueColor 
                    : (currentUser?.istweetBlue == true 
                        ? const Color(0xFF1DA1F2) 
                        : Colors.grey),
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            // Location
            IconButton(
              onPressed: toggleLocationPicker,
              icon: Icon(
                Icons.location_on_outlined,
                color: locationData != null ? Pallete.blueColor : const Color(0xFF1DA1F2),
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 200,
      child: CarouselSlider(
        items: images.map(
          (file) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: FileImage(file),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          images.remove(file);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ).toList(),
        options: CarouselOptions(
          height: 200,
          enableInfiniteScroll: false,
          viewportFraction: 0.9,
          enlargeCenterPage: true,
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _videoPreviewController != null && _videoPreviewController!.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _videoPreviewController!.value.aspectRatio,
                    child: VideoPlayer(_videoPreviewController!),
                  )
                : const SizedBox(),
          ),
          GestureDetector(
            onTap: () {
              if (_videoPreviewController != null) {
                if (_videoPreviewController!.value.isPlaying) {
                  _videoPreviewController!.pause();
                } else {
                  _videoPreviewController!.play();
                }
                setState(() {});
              }
            },
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              radius: 25,
              child: Icon(
                _videoPreviewController?.value.isPlaying ?? false
                    ? Icons.pause
                    : Icons.play_arrow,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                _videoPreviewController?.dispose();
                _videoPreviewController = null;
                setState(() {
                  videoFile = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGifPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: selectedGifUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Pallete.blueColor),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.error, color: Colors.grey),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedGifUrl = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'GIF',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollCreator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.poll_outlined,
                    color: Pallete.blueColor,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Poll',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  setState(() {
                    showPollOptions = false;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Poll options
          ...List.generate(pollOptionControllers.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: pollOptionControllers[index],
                      maxLength: 25,
                      style: const TextStyle(fontSize: 16),
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Option ${index + 1}',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Pallete.blueColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (index >= 2)
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(() {
                          pollOptionControllers.removeAt(index);
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            );
          }),
          // Add option button
          if (pollOptionControllers.length < 4)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextButton.icon(
                onPressed: addPollOption,
                icon: const Icon(
                  Icons.add,
                  color: Pallete.blueColor,
                  size: 18,
                ),
                label: const Text(
                  'Add option',
                  style: TextStyle(
                    color: Pallete.blueColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          const Divider(height: 24),
          // Poll duration
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 18,
                color: Pallete.blueColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'Poll length',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<int>(
                      value: pollDurationHours,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: [
                        DropdownMenuItem(value: 1, child: Text('1 hour')),
                        DropdownMenuItem(value: 6, child: Text('6 hours')),
                        DropdownMenuItem(value: 24, child: Text('1 day')),
                        DropdownMenuItem(value: 72, child: Text('3 days')),
                        DropdownMenuItem(value: 168, child: Text('7 days')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            pollDurationHours = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Pallete.blueColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Voice Tweet',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: 0.5,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Pallete.blueColor),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            '0:30',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () {
              setState(() {
                audioFile = null;
              });
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: Colors.grey[100],
              child: Center(
                child: Icon(
                  Icons.map,
                  size: 40,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Pallete.blueColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    locationData!['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  locationData = null;
                  showLocationPicker = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.black87,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
