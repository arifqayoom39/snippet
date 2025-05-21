import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:snippet/common/loading_page.dart';
import 'package:snippet/common/rounded_small_button.dart';
import 'package:snippet/constants/assets_constants.dart';
import 'package:snippet/core/utils.dart';
import 'package:snippet/features/auth/controller/auth_controller.dart';
import 'package:snippet/features/tweet/controller/tweet_controller.dart';
import 'package:snippet/features/tweet/widgets/tweet_card.dart';
import 'package:snippet/models/tweet_model.dart';
import 'package:snippet/theme/pallete.dart';

class QuoteTweetView extends ConsumerStatefulWidget {
  static route(Tweet quotedTweet) => MaterialPageRoute(
        builder: (context) => QuoteTweetView(quotedTweet: quotedTweet),
      );
      
  final Tweet quotedTweet;
  
  const QuoteTweetView({
    Key? key,
    required this.quotedTweet,
  }) : super(key: key);

  @override
  ConsumerState<QuoteTweetView> createState() => _QuoteTweetViewState();
}

class _QuoteTweetViewState extends ConsumerState<QuoteTweetView> {
  final tweetTextController = TextEditingController();
  List<File> images = [];
  bool isLoading = false;

  @override
  void dispose() {
    tweetTextController.dispose();
    super.dispose();
  }

  void shareTweet() async {
    setState(() {
      isLoading = true;
    });
    
    final res = await ref.read(tweetControllerProvider.notifier).quoteTweet(
      images: images,
      text: tweetTextController.text,
      context: context,
      quotedTweet: widget.quotedTweet,
    );
    
    setState(() {
      isLoading = false;
    });
    
    if (res && mounted) {
      Navigator.pop(context);
    }
  }

  void onPickImages() async {
    images = await pickImages();
    setState(() {});
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
          'Quote Tweet',
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
              onPressed: shareTweet,
              style: TextButton.styleFrom(
                backgroundColor: tweetTextController.text.isNotEmpty || images.isNotEmpty
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
                                hintText: "Add a comment!",
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
                    
                    // Display selected images
                    if (images.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                      ),
                    
                    // Quoted tweet
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey[300]!,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: tweetCard(
                          tweet: widget.quotedTweet,
                          isQuoted: true,
                        ),
                      ),
                    ),
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
          children: [
            const SizedBox(width: 10),
            // Image picker
            IconButton(
              onPressed: onPickImages,
              icon: Icon(
                Icons.photo_outlined,
                color: images.isNotEmpty ? Pallete.blueColor : const Color(0xFF1DA1F2),
                size: 22,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 10),
            // GIF picker
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.gif_box_outlined,
                color: const Color(0xFF1DA1F2),
                size: 22,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 10),
            // Video picker - added back
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.videocam_outlined,
                color: const Color(0xFF1DA1F2),
                size: 22,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const Spacer(),
            Container(
              height: 28,
              width: 28,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF1DA1F2),
                  width: 1.5,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Color(0xFF1DA1F2),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
