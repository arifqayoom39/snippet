import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/apis/storage_api.dart';
import 'package:snippet/apis/tweet_api.dart';
import 'package:snippet/core/enums/notification_type_enum.dart';
import 'package:snippet/core/enums/tweet_type_enum.dart';
import 'package:snippet/core/recommendation/recommendation_service.dart'; // Add this import
import 'package:snippet/core/utils.dart';
import 'package:snippet/features/auth/controller/auth_controller.dart';
import 'package:snippet/features/notifications/controller/notification_controller.dart';
import 'package:snippet/models/tweet_model.dart';
import 'package:snippet/models/user_model.dart';

final tweetControllerProvider = StateNotifierProvider<TweetController, bool>(
  (ref) {
    return TweetController(
      ref: ref,
      tweetAPI: ref.watch(tweetAPIProvider),
      storageAPI: ref.watch(storageAPIProvider),
      notificationController: ref.watch(notificationControllerProvider.notifier),
    );
  },
);

final getTweetsProvider = FutureProvider((ref) {
  final tweetController = ref.watch(tweetControllerProvider.notifier);
  return tweetController.getTweets();
});

final newTweetsAvailableProvider = StateProvider<bool>((ref) => false);

final paginatedTweetsProvider = StateNotifierProvider<PaginatedTweetsNotifier, List<Tweet>>((ref) {
  return PaginatedTweetsNotifier(
    ref: ref,
    tweetAPI: ref.watch(tweetAPIProvider),
  );
});

final getRepliesToTweetsProvider = FutureProvider.family((ref, Tweet tweet) {
  final tweetController = ref.watch(tweetControllerProvider.notifier);
  return tweetController.getRepliesToTweet(tweet);
});

final getLatestTweetProvider = StreamProvider((ref) {
  final tweetAPI = ref.watch(tweetAPIProvider);
  return tweetAPI.getLatesttweet();
});

final getTweetByIdProvider = FutureProvider.family((ref, String id) async {
  final tweetController = ref.watch(tweetControllerProvider.notifier);
  return tweetController.getTweetById(id);
});

final getTweetsByHashtagProvider = FutureProvider.family((ref, String hashtag) async {
  final tweetController = ref.watch(tweetControllerProvider.notifier);
  return tweetController.getTweetsByHashtag(hashtag);
});

final searchTweetsProvider = FutureProvider.family((ref, String query) {
  final tweetController = ref.watch(tweetControllerProvider.notifier);
  return tweetController.searchTweets(query);
});

// Add this provider to get ranked tweets
final rankedTweetsProvider = FutureProvider.autoDispose((ref) async {
  final tweetController = ref.watch(tweetControllerProvider.notifier);
  return tweetController.getRankedTweets();
});

class PaginatedTweetsNotifier extends StateNotifier<List<Tweet>> {
  final TweetAPI _tweetAPI;
  final Ref _ref;
  int _currentPage = 0;
  final int _tweetsPerPage = 5;
  bool _isLoading = false;
  bool _hasMoreTweets = true;

  PaginatedTweetsNotifier({
    required Ref ref,
    required TweetAPI tweetAPI,
  }) : _ref = ref,
       _tweetAPI = tweetAPI,
       super([]) {
    getNextBatch();
  }

  Future<void> getNextBatch() async {
    if (_isLoading || !_hasMoreTweets) return;
    
    _isLoading = true;
    // Notify UI we're loading to show the loader
    state = [...state];
    
    final tweetList = await _tweetAPI.gettweets(
      limit: _tweetsPerPage, 
      offset: _currentPage * _tweetsPerPage
    );
    
    final tweets = tweetList.map((tweet) => Tweet.fromMap(tweet.data)).toList();
    
    if (tweets.length < _tweetsPerPage) {
      _hasMoreTweets = false;
    }
    
    state = [...state, ...tweets];
    _currentPage++;
    _isLoading = false;
  }

