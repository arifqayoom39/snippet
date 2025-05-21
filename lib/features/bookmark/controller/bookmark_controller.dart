import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/apis/bookmark_api.dart';
import 'package:snippet/apis/tweet_api.dart';
import 'package:snippet/core/utils.dart';
import 'package:snippet/features/auth/controller/auth_controller.dart';
import 'package:snippet/models/bookmark_model.dart';
import 'package:snippet/models/tweet_model.dart';

final bookmarkControllerProvider = StateNotifierProvider<BookmarkController, bool>((ref) {
  return BookmarkController(
    ref: ref,
    bookmarkAPI: ref.watch(bookmarkAPIProvider),
    tweetAPI: ref.watch(tweetAPIProvider),
  );
});

final getBookmarkedTweetsProvider = FutureProvider((ref) async {
  final bookmarkController = ref.watch(bookmarkControllerProvider.notifier);
  return bookmarkController.getBookmarkedTweets();
});

final isBookmarkedProvider = FutureProvider.family((ref, String tweetId) async {
  final bookmarkController = ref.watch(bookmarkControllerProvider.notifier);
  return bookmarkController.isTweetBookmarked(tweetId);
});

class BookmarkController extends StateNotifier<bool> {
  final BookmarkAPI _bookmarkAPI;
  final TweetAPI _tweetAPI;
  final Ref _ref;

  BookmarkController({
    required Ref ref,
    required BookmarkAPI bookmarkAPI,
    required TweetAPI tweetAPI,
  }) : _ref = ref,
       _bookmarkAPI = bookmarkAPI,
       _tweetAPI = tweetAPI,
       super(false);

  // Toggle bookmark status of a tweet
  Future<void> toggleBookmark(String tweetId, BuildContext context) async {
    state = true;
    
    final currentUser = _ref.read(currentUserDetailsProvider).value;
    
    if (currentUser == null) {
      state = false;
      return;
    }
    
    // Get existing bookmarks
    final document = await _bookmarkAPI.getBookmarks(currentUser.uid);
    
    if (document == null) {
      // Create new bookmarks document
      final bookmarkModel = BookmarkModel(
        userId: currentUser.uid,
        bookmarkedTweets: [tweetId],
        id: currentUser.uid,
      );
      
      final res = await _bookmarkAPI.createBookmarks(bookmarkModel);
      
      res.fold(
        (l) => showSnackBar(context, l.message),
        (r) => showSnackBar(context, 'Tweet bookmarked'),
      );
    } else {
      // Update existing bookmarks
      final bookmarkModel = BookmarkModel.fromMap(document.data);
      List<String> updatedBookmarks = [...bookmarkModel.bookmarkedTweets];
      
      if (updatedBookmarks.contains(tweetId)) {
        // Remove bookmark
        updatedBookmarks.remove(tweetId);
      } else {
        // Add bookmark
        updatedBookmarks.add(tweetId);
      }
      
      final updatedModel = bookmarkModel.copyWith(
        bookmarkedTweets: updatedBookmarks,
      );
      
      final res = await _bookmarkAPI.updateBookmarks(updatedModel);
      
      res.fold(
        (l) => showSnackBar(context, l.message),
        (r) => showSnackBar(
          context, 
          updatedBookmarks.contains(tweetId) ? 'Tweet bookmarked' : 'Bookmark removed'
        ),
      );
    }
    
    state = false;
  }

  // Check if a tweet is bookmarked
  Future<bool> isTweetBookmarked(String tweetId) async {
    final currentUser = _ref.read(currentUserDetailsProvider).value;
    
    if (currentUser == null) {
      return false;
    }
    
    final document = await _bookmarkAPI.getBookmarks(currentUser.uid);
    
    if (document == null) {
      return false;
    }
    
    final bookmarkModel = BookmarkModel.fromMap(document.data);
    return bookmarkModel.bookmarkedTweets.contains(tweetId);
  }

  // Get all bookmarked tweets
  Future<List<Tweet>> getBookmarkedTweets() async {
    final currentUser = _ref.read(currentUserDetailsProvider).value;
    final List<Tweet> bookmarkedTweets = [];
    
    if (currentUser == null) {
      return bookmarkedTweets;
    }
    
    final document = await _bookmarkAPI.getBookmarks(currentUser.uid);
    
    if (document == null) {
      return bookmarkedTweets;
    }
    
    final bookmarkModel = BookmarkModel.fromMap(document.data);
    
    // Fetch each bookmarked tweet
    for (final tweetId in bookmarkModel.bookmarkedTweets) {
      try {
        final tweetDoc = await _tweetAPI.gettweetById(tweetId);
        final tweet = Tweet.fromMap(tweetDoc.data);
        bookmarkedTweets.add(tweet);
      } catch (e) {
        // Skip tweets that can't be fetched
        continue;
      }
    }
    
    return bookmarkedTweets;
  }
}
