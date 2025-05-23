import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:snippet/constants/appwrite_constants.dart';
import 'package:snippet/core/core.dart';
import 'package:snippet/core/providers.dart';
import 'package:snippet/models/tweet_model.dart';
import 'dart:convert';

final tweetAPIProvider = Provider((ref) {
  return TweetAPI(
    db: ref.watch(appwriteDatabaseProvider),
    realtime: ref.watch(appwriteRealtimeProvider),
  );
});

abstract class ItweetAPI {
  FutureEither<Document> sharetweet(Tweet tweet);
  Future<List<Document>> gettweets({int limit, int offset});
  Stream<RealtimeMessage> getLatesttweet();
  FutureEither<Document> liketweet(Tweet tweet);
  FutureEither<Document> updateReshareCount(Tweet tweet);
  Future<List<Document>> getRepliesTotweet(Tweet tweet);
  Future<Document> gettweetById(String id);
  Future<List<Document>> getUsertweets(String uid);
  Future<List<Document>> gettweetsByHashtag(String hashtag);
  Future<List<Document>> searchTweets(String query);
}

class TweetAPI implements ItweetAPI {
  final Databases _db;
  final Realtime _realtime;
  TweetAPI({required Databases db, required Realtime realtime})
      : _db = db,
        _realtime = realtime;

  @override
  FutureEither<Document> sharetweet(Tweet tweet) async {
    try {
      final document = await _db.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tweetsCollection,
        documentId: ID.unique(),
        data: tweet.toMap(),
      );
      return right(document);
    } on AppwriteException catch (e, st) {
      return left(Failure(e.message ?? 'Some unexpected error occurred', st));
    } catch (e, st) {
      return left(Failure(e.toString(), st));
    }
  }

  @override
  Future<List<Document>> gettweets({int limit = 20, int offset = 0}) async {
    try {
      final documents = await _db.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tweetsCollection,
        queries: [
          Query.orderDesc('tweetedAt'),
          Query.limit(limit),
          Query.offset(offset),
        ],
      );
      return documents.documents;
    } catch (e) {
      print('Error fetching tweets: $e'); // Add logging to diagnose issues
      return [];
    }
  }

  @override
  Stream<RealtimeMessage> getLatesttweet() {
    return _realtime.subscribe([
      'databases.${AppwriteConstants.databaseId}.collections.${AppwriteConstants.tweetsCollection}.documents'
    ]).stream;
  }

  @override
  FutureEither<Document> liketweet(Tweet tweet) async {
    try {
      final document = await _db.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tweetsCollection,
        documentId: tweet.id,
        data: {'likes': tweet.likes},
      );
      return right(document);
    } on AppwriteException catch (e, st) {
      return left(Failure(e.message ?? 'Some unexpected error occurred', st));
    } catch (e, st) {
      return left(Failure(e.toString(), st));
    }
  }

  @override
  FutureEither<Document> updateReshareCount(Tweet tweet) async {
    try {
      final document = await _db.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tweetsCollection,
        documentId: tweet.id,
        data: {'reshareCount': tweet.reshareCount},
      );
      return right(document);
    } on AppwriteException catch (e, st) {
      return left(Failure(e.message ?? 'Some unexpected error occurred', st));
    } catch (e, st) {
      return left(Failure(e.toString(), st));
    }
  }

  @override
  Future<List<Document>> getRepliesTotweet(Tweet tweet) async {
    try {
      final documents = await _db.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tweetsCollection,
        queries: [
          Query.equal('repliedTo', tweet.id),
        ],
      );
      return documents.documents;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Document> gettweetById(String id) async {
    try {
      final document = await _db.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tweetsCollection,
        documentId: id,
      );
      return document;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Document>> getUsertweets(String uid) async {
    try {
      final documents = await _db.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tweetsCollection,
        queries: [
          Query.equal('uid', uid),
        ],
      );
      return documents.documents;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Document>> gettweetsByHashtag(String hashtag) async {
    try {
      final documents = await _db.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tweetsCollection,
        queries: [
          Query.search('hashtags', hashtag),
        ],
      );
      return documents.documents;
    } catch (e) {
      return [];
    }
  }

  Future<List<Document>> getTweetsByHashtag(String hashtag) async {
    final documents = await _db.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.tweetsCollection,
      queries: [
        // Search for tweets containing the hashtag in the text field
        Query.search('text', '#$hashtag'),
      ],
    );
    return documents.documents;
  }

  @override
  Future<List<Document>> searchTweets(String query) async {
    try {
      final documents = await _db.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tweetsCollection,
        queries: [
          // More comprehensive search through text field
          Query.search('text', query),
          // Also order by recency for more relevant results
          Query.orderDesc('tweetedAt'),
          // Limit to top 30 results
          Query.limit(30),
        ],
      );
      
      // If we find exact matches, prioritize them
      final exactMatches = documents.documents.where(
        (doc) => doc.data['text'].toString().toLowerCase().contains(query.toLowerCase())
      ).toList();
      
      final otherMatches = documents.documents.where(
        (doc) => !exactMatches.contains(doc)
      ).toList();
      
      // Return exact matches first, then other matches
      return [...exactMatches, ...otherMatches];
    } catch (e) {
      print('Error searching tweets: $e');
      return [];
    }
  }

  Future<Either> updatePoll(Tweet tweet) async {
    try {
      final document = await _db.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tweetsCollection,
        documentId: tweet.id,
        data: {
          'pollOptions': jsonEncode(tweet.pollOptions),
        },
      );
      return right(document);
    } on AppwriteException catch (e, st) {
      return left(Failure(e.message ?? 'Some unexpected error occurred', st));
    } catch (e, st) {
      return left(Failure(e.toString(), st));
    }
  }

  Future<Either> updateAudioRoomStatus(Tweet tweet) async {
    try {
      final document = await _db.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.tweetsCollection,
        documentId: tweet.id,
        data: {
          'isAudioRoomActive': tweet.isAudioRoomActive,
          'audioRoomParticipants': tweet.audioRoomParticipants,
        },
      );
      return right(document);
    } on AppwriteException catch (e, st) {
      return left(Failure(e.message ?? 'Some unexpected error occurred', st));
    } catch (e, st) {
      return left(Failure(e.toString(), st));
    }
  }
}