  Future<void> refresh() async {
    _isLoading = true;
    _currentPage = 0;
    _hasMoreTweets = true;
    
    // Clear the list and show loader
    state = [];
    
    final tweetList = await _tweetAPI.gettweets(
      limit: _tweetsPerPage, 
      offset: 0
    );
    
    final tweets = tweetList.map((tweet) => Tweet.fromMap(tweet.data)).toList();
    
    if (tweets.length < _tweetsPerPage) {
      _hasMoreTweets = false;
    }
    
    state = tweets;
    _currentPage = 1;
    _isLoading = false;
    
    // Reset new tweets indicator
    _ref.read(newTweetsAvailableProvider.notifier).state = false;
  }

  void addNewTweet(Tweet tweet) {
    // Only add if it's not already in the list
    if (!state.any((t) => t.id == tweet.id)) {
      state = [tweet, ...state];
    }
  }

  void updateTweet(Tweet updatedTweet) {
    state = state.map((tweet) {
      if (tweet.id == updatedTweet.id) {
        return updatedTweet;
      }
      return tweet;
    }).toList();
  }

  bool get isLoading => _isLoading;
  bool get hasMoreTweets => _hasMoreTweets;
}

class TweetController extends StateNotifier<bool> {
  final TweetAPI _tweetAPI;
  final StorageAPI _storageAPI;
  final NotificationController _notificationController;
  final Ref _ref;

  TweetController({
    required Ref ref,
    required TweetAPI tweetAPI,
    required StorageAPI storageAPI,
    required NotificationController notificationController,
  })  : _ref = ref,
        _tweetAPI = tweetAPI,
        _storageAPI = storageAPI,
        _notificationController = notificationController,
        super(false);

  Future<List<Tweet>> getTweets({int limit = 20, int offset = 0}) async {
    final tweetList = await _tweetAPI.gettweets(limit: limit, offset: offset);
    return tweetList.map((tweet) => Tweet.fromMap(tweet.data)).toList();
  }

  Future<Tweet> getTweetById(String id) async {
    final tweet = await _tweetAPI.gettweetById(id);
    return Tweet.fromMap(tweet.data);
  }

  void likeTweet(Tweet tweet, UserModel user) async {
    List<String> likes = tweet.likes;

    if (likes.contains(user.uid)) {
      likes.remove(user.uid);
    } else {
      likes.add(user.uid);
    }

    tweet = tweet.copyWith(likes: likes);
    final res = await _tweetAPI.liketweet(tweet);
    res.fold((l) => null, (r) {
      if (tweet.uid != user.uid) {
        _ref.read(notificationControllerProvider.notifier).createNotification(
          text: '${user.name} liked your tweet!',
          postId: tweet.id,
          notificationType: NotificationType.like,
          uid: tweet.uid,
          currentUser: user,
        );
      }
    });
  }

  void reshareTweet(
    Tweet tweet,
    UserModel currentUser,
    BuildContext context,
  ) async {
    tweet = tweet.copyWith(
      retweetedBy: currentUser.name,
      likes: [],
      commentIds: [],
      reshareCount: tweet.reshareCount + 1,
    );

    final res = await _tweetAPI.updateReshareCount(tweet);
    res.fold(
      (l) => showSnackBar(context, l.message),
      (r) async {
        tweet = tweet.copyWith(
          id: ID.unique(),
          reshareCount: 0,
          tweetedAt: DateTime.now(),
        );
        final res2 = await _tweetAPI.sharetweet(tweet);
        res2.fold(
          (l) => showSnackBar(context, l.message),
          (r) {
            _notificationController.createNotification(
              text: '${currentUser.name} reshared your tweet!',
              postId: tweet.id,
              notificationType: NotificationType.retweet,
              uid: tweet.uid,
            );
            showSnackBar(context, 'Retweeted!');
          },
        );
      },
    );
  }

