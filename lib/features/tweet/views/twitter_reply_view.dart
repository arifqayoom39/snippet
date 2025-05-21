// ignore_for_file: camel_case_types

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:snippet/common/common.dart';
import 'package:snippet/constants/appwrite_constants.dart';
import 'package:snippet/features/tweet/controller/tweet_controller.dart';
import 'package:snippet/features/tweet/widgets/tweet_card.dart';
import 'package:snippet/models/tweet_model.dart';
import 'package:snippet/theme/pallete.dart';

class tweetReplyScreen extends ConsumerWidget {
  static route(Tweet tweet) => MaterialPageRoute(
        builder: (context) => tweetReplyScreen(
          tweet: tweet,
        ),
      );
  final Tweet tweet;
  const tweetReplyScreen({
    super.key,
    required this.tweet,
  });

  // Add method for opening images in full screen
  void _openImagesFullScreen(BuildContext context, List<String> imageUrls, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4,
                  child: CachedNetworkImage(
                    imageUrl: imageUrls[index],
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        color: Pallete.blueColor,
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.error,
                      color: Colors.white,
                      size: 50,
                    ),
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tweetTextController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('tweet'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    tweetCard(tweet: tweet),
                    ref.watch(getRepliesToTweetsProvider(tweet)).when(
                          data: (tweets) {
                            return ref.watch(getLatestTweetProvider).when(
                                  data: (data) {
                                    final latesttweet = Tweet.fromMap(data.payload);

                                    bool istweetAlreadyPresent = false;
                                    for (final tweetModel in tweets) {
                                      if (tweetModel.id == latesttweet.id) {
                                        istweetAlreadyPresent = true;
                                        break;
                                      }
                                    }

                                    if (!istweetAlreadyPresent &&
                                        latesttweet.repliedTo == tweet.id) {
                                      if (data.events.contains(
                                        'databases.*.collections.${AppwriteConstants.tweetsCollection}.documents.*.create',
                                      )) {
                                        tweets.insert(0, Tweet.fromMap(data.payload));
                                      } else if (data.events.contains(
                                        'databases.*.collections.${AppwriteConstants.tweetsCollection}.documents.*.update',
                                      )) {
                                        final startingPoint =
                                            data.events[0].lastIndexOf('documents.');
                                        final endPoint =
                                            data.events[0].lastIndexOf('.update');
                                        final tweetId = data.events[0]
                                            .substring(startingPoint + 10, endPoint);

                                        var tweet = tweets
                                            .where((element) => element.id == tweetId)
                                            .first;

                                        final tweetIndex = tweets.indexOf(tweet);
                                        tweets.removeWhere(
                                            (element) => element.id == tweetId);

                                        tweet = Tweet.fromMap(data.payload);
                                        tweets.insert(tweetIndex, tweet);
                                      }
                                    }

                                    return ListView.builder(
                                      shrinkWrap: true, // Add this to allow ListView inside a Column
                                      physics: const NeverScrollableScrollPhysics(), // Prevent ListView from scrolling independently
                                      itemCount: tweets.length,
                                      itemBuilder: (BuildContext context, int index) {
                                        final tweet = tweets[index];
                                        return tweetCard(tweet: tweet);
                                      },
                                    );
                                  },
                                  error: (error, stackTrace) => ErrorText(
                                    error: error.toString(),
                                  ),
                                  loading: () {
                                    return ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: tweets.length,
                                      itemBuilder: (BuildContext context, int index) {
                                        final tweet = tweets[index];
                                        return tweetCard(tweet: tweet);
                                      },
                                    );
                                  },
                                );
                          },
                          error: (error, stackTrace) => ErrorText(
                            error: error.toString(),
                          ),
                          loading: () => const Loader(),
                        ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Pallete.greyColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: tweetTextController,
                        onSubmitted: (value) {
                          final text = tweetTextController.text.trim();
                          if (text.isNotEmpty) {
                            ref.read(tweetControllerProvider.notifier).shareTweet(
                              images: [],
                              text: text,
                              context: context,
                              repliedTo: tweet.id,
                              repliedToUserId: tweet.uid,
                            );
                            Navigator.pop(context);
                          }
                        },
                        decoration: const InputDecoration(
                          hintText: 'tweet your reply...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Pallete.blueColor,
                    ),
                    child: IconButton(
                      onPressed: () {
                        final text = tweetTextController.text.trim();
                        if (text.isNotEmpty) {
                          ref.read(tweetControllerProvider.notifier).shareTweet(
                            images: [],
                            text: text,
                            context: context,
                            repliedTo: tweet.id,
                            repliedToUserId: tweet.uid,
                          );
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: true,
    );
  }
}
