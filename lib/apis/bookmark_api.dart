import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:snippet/constants/appwrite_constants.dart';
import 'package:snippet/core/core.dart';
import 'package:snippet/core/providers.dart';
import 'package:snippet/models/bookmark_model.dart';

final bookmarkAPIProvider = Provider((ref) {
  return BookmarkAPI(
    db: ref.watch(appwriteDatabaseProvider),
  );
});

abstract class IBookmarkAPI {
  FutureEither<Document> createBookmarks(BookmarkModel bookmarkModel);
  FutureEither<Document> updateBookmarks(BookmarkModel bookmarkModel);
  Future<Document?> getBookmarks(String userId);
}

class BookmarkAPI implements IBookmarkAPI {
  final Databases _db;
  
  BookmarkAPI({required Databases db}) : _db = db;

  @override
  FutureEither<Document> createBookmarks(BookmarkModel bookmarkModel) async {
    try {
      final document = await _db.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.bookmarksCollection, // You'll need to create this collection
        documentId: bookmarkModel.userId, // Use userId as document ID for easy lookup
        data: bookmarkModel.toMap(),
      );
      return right(document);
    } on AppwriteException catch (e, st) {
      return left(Failure(e.message ?? 'Some unexpected error occurred', st));
    } catch (e, st) {
      return left(Failure(e.toString(), st));
    }
  }

  @override
  FutureEither<Document> updateBookmarks(BookmarkModel bookmarkModel) async {
    try {
      final document = await _db.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.bookmarksCollection,
        documentId: bookmarkModel.id,
        data: {'bookmarkedTweets': bookmarkModel.bookmarkedTweets},
      );
      return right(document);
    } on AppwriteException catch (e, st) {
      return left(Failure(e.message ?? 'Some unexpected error occurred', st));
    } catch (e, st) {
      return left(Failure(e.toString(), st));
    }
  }

  @override
  Future<Document?> getBookmarks(String userId) async {
    try {
      final document = await _db.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.bookmarksCollection,
        documentId: userId,
      );
      return document;
    } on AppwriteException {
      // If document doesn't exist, return null
      return null;
    } catch (e) {
      return null;
    }
  }
}