  Future<bool> shareTweet({
    required List<File> images,
    required String text,
    required BuildContext context,
    required String repliedTo,
    required String repliedToUserId,
  }) async {
    print('DEBUG: TweetController.shareTweet called');
    print('DEBUG: Text: "$text", Images: ${images.length}, repliedTo: "$repliedTo"');
    
    if (text.isEmpty && images.isEmpty) {
      print('DEBUG: Empty tweet attempt - no text or images');
      showSnackBar(context, 'Please enter text or add an image');
      return false;
    }

    try {
      if (images.isNotEmpty) {
        print('DEBUG: Sharing image tweet');
        return await _shareImageTweet(
          images: images,
          text: text,
          context: context,
          repliedTo: repliedTo,
          repliedToUserId: repliedToUserId,
        );
      } else {
        print('DEBUG: Sharing text-only tweet');
        return await _shareTextTweet(
          text: text,
          context: context,
          repliedTo: repliedTo,
          repliedToUserId: repliedToUserId,
        );
      }
    } catch (e) {
      print('DEBUG: Exception in shareTweet: $e');
      if (context.mounted) {
        showSnackBar(context, 'Error creating tweet: $e');
      }
      return false;
    }
  }

  Future<List<Tweet>> getRepliesToTweet(Tweet tweet) async {
    final documents = await _tweetAPI.getRepliesTotweet(tweet);
    return documents.map((tweet) => Tweet.fromMap(tweet.data)).toList();
  }

  Future<List<Tweet>> getTweetsByHashtag(String hashtag) async {
    final tweets = await _tweetAPI.getTweetsByHashtag(hashtag);
    return tweets.map((tweet) => Tweet.fromMap(tweet.data)).toList();
  }

  Future<List<Tweet>> searchTweets(String query) async {
    if (query.isEmpty) {
      return [];
    }
    print('DEBUG: Searching tweets with query: $query');
    final documents = await _tweetAPI.searchTweets(query);
    return documents.map((doc) => Tweet.fromMap(doc.data)).toList();
  }

  Future<bool> _shareImageTweet({
    required List<File> images,
    required String text,
    required BuildContext context,
    required String repliedTo,
    required String repliedToUserId,
  }) async {
    print('DEBUG: _shareImageTweet - Starting');
    state = true;
    bool success = false;
    
    try {
      final hashtags = _getHashtagsFromText(text);
      String link = _getLinkFromText(text);
      final user = _ref.read(currentUserDetailsProvider).value!;
      print('DEBUG: Uploading ${images.length} images');
      final imageLinks = await _storageAPI.uploadImage(images);
      print('DEBUG: Images uploaded successfully: ${imageLinks.length} links');
      
      Tweet tweet = Tweet(
        text: text,
        hashtags: hashtags,
        link: link,
        imageLinks: imageLinks,
        uid: user.uid,
        tweetType: TweetType.image,
        tweetedAt: DateTime.now(),
        likes: const [],
        commentIds: const [],
        id: '',
        reshareCount: 0,
        retweetedBy: '',
        repliedTo: repliedTo,
      );
      
      print('DEBUG: Calling sharetweet API');
      final res = await _tweetAPI.sharetweet(tweet);

      res.fold(
        (l) {
          print('DEBUG: Error sharing image tweet: ${l.message}');
          showSnackBar(context, l.message);
        }, 
        (r) {
          print('DEBUG: Image tweet shared successfully with ID: ${r.$id}');
          success = true;
          if (repliedToUserId.isNotEmpty) {
            _notificationController.createNotification(
              text: '${user.name} replied to your tweet!',
              postId: r.$id,
              notificationType: NotificationType.reply,
              uid: repliedToUserId,
            );
          }
        }
      );
    } catch (e) {
      print('DEBUG: Exception in _shareImageTweet: $e');
      if (context.mounted) {
        showSnackBar(context, 'An error occurred: $e');
      }
    } finally {
      state = false;
      print('DEBUG: _shareImageTweet - Completed, state set to false');
    }
    return success;
  }

