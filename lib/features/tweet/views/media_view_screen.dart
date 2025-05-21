import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:snippet/theme/pallete.dart';

enum MediaType { image, video, gif }

class MediaViewScreen extends StatefulWidget {
  final String? mediaUrl;
  final List<String>? mediaUrls;
  final int initialIndex;
  final MediaType mediaType;

  const MediaViewScreen({
    Key? key,
    this.mediaUrl,
    this.mediaUrls,
    this.initialIndex = 0,
    required this.mediaType,
  }) : assert(mediaUrl != null || mediaUrls != null),
       super(key: key);

  @override
  State<MediaViewScreen> createState() => _MediaViewScreenState();
}

class _MediaViewScreenState extends State<MediaViewScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  int _currentIndex = 0;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn)
    );
    
    _animationController.forward();

    if (widget.mediaType == MediaType.video && widget.mediaUrl != null) {
      _initializeVideoPlayer(widget.mediaUrl!);
    }

    // Set preferred orientations to allow landscape for videos
    if (widget.mediaType == MediaType.video) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  Future<void> _initializeVideoPlayer(String videoUrl) async {
    setState(() {
      _isLoading = true;
    });
    
    _videoController = VideoPlayerController.network(videoUrl);
    
    try {
      await _videoController!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        showControlsOnInitialize: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: Pallete.blueColor,
          handleColor: Pallete.blueColor,
          backgroundColor: Colors.grey.shade800,
          bufferedColor: Colors.grey.shade500,
        ),
        placeholder: Center(
          child: CircularProgressIndicator(
            color: Pallete.blueColor,
            strokeWidth: 2,
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 30),
                const SizedBox(height: 8),
                const Text(
                  'Unable to play video',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  errorMessage,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print("Error initializing video: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    _animationController.dispose();
    
    // Reset preferred orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white),
          ),
        ),
        actions: [
          if (widget.mediaType == MediaType.video || widget.mediaType == MediaType.gif)
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.share_outlined, size: 20),
                color: Colors.white,
                onPressed: () {
                  // Implement share functionality here
                },
              ),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _opacityAnimation,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // Single media display (video or GIF)
    if (widget.mediaUrl != null) {
      if (widget.mediaType == MediaType.video) {
        return _buildVideoPlayer();
      } else if (widget.mediaType == MediaType.gif) {
        return _buildGifViewer(widget.mediaUrl!);
      }
    }

    // Multiple images in a PageView
    if (widget.mediaUrls != null && widget.mediaType == MediaType.image) {
      return Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.mediaUrls!.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildImageViewer(widget.mediaUrls![index]);
            },
          ),
          if (widget.mediaUrls!.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.mediaUrls!.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _currentIndex == index ? 8 : 6,
                    height: _currentIndex == index ? 8 : 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Pallete.blueColor
                          : Colors.grey.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ),
          // Counter indicator like Twitter
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            right: 0,
            left: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${_currentIndex + 1}/${widget.mediaUrls!.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return const Center(child: Text('No media to display', style: TextStyle(color: Colors.white)));
  }

  Widget _buildVideoPlayer() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Pallete.blueColor,
              strokeWidth: 2,
            ),
            const SizedBox(height: 10),
            Text(
              'Loading video...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (_chewieController != null) {
      return Center(
        child: Chewie(
          controller: _chewieController!,
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.error_outline, color: Colors.white, size: 30),
          SizedBox(height: 8),
          Text(
            'Error loading video',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageViewer(String imageUrl) {
    return GestureDetector(
      onTap: () {
        // Toggle AppBar visibility
        // This would require additional state management
      },
      child: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4,
          child: Hero(
            tag: imageUrl,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              placeholder: (context, url) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Pallete.blueColor,
                      strokeWidth: 2,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Loading image...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              errorWidget: (context, url, error) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 30,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Unable to load image',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGifViewer(String gifUrl) {
    return Center(
      child: InteractiveViewer(
        panEnabled: true,
        boundaryMargin: const EdgeInsets.all(20),
        minScale: 0.5,
        maxScale: 2,
        child: CachedNetworkImage(
          imageUrl: gifUrl,
          placeholder: (context, url) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: Pallete.blueColor,
                  strokeWidth: 2,
                ),
                const SizedBox(height: 10),
                Text(
                  'Loading GIF...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          errorWidget: (context, url, error) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 30,
              ),
              SizedBox(height: 8),
              Text(
                'Unable to load GIF',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
