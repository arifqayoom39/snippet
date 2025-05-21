// ignore_for_file: deprecated_member_use

import 'package:any_link_preview/any_link_preview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:like_button/like_button.dart';
import 'package:snippet/common/common.dart';
import 'package:snippet/common/skeleton_loading.dart';
import 'package:snippet/constants/assets_constants.dart';
import 'package:snippet/core/enums/tweet_type_enum.dart';
import 'package:snippet/features/audio_room/views/audio_room_screen.dart';
import 'package:snippet/features/auth/controller/auth_controller.dart';
import 'package:snippet/features/bookmark/controller/bookmark_controller.dart';
import 'package:snippet/features/tweet/controller/tweet_controller.dart';
import 'package:snippet/features/tweet/views/twitter_reply_view.dart';
import 'package:snippet/features/tweet/views/quote_tweet_view.dart';
import 'package:snippet/features/tweet/views/media_view_screen.dart';
import 'package:snippet/features/tweet/widgets/carousel_image.dart';
import 'package:snippet/features/tweet/widgets/hashtag_text.dart';
import 'package:snippet/features/tweet/widgets/tweet_icon_button.dart';
import 'package:snippet/features/user_profile/view/user_profile_view.dart';
import 'package:snippet/models/tweet_model.dart';
import 'package:snippet/models/user_model.dart';
import 'package:snippet/theme/pallete.dart';
import 'package:timeago/timeago.dart' as timeago;

class tweetCard extends ConsumerWidget {
  final Tweet tweet;
  final bool isQuoted;