  Future<bool> _shareTextTweet({
    required String text,
    required BuildContext context,
    required String repliedTo,
    required String repliedToUserId,
  }) async {
    print('DEBUG: _shareTextTweet - Starting');
    state = true;
    bool success = false;
    
    try {
      final hashtags = _getHashtagsFromText(text);
      String link = _getLinkFromText(text);
      final user = _ref.read(currentUserDetailsProvider).value!;
      print('DEBUG: Current user: ${user.name}, UID: ${user.uid}');
      
      Tweet tweet = Tweet(
        text: text,
        hashtags: hashtags,
        link: link,
        imageLinks: const [],
        uid: user.uid,
        tweetType: TweetType.text,
        tweetedAt: DateTime.now(),
        likes: const [],
        commentIds: const [],
        id: '',
        reshareCount: 0,
        retweetedBy: '',
        repliedTo: repliedTo,
      );
      
      print('DEBUG: Tweet object created, calling API');
      final res = await _tweetAPI.sharetweet(tweet);
      
      res.fold(
        (l) {
          print('DEBUG: Error sharing text tweet: ${l.message}');
          if (context.mounted) {
            showSnackBar(context, l.message);
          }
        },
        (r) {
          print('DEBUG: Text tweet shared successfully with ID: ${r.$id}');
          success = true;
          if (context.mounted && repliedToUserId.isNotEmpty) {
            _notificationController.createNotification(
              text: '${user.name} replied to your tweet!',
              postId: r.$id,
              notificationType: NotificationType.reply,
              uid: repliedToUserId,
            );
          }
        },
      );
    } catch (e) {
      print('DEBUG: Exception in _shareTextTweet: $e');
      if (context.mounted) {
        showSnackBar(context, 'An error occurred: $e');
      }
    } finally {
      state = false;
      print('DEBUG: _shareTextTweet - Completed, state set to false');
    }
    return success;
  }

  String _getLinkFromText(String text) {
    String link = '';
    List<String> wordsInSentence = text.split(' ');
    for (String word in wordsInSentence) {
      if (word.startsWith('https://') || word.startsWith('www.')) {
        link = word;
      }
    }
    return link;
  }

  List<String> _getHashtagsFromText(String text) {
    List<String> hashtags = [];
    List<String> wordsInSentence = text.split(' ');
    for (String word in wordsInSentence) {
      if (word.startsWith('#')) {
        hashtags.add(word);
      }
    }
    return hashtags;
  }

  // Add this method for quote tweets
  Future<bool> quoteTweet({
    required List<File> images,
    required String text,
    required BuildContext context,
    required Tweet quotedTweet,
  }) async {
    print('DEBUG: quoteTweet method called in TweetController');
    state = true;
    bool success = false;
    
    try {
      final hashtags = _getHashtagsFromText(text);
      String link = _getLinkFromText(text);
      final user = _ref.read(currentUserDetailsProvider).value!;
      
      List<String> imageLinks = [];
      
      if (images.isNotEmpty) {
        print('DEBUG: Uploading ${images.length} images for quote tweet');
        imageLinks = await _storageAPI.uploadImage(images);
      }
      
      Tweet tweet = Tweet(
        text: text,
        hashtags: hashtags,
        link: link,
        imageLinks: imageLinks,
        uid: user.uid,
        tweetType: images.isEmpty ? TweetType.text : TweetType.image,
        tweetedAt: DateTime.now(),
        likes: const [],
        commentIds: const [],
        id: '',
        reshareCount: 0,
        retweetedBy: '',
        repliedTo: '',
        quotedTweetId: quotedTweet.id,
      );
      
      print('DEBUG: Sharing quote tweet');
      final res = await _tweetAPI.sharetweet(tweet);
      
      res.fold(
        (l) {
          print('DEBUG: Error sharing quote tweet: ${l.message}');
          showSnackBar(context, l.message);
        },
        (r) {
          print('DEBUG: Quote tweet shared successfully with ID: ${r.$id}');
          success = true;
          
          // Notify the original tweet author
          if (quotedTweet.uid != user.uid) {
            _notificationController.createNotification(
              text: '${user.name} quoted your tweet!',
              postId: r.$id,
              notificationType: NotificationType.retweet,
              uid: quotedTweet.uid,
              currentUser: user,
            );
          }
          
          if (context.mounted) {
            showSnackBar(context, 'Quote tweet shared!');
          }
        },
      );
    } catch (e) {
      print('DEBUG: Exception in quoteTweet: $e');
      if (context.mounted) {
        showSnackBar(context, 'An error occurred: $e');
      }
    } finally {
      state = false;
    }
    
    return success;
  }

