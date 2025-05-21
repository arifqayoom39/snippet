import 'dart:convert';

class BookmarkModel {
  final String userId;
  final List<String> bookmarkedTweets;
  final String id;

  BookmarkModel({
    required this.userId,
    required this.bookmarkedTweets,
    required this.id,
  });

  BookmarkModel copyWith({
    String? userId,
    List<String>? bookmarkedTweets,
    String? id,
  }) {
    return BookmarkModel(
      userId: userId ?? this.userId,
      bookmarkedTweets: bookmarkedTweets ?? this.bookmarkedTweets,
      id: id ?? this.id,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bookmarkedTweets': bookmarkedTweets,
      'id': id,
    };
  }

  factory BookmarkModel.fromMap(Map<String, dynamic> map) {
    return BookmarkModel(
      userId: map['userId'] ?? '',
      bookmarkedTweets: List<String>.from(map['bookmarkedTweets'] ?? []),
      id: map['id'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory BookmarkModel.fromJson(String source) => BookmarkModel.fromMap(json.decode(source));
}