  const tweetCard({
    super.key,
    required this.tweet,
    this.isQuoted = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserDetailsProvider).value;
    final isDarkMode = ref.watch(themeProvider);

    return currentUser == null
        ? const SizedBox()
        : ref.watch(userDetailsProvider(tweet.uid)).when(
              data: (user) {
                final formattedTime = _getFormattedTimeAgo(tweet.tweetedAt);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      tweetReplyScreen.route(tweet),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: isQuoted
                          ? Border.all(color: Pallete.greyColor.withOpacity(0.3), width: 1)
                          : Border(
                              bottom: BorderSide(
                                color: Pallete.greyColor.withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                      borderRadius: isQuoted ? BorderRadius.circular(12) : null,
                    ),
                    margin: isQuoted ? const EdgeInsets.only(top: 8, bottom: 8) : null,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: isQuoted ? 8.0 : 5.0,
                        horizontal: isQuoted ? 8.0 : 0.0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      UserProfileView.route(user),
                                    );
                                  },
                                  child: CircleAvatar(
                                    radius: isQuoted ? 15 : 20,
                                    backgroundImage: CachedNetworkImageProvider(user.profilePic),
                                  ),
                                ),
                              ),
                              if (tweet.retweetedBy.isNotEmpty && !isQuoted)
                                Container(
                                  width: 2,
                                  height: 50,
                                  margin: const EdgeInsets.only(left: 12),
                                  color: Pallete.greyColor.withOpacity(0.3),
                                ),
                            ],
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (tweet.retweetedBy.isNotEmpty && !isQuoted)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2.0),
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          AssetsConstants.retweetIcon,
                                          colorFilter: ColorFilter.mode(Pallete.greyColor, BlendMode.srcIn),
                                          height: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${tweet.retweetedBy} remixed',
                                          style: TextStyle(
                                            color: Pallete.greyColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Row(
                                  children: [
                                    Text(
                                      user.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isQuoted ? 14 : 15,
                                        color: Pallete.textColor,
                                      ),
                                    ),
                                    if (user.istweetBlue)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 2.0),
                                        child: SvgPicture.asset(
                                          AssetsConstants.verifiedIcon,
                                          width: isQuoted ? 12 : 14,
                                          height: isQuoted ? 12 : 14,
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4.0),
                                      child: Text(
                                        '@${user.username.isNotEmpty ? user.username : user.name} · $formattedTime',
                                        style: TextStyle(
                                          color: Pallete.greyColor,
                                          fontSize: isQuoted ? 13 : 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (tweet.repliedTo.isNotEmpty)
                                  ref.watch(getTweetByIdProvider(tweet.repliedTo)).when(
                                        data: (repliedTotweet) {
                                          final replyingToUserAsync = ref.watch(
                                            userDetailsProvider(repliedTotweet.uid),
                                          );

                                          return replyingToUserAsync.when(
                                            data: (replyingToUser) {
                                              if (replyingToUser == null) {
                                                return const Padding(
                                                  padding: EdgeInsets.only(top: 1.0),
                                                  child: Text(
                                                    'Replying to tweet',
                                                    style: TextStyle(
                                                      color: Pallete.greyColor,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                );
                                              }

                                              final username = replyingToUser.username.isNotEmpty
                                                  ? replyingToUser.username
                                                  : replyingToUser.name;

                                              return Padding(
                                                padding: const EdgeInsets.only(top: 1.0),
                                                child: RichText(
                                                  text: TextSpan(
                                                    text: 'Replying to',
                                                    style: TextStyle(
                                                      color: Pallete.greyColor,
                                                      fontSize: 14,
                                                    ),
                                                    children: [
                                                      TextSpan(
                                                        text: ' @$username',
                                                        style: TextStyle(
                                                          color: Pallete.blueColor,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                            loading: () => const Padding(
                                              padding: EdgeInsets.only(top: 1.0),
                                              child: Text(
                                                'Loading reply info...',
                                                style: TextStyle(
                                                  color: Pallete.greyColor,
                                                  fontSize: 14,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                            error: (error, _) => Padding(
                                              padding: const EdgeInsets.only(top: 1.0),
                                              child: Text(
                                                'Replying to tweet',
                                                style: TextStyle(
                                                  color: Pallete.greyColor,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        error: (error, st) => Padding(
                                          padding: const EdgeInsets.only(top: 1.0),
                                          child: Text(
                                            'Replying to tweet',
                                            style: TextStyle(
                                              color: Pallete.greyColor,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        loading: () => const Padding(
                                          padding: EdgeInsets.only(top: 1.0),
                                          child: Text(
                                            'Loading...',
                                            style: TextStyle(
                                              color: Pallete.greyColor,
                                              fontSize: 14,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0, right: 8.0),
                                  child: HashtagText(
                                    text: tweet.text,
                                    fontSize: isQuoted ? 14 : 15,
                                    textColor: Pallete.textColor,
                                  ),
                                ),
                                if (tweet.quotedTweetId.isNotEmpty)
                                  Consumer(
                                    builder: (context, ref, child) {
                                      return ref.watch(getTweetByIdProvider(tweet.quotedTweetId)).when(
                                        data: (quotedTweet) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                                            child: tweetCard(
                                              tweet: quotedTweet,
                                              isQuoted: true,
                                            ),
                                          );
                                        },
                                        loading: () => const Padding(
                                          padding: EdgeInsets.only(top: 8.0, right: 8.0),
                                          child: Center(
                                            child: SizedBox(
                                              height: 50,
                                              width: 50,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                        error: (error, _) => Padding(
                                          padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Pallete.greyColor.withOpacity(0.3)),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text('Tweet unavailable'),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                if (tweet.tweetType == TweetType.image)
                                  _buildImageContent(context, tweet),
                                if (tweet.tweetType == TweetType.video)
                                  _buildVideoContent(context, tweet),
                                if (tweet.tweetType == TweetType.gif)
                                  _buildGifContent(context, tweet),
                                if (tweet.tweetType == TweetType.poll && tweet.pollOptions != null)
                                  _buildPollContent(context, ref, tweet),
                                if (tweet.tweetType == TweetType.audio)
                                  _buildAudioContent(context, tweet),
                                if (tweet.tweetType == TweetType.location && tweet.locationData != null)
                                  _buildLocationContent(context, tweet),
                                if (tweet.tweetType == TweetType.audioRoom)
                                  _buildAudioRoomContent(context, tweet, ref, currentUser),
                                if (tweet.link.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Pallete.greyColor.withOpacity(0.3),
                                      ),
                                    ),
                                    margin: const EdgeInsets.only(right: 16.0),
                                    child: AnyLinkPreview(
                                      displayDirection:
                                          UIDirection.uiDirectionHorizontal,
                                      link: 'https://${tweet.link}',
                                      borderRadius: 12,
                                    ),
                                  ),
                                ],
                                if (!isQuoted)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5.0, right: 16.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        tweetIconButton(
                                          pathName: AssetsConstants.viewsIcon,
                                          text: (tweet.commentIds.length +
                                                  tweet.reshareCount +
                                                  tweet.likes.length)
                                              .toString(),
                                          onTap: () {},
                                          fontSize: 14,
                                          color: Pallete.greyColor,
                                        ),
                                        tweetIconButton(
                                          pathName: AssetsConstants.commentIcon,
                                          text: tweet.commentIds.length.toString(),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              tweetReplyScreen.route(tweet),
                                            );
                                          },
                                          fontSize: 14,
                                          color: Pallete.greyColor,
                                        ),
                                        tweetIconButton(
                                          pathName: AssetsConstants.retweetIcon,
                                          text: tweet.reshareCount.toString(),
                                          onTap: () {
                                            _showRetweetOptions(context, ref, tweet, currentUser);
                                          },
                                          fontSize: 14,
                                          color: Pallete.greyColor,
                                        ),
                                        LikeButton(
                                          size: 20,
                                          onTap: (isLiked) async {
                                            ref
                                                .read(tweetControllerProvider
                                                    .notifier)
                                                .likeTweet(
                                                  tweet,
                                                  currentUser,
                                                );
                                            return !isLiked;
                                          },
                                          isLiked: tweet.likes
                                              .contains(currentUser.uid),
                                          likeBuilder: (isLiked) {
                                            return isLiked
                                                ? SvgPicture.asset(
                                                    AssetsConstants
                                                        .likeFilledIcon,
                                                    color: Pallete.redColor,
                                                  )
                                                : SvgPicture.asset(
                                                    AssetsConstants
                                                        .likeOutlinedIcon,
                                                    color: Pallete.greyColor,
                                                  );
                                          },
                                          likeCount: tweet.likes.length,
                                          countBuilder:
                                              (likeCount, isLiked, text) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 2.0),
                                              child: Text(
                                                text,
                                                style: TextStyle(
                                                  color: isLiked
                                                      ? Pallete.redColor
                                                      : Pallete.greyColor,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        _buildBookmarkButton(context, ref, tweet.id),
                                        IconButton(
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                          onPressed: () {
                                            _showShareOptions(context, tweet);
                                          },
                                          icon: const Icon(
                                            Icons.share_outlined,
                                            size: 18,
                                            color: Pallete.greyColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              error: (error, stackTrace) => ErrorText(
                error: error.toString(),
              ),
              loading: () => const SkeletonTweetCard(index: 0),
            );
  }

  Widget _buildBookmarkButton(BuildContext context, WidgetRef ref, String tweetId) {
    return Consumer(
      builder: (context, ref, child) {
        final isBookmarked = ref.watch(isBookmarkedProvider(tweetId));

        return isBookmarked.when(
          data: (isBookmarked) {
            return GestureDetector(
              onTap: () {
                ref.read(bookmarkControllerProvider.notifier).toggleBookmark(
                  tweetId,
                  context,
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? Pallete.blueColor : Pallete.greyColor,
                  size: 18,
                ),
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(6.0),
            child: Icon(
              Icons.bookmark_border,
              color: Pallete.greyColor,
              size: 18,
            ),
          ),
          error: (_, __) => const Padding(
            padding: EdgeInsets.all(6.0),
            child: Icon(
              Icons.bookmark_border,
              color: Pallete.greyColor,
              size: 18,
            ),
          ),
        );
      },
    );
  }

  void _showRetweetOptions(BuildContext context, WidgetRef ref, Tweet tweet, UserModel currentUser) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Pallete.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.repeat,
                  color: Pallete.blueColor,
                ),
                title: const Text(
                  'Retweet',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(tweetControllerProvider.notifier)
                      .reshareTweet(
                        tweet,
                        currentUser,
                        context,
                      );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.chat_bubble_outline,
                  color: Pallete.blueColor,
                ),
                title: const Text(
                  'Quote Tweet',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, QuoteTweetView.route(tweet));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showShareOptions(BuildContext context, Tweet tweet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Pallete.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.link,
                  color: Pallete.blueColor,
                ),
                title: const Text(
                  'Copy link to Tweet',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link copied to clipboard'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.share,
                  color: Pallete.blueColor,
                ),
                title: const Text(
                  'Share via...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openMediaFullScreen(BuildContext context, List<String> urls, int initialIndex, MediaType mediaType) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaViewScreen(
          mediaUrls: urls,
          initialIndex: initialIndex,
          mediaType: mediaType,
        ),
      ),
    );
  }

  String _getFormattedTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    final isToday = dateTime.day == now.day && 
                    dateTime.month == now.month && 
                    dateTime.year == now.year;
    
    if (isToday) {
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour == 0 ? 12 : dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } else if (difference.inHours < 24 && difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else if (dateTime.year == now.year) {
      return '${_getMonthAbbr(dateTime.month)} ${dateTime.day}';
    } else {
      return '${_getMonthAbbr(dateTime.month)} ${dateTime.day}, ${dateTime.year}';
    }
  }

  String _getMonthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildImageContent(BuildContext context, Tweet tweet) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, right: 16.0),
      child: tweet.imageLinks.length > 1
          ? GestureDetector(
              onTap: () {
                _openMediaFullScreen(context, tweet.imageLinks, 0, MediaType.image);
              },
              child: CarouselImage(
                imageLinks: tweet.imageLinks,
                onImageTap: (index) {
                  _openMediaFullScreen(context, tweet.imageLinks, index, MediaType.image);
                },
              ),
            )
          : GestureDetector(
              onTap: () {
                _openMediaFullScreen(context, tweet.imageLinks, 0, MediaType.image);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: CachedNetworkImage(
                    imageUrl: tweet.imageLinks.first,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(
                          color: Pallete.greyColor.withOpacity(0.3),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Pallete.blueColor,
                            ),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) =>
                            const Icon(Icons.error),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildVideoContent(BuildContext context, Tweet tweet) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, right: 16.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MediaViewScreen(
                mediaUrl: tweet.videoUrl,
                mediaType: MediaType.video,
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: 200,
            color: Pallete.greyColor.withOpacity(0.2),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.play_circle_fill,
                  size: 50,
                  color: Pallete.whiteColor.withOpacity(0.8),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Video',
                      style: TextStyle(
                        color: Pallete.whiteColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGifContent(BuildContext context, Tweet tweet) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, right: 16.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MediaViewScreen(
                mediaUrl: tweet.gifUrl,
                mediaType: MediaType.gif,
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: 200,
            child: CachedNetworkImage(
              imageUrl: tweet.gifUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Pallete.greyColor.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Pallete.blueColor,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Pallete.greyColor.withOpacity(0.3),
                child: const Center(
                  child: Text('GIF'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPollContent(BuildContext context, WidgetRef ref, Tweet tweet) {
    final isPollEnded = tweet.pollEndTime != null && 
                       DateTime.now().isAfter(tweet.pollEndTime!);
    
    final currentUser = ref.watch(currentUserDetailsProvider).value;
    bool hasVoted = false;
    int? userVotedIndex;
    
    if (currentUser != null && tweet.pollOptions != null) {
      for (int i = 0; i < tweet.pollOptions!.length; i++) {
        final votes = (tweet.pollOptions![i]['votes'] as List<dynamic>);
        if (votes.contains(currentUser.uid)) {
          hasVoted = true;
          userVotedIndex = i;
          break;
        }
      }
    }
    
    int totalVotes = 0;
    if (tweet.pollOptions != null) {
      for (final option in tweet.pollOptions!) {
        totalVotes += (option['votes'] as List).length;
      }
    }
    
    String timeLeft = '';
    if (tweet.pollEndTime != null) {
      if (isPollEnded) {
        timeLeft = 'Final results';
      } else {
        final duration = tweet.pollEndTime!.difference(DateTime.now());
        if (duration.inDays > 0) {
          timeLeft = '${duration.inDays}d left';
        } else if (duration.inHours > 0) {
          timeLeft = '${duration.inHours}h left';
        } else if (duration.inMinutes > 0) {
          timeLeft = '${duration.inMinutes}m left';
        } else {
          timeLeft = 'Ending soon';
        }
      }
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, right: 16.0, bottom: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Pallete.greyColor.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tweet.pollOptions != null)
              ...List.generate(tweet.pollOptions!.length, (index) {
                final option = tweet.pollOptions![index];
                final votes = (option['votes'] as List).length;
                final percentage = totalVotes > 0 ? (votes / totalVotes * 100).round() : 0;
                final isWinning = totalVotes > 0 && votes == tweet.pollOptions!
                    .map((o) => (o['votes'] as List).length)
                    .reduce((a, b) => a > b ? a : b);
                
                return GestureDetector(
                  onTap: () {
                    if (!hasVoted && !isPollEnded) {
                      ref.read(tweetControllerProvider.notifier).votePoll(
                        tweet: tweet,
                        optionIndex: index,
                        context: context,
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Stack(
                      children: [
                        // Option container with background
                        Container(
                          width: double.infinity,
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: userVotedIndex == index 
                                  ? Pallete.blueColor.withOpacity(0.5) 
                                  : Pallete.greyColor.withOpacity(0.3),
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        
                        // Filled progress bar
                        if (hasVoted || isPollEnded)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutQuint,
                            height: 40,
                            width: MediaQuery.of(context).size.width * 
                                (percentage / 100) * 0.7,
                            decoration: BoxDecoration(
                              color: userVotedIndex == index
                                  ? Pallete.blueColor.withOpacity(0.2)
                                  : isWinning
                                      ? Pallete.blueColor.withOpacity(0.1)
                                      : Pallete.greyColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        
                        // Content (text and percentage)
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    option['text'],
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: userVotedIndex == index || isWinning ? 
                                          FontWeight.w600 : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (hasVoted || isPollEnded)
                                  Row(
                                    children: [
                                      Text(
                                        '$percentage%',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: isWinning ? Pallete.blueColor : Pallete.greyColor,
                                        ),
                                      ),
                                      if (userVotedIndex == index)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4.0),
                                          child: Icon(
                                            Icons.check_circle,
                                            color: Pallete.blueColor,
                                            size: 16,
                                          ),
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Row(
                children: [
                  Text(
                    totalVotes > 0 ? 
                        '$totalVotes ${totalVotes == 1 ? 'vote' : 'votes'}' : 
                        isPollEnded ? 'No votes' : 'Vote now',
                    style: TextStyle(
                      color: Pallete.greyColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      if (!isPollEnded)
                        Icon(
                          Icons.schedule,
                          size: 13,
                          color: Pallete.greyColor,
                        ),
                      const SizedBox(width: 3),
                      Text(
                        timeLeft,
                        style: TextStyle(
                          color: Pallete.greyColor,
                          fontSize: 13,
                          fontWeight: isPollEnded ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!hasVoted && !isPollEnded)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Tap an option to vote',
                  style: TextStyle(
                    color: Pallete.blueColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioContent(BuildContext context, Tweet tweet) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, right: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Pallete.greyColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.play_circle_filled,
              color: Pallete.blueColor,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voice message',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: LinearProgressIndicator(
                        value: 0,
                        backgroundColor: Pallete.greyColor.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(Pallete.blueColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '0:00',
              style: TextStyle(
                color: Pallete.greyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationContent(BuildContext context, Tweet tweet) {
    final locationName = tweet.locationData?['name'] ?? 'Location';
    
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, right: 16.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Pallete.greyColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        height: 120,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Container(
                color: Pallete.greyColor.withOpacity(0.2),
                width: double.infinity,
              ),
              Center(
                child: Icon(
                  Icons.map,
                  size: 40,
                  color: Pallete.blueColor.withOpacity(0.7),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black.withOpacity(0.6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Pallete.whiteColor,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        locationName,
                        style: TextStyle(
                          color: Pallete.whiteColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioRoomContent(BuildContext context, Tweet tweet, WidgetRef ref, UserModel currentUser) {
    final isActive = tweet.isAudioRoomActive;
    final participantCount = tweet.audioRoomParticipants.length;
    
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, right: 16.0, bottom: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: isActive ? Pallete.blueColor.withOpacity(0.5) : Pallete.greyColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
          color: isActive ? Pallete.blueColor.withOpacity(0.1) : null,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.spatial_audio,
                  color: isActive ? Pallete.blueColor : Pallete.greyColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isActive ? 'Live Audio Room' : 'Audio Room (Ended)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isActive ? Pallete.blueColor : Pallete.greyColor,
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.people,
                  color: Pallete.greyColor,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '$participantCount ${participantCount == 1 ? 'participant' : 'participants'}',
                  style: TextStyle(
                    color: Pallete.greyColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isActive)
              ElevatedButton(
                onPressed: () {
                  // Navigate to audio room without passing user details explicitly
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AudioRoomScreen(
                        audioRoomId: tweet.audioRoomId,
                        isHost: tweet.uid == currentUser.uid,
                        tweetCreatorUid: tweet.uid,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Pallete.blueColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Join Room',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