  // Add this method to get ranked tweets based on user interests
  Future<List<Tweet>> getRankedTweets() async {
    try {
      final currentUser = _ref.read(currentUserDetailsProvider).value;
      if (currentUser == null) {
        // Fall back to chronological order if no user
        return getTweets();
      }
      
      // Get recommendation service
      final recommendationService = _ref.read(recommendationServiceProvider);
      
      // Get tweets
      final tweets = await getTweets(limit: 50); // Get a larger pool to rank from
      
      // Get user's liked tweets to infer interests
      final userTweets = await getUserLikedTweets(currentUser.uid);
      
      // Infer interests
      final interests = recommendationService.inferUserInterests(currentUser, userTweets);
      
      // Score and rank tweets
      final scoredTweets = tweets.map((tweet) {
        final score = recommendationService.scoreTweet(tweet, currentUser, interests);
        return {
          'tweet': tweet,
          'score': score,
        };
      }).toList();
      
      // Sort by score (descending)
      scoredTweets.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
      
      // Return ranked tweets
      return scoredTweets.map((item) => item['tweet'] as Tweet).toList();
    } catch (e) {
      print('Error getting ranked tweets: $e');
      // Fall back to chronological order
      return getTweets();
    }
  }
  
  // Method to get tweets the user has liked
  Future<List<Tweet>> getUserLikedTweets(String uid) async {
    try {
      final tweetDocs = await _tweetAPI.gettweets(limit: 100); // Get recent tweets
      final tweets = tweetDocs.map((doc) => Tweet.fromMap(doc.data)).toList();
      
      // Filter to tweets the user has liked
      return tweets.where((tweet) => tweet.likes.contains(uid)).toList();
    } catch (e) {
      return [];
    }
  }

  // New methods for different tweet types
  Future<bool> shareVideoTweet({
    required File video,
    required String text,
    required BuildContext context,
    String repliedTo = '',
    String repliedToUserId = '',
  }) async {
    print('DEBUG: shareVideoTweet - Starting');
    state = true;
    bool success = false;
    
    try {
      final hashtags = _getHashtagsFromText(text);
      String link = _getLinkFromText(text);
      final user = _ref.read(currentUserDetailsProvider).value!;
      
      // Upload video to storage
      final videoUrl = await _storageAPI.uploadVideo(video);
      
      Tweet tweet = Tweet(
        text: text,
        hashtags: hashtags,
        link: link,
        imageLinks: const [],
        uid: user.uid,
        tweetType: TweetType.video,
        tweetedAt: DateTime.now(),
        likes: const [],
        commentIds: const [],
        id: '',
        reshareCount: 0,
        retweetedBy: '',
        repliedTo: repliedTo,
        videoUrl: videoUrl,
      );
      
      final res = await _tweetAPI.sharetweet(tweet);
      res.fold(
        (l) {
          print('DEBUG: Error sharing video tweet: ${l.message}');
          showSnackBar(context, l.message);
        },
        (r) {
          print('DEBUG: Video tweet shared successfully with ID: ${r.$id}');
          success = true;
          if (repliedToUserId.isNotEmpty) {
            _notificationController.createNotification(
              text: '${user.name} replied to your tweet with a video!',
              postId: r.$id,
              notificationType: NotificationType.reply,
              uid: repliedToUserId,
            );
          }
        }
      );
    } catch (e) {
      print('DEBUG: Exception in shareVideoTweet: $e');
      if (context.mounted) {
        showSnackBar(context, 'An error occurred: $e');
      }
    } finally {
      state = false;
    }
    return success;
  }

