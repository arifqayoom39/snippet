// ignore_for_file: camel_case_types

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/common/error_page.dart';
import 'package:snippet/common/loading_page.dart';
import 'package:snippet/common/skeleton_loading.dart';
import 'package:snippet/constants/appwrite_constants.dart';
import 'package:snippet/features/tweet/controller/tweet_controller.dart';
import 'package:snippet/features/tweet/widgets/tweet_card.dart';
import 'package:snippet/features/tweet/widgets/who_to_follow.dart';
import 'package:snippet/models/tweet_model.dart';
import 'package:snippet/theme/pallete.dart';

class tweetList extends ConsumerStatefulWidget {
  const tweetList({super.key});

  @override
  ConsumerState<tweetList> createState() => _tweetListState();
}

class _tweetListState extends ConsumerState<tweetList> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;
  bool _showNewTweetsButton = false;
  bool _isScrolled = false;

  // Position to show Who to Follow section (after this many tweets)
  final int _whoToFollowPosition = 5;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    // Show/hide scroll to top button based on scroll position
    if (_scrollController.offset > 500 && !_showScrollToTop) {
      setState(() {
        _showScrollToTop = true;
      });
    } else if (_scrollController.offset <= 500 && _showScrollToTop) {
      setState(() {
        _showScrollToTop = false;
      });
    }

    // Track if user has scrolled down
    if (_scrollController.offset > 100 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    ref.read(paginatedTweetsProvider.notifier).refresh();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tweets = ref.watch(paginatedTweetsProvider);
    final isNewTweetsAvailable = ref.watch(newTweetsAvailableProvider);
    final isLoadingMore = ref.watch(paginatedTweetsProvider.notifier).isLoading;
    final hasMoreTweets = ref.watch(paginatedTweetsProvider.notifier).hasMoreTweets;

    // Show new tweets button if there are new tweets and user has scrolled down
    if (isNewTweetsAvailable && _isScrolled && !_showNewTweetsButton) {
      setState(() {
        _showNewTweetsButton = true;
      });
    }

    // Listen for realtime updates
    ref.listen(getLatestTweetProvider, (previous, next) {
      next.whenData((data) {
        if (data.events.contains(
          'databases.*.collections.${AppwriteConstants.tweetsCollection}.documents.*.create',
        )) {
          final tweet = Tweet.fromMap(data.payload);

          // Add the new tweet to the list if it's not already there
          ref.read(paginatedTweetsProvider.notifier).addNewTweet(tweet);

          // If user has scrolled down, show new tweets button
          if (_isScrolled) {
            ref.read(newTweetsAvailableProvider.notifier).state = true;
            setState(() {
              _showNewTweetsButton = true;
            });
          }
        } else if (data.events.contains(
          'databases.*.collections.${AppwriteConstants.tweetsCollection}.documents.*.update',
        )) {
          // Update the existing tweet
          final tweet = Tweet.fromMap(data.payload);
          ref.read(paginatedTweetsProvider.notifier).updateTweet(tweet);
        }
      });
    });

    if (tweets.isEmpty) {
      return const SkeletonLoading();
    }

    // Calculate the actual item count including the Who to Follow section
    // We'll add +1 for the Who to Follow section and +1 if loading more
    final itemCount = tweets.length +
        (tweets.length > _whoToFollowPosition ? 1 : 0) +
        (isLoadingMore || hasMoreTweets ? 1 : 0);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(paginatedTweetsProvider.notifier).refresh();
        setState(() {
          _showNewTweetsButton = false;
          _isScrolled = false;
        });
      },
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notification) {
              // Load more tweets when nearing the bottom, but only if not already loading
              if (notification is ScrollUpdateNotification) {
                if (_scrollController.position.extentAfter < 500 &&
                    !isLoadingMore &&
                    hasMoreTweets) {
                  ref.read(paginatedTweetsProvider.notifier).getNextBatch();
                }
              }
              return true;
            },
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              itemCount: itemCount,
              itemBuilder: (BuildContext context, int index) {
                // Show the Who to Follow section after a certain number of tweets
                if (tweets.length > _whoToFollowPosition &&
                    index == _whoToFollowPosition) {
                  return const WhoToFollowSection();
                }

                // Adjust index to account for the Who to Follow section
                final tweetIndex = index >= _whoToFollowPosition &&
                        tweets.length > _whoToFollowPosition
                    ? index - 1
                    : index;

                // Show loader at the end of the list when loading more tweets
                if (tweetIndex == tweets.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Pallete.blueColor),
                        ),
                      ),
                    ),
                  );
                }

                final tweet = tweets[tweetIndex];
                return Container(
                  margin: EdgeInsets.only(
                    bottom: tweetIndex == tweets.length - 1 ? 8.0 : 0.0
                  ),
                  child: tweetCard(tweet: tweet),
                );
              },
            ),
          ),

          // Show scroll to top button
          if (_showScrollToTop)
            Positioned(
              bottom: 20,
              right: 20,
              child: AnimatedOpacity(
                opacity: _showScrollToTop ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Pallete.backgroundColor,
                  elevation: 4.0,
                  onPressed: _scrollToTop,
                  child: Icon(
                    Icons.arrow_upward,
                    color: Pallete.textColor,
                    size: 20,
                  ),
                ),
              ),
            ),

          // Show new tweets available button
          if (_showNewTweetsButton)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  elevation: 6,
                  shadowColor: Colors.black26,
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () {
                      _scrollToTop();
                      setState(() {
                        _showNewTweetsButton = false;
                        _isScrolled = false;
                      });
                      ref.read(newTweetsAvailableProvider.notifier).state = false;
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14, 
                        vertical: 8
                      ),
                      decoration: BoxDecoration(
                        color: Pallete.blueColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_upward_rounded,
                            color: Pallete.whiteColor,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'New tweets',
                            style: TextStyle(
                              color: Pallete.whiteColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