  Future<bool> shareGifTweet({
    required String gifUrl,
    required String text,
    required BuildContext context,
    String repliedTo = '',
    String repliedToUserId = '',
  }) async {
    print('DEBUG: shareGifTweet - Starting');
    state = true;
    bool success = false;
    
    try {
      final hashtags = _getHashtagsFromText(text);
      String link = _getLinkFromText(text);
      final user = _ref.read(currentUserDetailsProvider).value!;
      
      Tweet tweet = Tweet(
        text: text,
        hashtags: hashtags,
        link: link,
        imageLinks: const [],
        uid: user.uid,
        tweetType: TweetType.gif,
        tweetedAt: DateTime.now(),
        likes: const [],
        commentIds: const [],
        id: '',
        reshareCount: 0,
        retweetedBy: '',
        repliedTo: repliedTo,
        gifUrl: gifUrl,
      );
      
      final res = await _tweetAPI.sharetweet(tweet);
      res.fold(
        (l) {
          print('DEBUG: Error sharing GIF tweet: ${l.message}');
          showSnackBar(context, l.message);
        },
        (r) {
          print('DEBUG: GIF tweet shared successfully with ID: ${r.$id}');
          success = true;
          if (repliedToUserId.isNotEmpty) {
            _notificationController.createNotification(
              text: '${user.name} replied to your tweet with a GIF!',
              postId: r.$id,
              notificationType: NotificationType.reply,
              uid: repliedToUserId,
            );
          }
        }
      );
    } catch (e) {
      print('DEBUG: Exception in shareGifTweet: $e');
      if (context.mounted) {
        showSnackBar(context, 'An error occurred: $e');
      }
    } finally {
      state = false;
    }
    return success;
  }

  Future<bool> sharePollTweet({
    required String text,
    required List<String> pollOptions,
    required Duration pollDuration,
    required BuildContext context,
    String repliedTo = '',
    String repliedToUserId = '',
  }) async {
    print('DEBUG: sharePollTweet - Starting');
    state = true;
    bool success = false;
    
    try {
      final hashtags = _getHashtagsFromText(text);
      String link = _getLinkFromText(text);
      final user = _ref.read(currentUserDetailsProvider).value!;
      
      // Convert poll options to the expected format
      final formattedPollOptions = pollOptions.map((option) => {
        'text': option,
        'votes': <String>[],  // Empty list to store UIDs of users who voted
      }).toList();
      
      Tweet tweet = Tweet(
        text: text,
        hashtags: hashtags,
        link: link,
        imageLinks: const [],
        uid: user.uid,
        tweetType: TweetType.poll,
        tweetedAt: DateTime.now(),
        likes: const [],
        commentIds: const [],
        id: '',
        reshareCount: 0,
        retweetedBy: '',
        repliedTo: repliedTo,
        pollOptions: formattedPollOptions,
        pollEndTime: DateTime.now().add(pollDuration),
      );
      
      final res = await _tweetAPI.sharetweet(tweet);
      res.fold(
        (l) {
          print('DEBUG: Error sharing poll tweet: ${l.message}');
          showSnackBar(context, l.message);
        },
        (r) {
          print('DEBUG: Poll tweet shared successfully with ID: ${r.$id}');
          success = true;
          if (repliedToUserId.isNotEmpty) {
            _notificationController.createNotification(
              text: '${user.name} replied to your tweet with a poll!',
              postId: r.$id,
              notificationType: NotificationType.reply,
              uid: repliedToUserId,
            );
          }
        }
      );
    } catch (e) {
      print('DEBUG: Exception in sharePollTweet: $e');
      if (context.mounted) {
        showSnackBar(context, 'An error occurred: $e');
      }
    } finally {
      state = false;
    }
    return success;
  }

  Future<bool> shareAudioTweet({
    required File audio,
    required String text,
    required BuildContext context,
    String repliedTo = '',
    String repliedToUserId = '',
  }) async {
    print('DEBUG: shareAudioTweet - Starting');
    state = true;
    bool success = false;
    
    try {
      final hashtags = _getHashtagsFromText(text);
      String link = _getLinkFromText(text);
      final user = _ref.read(currentUserDetailsProvider).value!;
      
      // Upload audio to storage
      final audioUrl = await _storageAPI.uploadAudio(audio);
      
      Tweet tweet = Tweet(
        text: text,
        hashtags: hashtags,
        link: link,
        imageLinks: const [],
        uid: user.uid,
        tweetType: TweetType.audio,
        tweetedAt: DateTime.now(),
        likes: const [],
        commentIds: const [],
        id: '',
        reshareCount: 0,
        retweetedBy: '',
        repliedTo: repliedTo,
        audioUrl: audioUrl,
      );
      
      final res = await _tweetAPI.sharetweet(tweet);
      res.fold(
        (l) {
          print('DEBUG: Error sharing audio tweet: ${l.message}');
          showSnackBar(context, l.message);
        },
        (r) {
          print('DEBUG: Audio tweet shared successfully with ID: ${r.$id}');
          success = true;
          if (repliedToUserId.isNotEmpty) {
            _notificationController.createNotification(
              text: '${user.name} replied to your tweet with audio!',
              postId: r.$id,
              notificationType: NotificationType.reply,
              uid: repliedToUserId,
            );
          }
        }
      );
    } catch (e) {
      print('DEBUG: Exception in shareAudioTweet: $e');
      if (context.mounted) {
        showSnackBar(context, 'An error occurred: $e');
      }
    } finally {
      state = false;
    }
    return success;
  }

  Future<bool> shareLocationTweet({
    required Map<String, dynamic> locationData,
    required String text,
    required BuildContext context,
    String repliedTo = '',
    String repliedToUserId = '',
  }) async {
    print('DEBUG: shareLocationTweet - Starting');
    state = true;
    bool success = false;
    
    try {
      final hashtags = _getHashtagsFromText(text);
      String link = _getLinkFromText(text);
      final user = _ref.read(currentUserDetailsProvider).value!;
      
      Tweet tweet = Tweet(
        text: text,
        hashtags: hashtags,
        link: link,
        imageLinks: const [],
        uid: user.uid,
        tweetType: TweetType.location,
        tweetedAt: DateTime.now(),
        likes: const [],
        commentIds: const [],
        id: '',
        reshareCount: 0,
        retweetedBy: '',
        repliedTo: repliedTo,
        locationData: locationData,
      );
      
      final res = await _tweetAPI.sharetweet(tweet);
      res.fold(
        (l) {
          print('DEBUG: Error sharing location tweet: ${l.message}');
          showSnackBar(context, l.message);
        },
        (r) {
          print('DEBUG: Location tweet shared successfully with ID: ${r.$id}');
          success = true;
          if (repliedToUserId.isNotEmpty) {
            _notificationController.createNotification(
              text: '${user.name} shared a location in reply to your tweet!',
              postId: r.$id,
              notificationType: NotificationType.reply,
              uid: repliedToUserId,
            );
          }
        }
      );
    } catch (e) {
      print('DEBUG: Exception in shareLocationTweet: $e');
      if (context.mounted) {
        showSnackBar(context, 'An error occurred: $e');
      }
    } finally {
      state = false;
    }
    return success;
  }

  // Vote on a poll
  Future<bool> votePoll({
    required Tweet tweet,
    required int optionIndex,
    required BuildContext context,
  }) async {
    state = true;
    bool success = false;
    
    try {
      final currentUser = _ref.read(currentUserDetailsProvider).value!;
      
      if (tweet.pollOptions == null || optionIndex >= tweet.pollOptions!.length) {
        if (context.mounted) {
          showSnackBar(context, 'Invalid poll option');
        }
        state = false;
        return false;
      }
      
      // Check if poll has ended - FIXED missing parenthesis
      if (tweet.pollEndTime != null && DateTime.now().isAfter(tweet.pollEndTime!)) {
        if (context.mounted) {
          showSnackBar(context, 'This poll has ended');
        }
        state = false;
        return false;
      }
      
      // Check if user has already voted on this poll
      bool hasVoted = false;
      if (tweet.pollOptions != null) {
        for (final option in tweet.pollOptions!) {
          if ((option['votes'] as List<dynamic>).contains(currentUser.uid)) {
            hasVoted = true;
            break;
          }
        }
      }
      
      if (hasVoted) {
        if (context.mounted) {
          showSnackBar(context, 'You have already voted on this poll');
        }
        state = false;
        return false;
      }
      
      // Update the poll options to include this vote
      final updatedPollOptions = List<Map<String, dynamic>>.from(tweet.pollOptions!);
      final votes = List<String>.from(updatedPollOptions[optionIndex]['votes'] as List<dynamic>);
      votes.add(currentUser.uid);
      updatedPollOptions[optionIndex] = {
        ...updatedPollOptions[optionIndex],
        'votes': votes,
      };
      
      final updatedTweet = tweet.copyWith(
        pollOptions: updatedPollOptions,
      );
      
      final res = await _tweetAPI.updatePoll(updatedTweet);
      res.fold(
        (l) {
          if (context.mounted) {
            showSnackBar(context, l.message);
          }
        },
        (r) {
          success = true;
          if (context.mounted) {
            showSnackBar(context, 'Vote recorded!');
          }
        },
      );
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'An error occurred: $e');
      }
    } finally {
      state = false;
    }
    
    return success;
  }

  Future<bool> shareAudioRoomTweet({
    required String text,
    required String audioRoomId,
    required BuildContext context,
    String repliedTo = '',
    String repliedToUserId = '',
  }) async {
    print('DEBUG: shareAudioRoomTweet - Starting');
    state = true;
    bool success = false;
    
    try {
      final hashtags = _getHashtagsFromText(text);
      String link = _getLinkFromText(text);
      final user = _ref.read(currentUserDetailsProvider).value!;
      
      Tweet tweet = Tweet(
        text: text,
        hashtags: hashtags,
        link: link,
        imageLinks: const [],
        uid: user.uid,
        tweetType: TweetType.audioRoom,
        tweetedAt: DateTime.now(),
        likes: const [],
        commentIds: const [],
        id: '',
        reshareCount: 0,
        retweetedBy: '',
        repliedTo: repliedTo,
        audioRoomId: audioRoomId,
        isAudioRoomActive: true,
        audioRoomParticipants: [user.uid],
      );
      
      final res = await _tweetAPI.sharetweet(tweet);
      res.fold(
        (l) {
          print('DEBUG: Error sharing audio room tweet: ${l.message}');
          showSnackBar(context, l.message);
        },
        (r) {
          print('DEBUG: Audio room tweet shared successfully with ID: ${r.$id}');
          success = true;
          if (repliedToUserId.isNotEmpty) {
            _notificationController.createNotification(
              text: '${user.name} started an audio room!',
              postId: r.$id,
              notificationType: NotificationType.reply,
              uid: repliedToUserId,
            );
          }
        }
      );
    } catch (e) {
      print('DEBUG: Exception in shareAudioRoomTweet: $e');
      if (context.mounted) {
        showSnackBar(context, 'An error occurred: $e');
      }
    } finally {
      state = false;
    }
    return success;
  }

  Future<bool> updateAudioRoomStatus({
    required Tweet tweet,
    required bool isActive,
    required List<String> participants,
    required BuildContext context,
  }) async {
    state = true;
    bool success = false;
    
    try {
      final updatedTweet = tweet.copyWith(
        isAudioRoomActive: isActive,
        audioRoomParticipants: participants,
      );
      
      final res = await _tweetAPI.updateAudioRoomStatus(updatedTweet);
      res.fold(
        (l) {
          if (context.mounted) {
            showSnackBar(context, l.message);
          }
        },
        (r) {
          success = true;
        },
      );
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'An error occurred: $e');
      }
    } finally {
      state = false;
    }
    
    return success;
  }
}
