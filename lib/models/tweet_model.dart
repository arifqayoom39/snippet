import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:snippet/core/enums/tweet_type_enum.dart';

@immutable
class Tweet {
  final String text;
  final List<String> hashtags;
  final String link;
  final List<String> imageLinks;
  final String uid;
  final TweetType tweetType;
  final DateTime tweetedAt;
  final List<String> likes;
  final List<String> commentIds;
  final String id;
  final int reshareCount;
  final String retweetedBy;
  final String repliedTo;
  final String quotedTweetId;
  
  // New fields for additional tweet types
  final String videoUrl;
  final String gifUrl;
  final String audioUrl;
  final Map<String, dynamic>? locationData;
  final String threadParentId;
  final List<Map<String, dynamic>>? pollOptions;
  final DateTime? pollEndTime;
  
  // Audio room fields
  final String audioRoomId;
  final bool isAudioRoomActive;
  final List<String> audioRoomParticipants;

  const Tweet({
    required this.text,
    required this.hashtags,
    required this.link,
    required this.imageLinks,
    required this.uid,
    required this.tweetType,
    required this.tweetedAt,
    required this.likes,
    required this.commentIds,
    required this.id,
    required this.reshareCount,
    required this.retweetedBy,
    required this.repliedTo,
    this.quotedTweetId = '',
    this.videoUrl = '',
    this.gifUrl = '',
    this.audioUrl = '',
    this.locationData,
    this.threadParentId = '',
    this.pollOptions,
    this.pollEndTime,
    this.audioRoomId = '',
    this.isAudioRoomActive = false,
    this.audioRoomParticipants = const [],
  });

  Tweet copyWith({
    String? text,
    List<String>? hashtags,
    String? link,
    List<String>? imageLinks,
    String? uid,
    TweetType? tweetType,
    DateTime? tweetedAt,
    List<String>? likes,
    List<String>? commentIds,
    String? id,
    int? reshareCount,
    String? retweetedBy,
    String? repliedTo,
    String? quotedTweetId,
    String? videoUrl,
    String? gifUrl,
    String? audioUrl,
    Map<String, dynamic>? locationData,
    String? threadParentId,
    List<Map<String, dynamic>>? pollOptions,
    DateTime? pollEndTime,
    String? audioRoomId,
    bool? isAudioRoomActive,
    List<String>? audioRoomParticipants,
  }) {
    return Tweet(
      text: text ?? this.text,
      hashtags: hashtags ?? this.hashtags,
      link: link ?? this.link,
      imageLinks: imageLinks ?? this.imageLinks,
      uid: uid ?? this.uid,
      tweetType: tweetType ?? this.tweetType,
      tweetedAt: tweetedAt ?? this.tweetedAt,
      likes: likes ?? this.likes,
      commentIds: commentIds ?? this.commentIds,
      id: id ?? this.id,
      reshareCount: reshareCount ?? this.reshareCount,
      retweetedBy: retweetedBy ?? this.retweetedBy,
      repliedTo: repliedTo ?? this.repliedTo,
      quotedTweetId: quotedTweetId ?? this.quotedTweetId,
      videoUrl: videoUrl ?? this.videoUrl,
      gifUrl: gifUrl ?? this.gifUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      locationData: locationData ?? this.locationData,
      threadParentId: threadParentId ?? this.threadParentId,
      pollOptions: pollOptions ?? this.pollOptions,
      pollEndTime: pollEndTime ?? this.pollEndTime,
      audioRoomId: audioRoomId ?? this.audioRoomId,
      isAudioRoomActive: isAudioRoomActive ?? this.isAudioRoomActive,
      audioRoomParticipants: audioRoomParticipants ?? this.audioRoomParticipants,
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'text': text,
      'hashtags': hashtags,
      'link': link,
      'imageLinks': imageLinks,
      'uid': uid,
      'tweetType': tweetType.type,
      'tweetedAt': tweetedAt.toIso8601String(),
      'likes': likes,
      'commentIds': commentIds,
      'reshareCount': reshareCount,
      'retweetedBy': retweetedBy,
      'repliedTo': repliedTo,
      'quotedTweetId': quotedTweetId,
      'videoUrl': videoUrl,
      'gifUrl': gifUrl,
      'audioUrl': audioUrl,
      'threadParentId': threadParentId,
      'audioRoomId': audioRoomId,
      'isAudioRoomActive': isAudioRoomActive,
      'audioRoomParticipants': audioRoomParticipants,
    };
    
    // Convert complex objects to JSON strings
    if (locationData != null) {
      map['locationData'] = jsonEncode(locationData);
    }
    
    if (pollOptions != null) {
      map['pollOptions'] = jsonEncode(pollOptions);
    }
    
    if (pollEndTime != null) {
      map['pollEndTime'] = pollEndTime!.toIso8601String();
    }
    
    return map;
  }

  factory Tweet.fromMap(Map<String, dynamic> map) {
    return Tweet(
      text: map['text'] ?? '',
      hashtags: List<String>.from(map['hashtags'] ?? []),
      link: map['link'] ?? '',
      imageLinks: List<String>.from(map['imageLinks'] ?? []),
      uid: map['uid'] ?? '',
      tweetType: (map['tweetType'] as String).toTweetTypeEnum(),
      tweetedAt: DateTime.parse(map['tweetedAt']),
      likes: List<String>.from(map['likes'] ?? []),
      commentIds: List<String>.from(map['commentIds'] ?? []),
      id: map['\$id'] ?? '',
      reshareCount: map['reshareCount']?.toInt() ?? 0,
      retweetedBy: map['retweetedBy'] ?? '',
      repliedTo: map['repliedTo'] ?? '',
      quotedTweetId: map['quotedTweetId'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      gifUrl: map['gifUrl'] ?? '',
      audioUrl: map['audioUrl'] ?? '',
      locationData: map['locationData'] != null 
        ? jsonDecode(map['locationData']) as Map<String, dynamic>
        : null,
      threadParentId: map['threadParentId'] ?? '',
      pollOptions: map['pollOptions'] != null 
        ? (jsonDecode(map['pollOptions']) as List)
            .map((option) => option as Map<String, dynamic>)
            .toList() 
        : null,
      pollEndTime: map['pollEndTime'] != null ? DateTime.parse(map['pollEndTime']) : null,
      audioRoomId: map['audioRoomId'] ?? '',
      isAudioRoomActive: map['isAudioRoomActive'] ?? false,
      audioRoomParticipants: List<String>.from(map['audioRoomParticipants'] ?? []),
    );
  }

  @override
  String toString() {
    return 'Tweet(text: $text, hashtags: $hashtags, link: $link, imageLinks: $imageLinks, uid: $uid, tweetType: $tweetType, tweetedAt: $tweetedAt, likes: $likes, commentIds: $commentIds, id: $id, reshareCount: $reshareCount, retweetedBy: $retweetedBy, repliedTo: $repliedTo, quotedTweetId: $quotedTweetId, videoUrl: $videoUrl, gifUrl: $gifUrl, audioUrl: $audioUrl, locationData: $locationData, threadParentId: $threadParentId, pollOptions: $pollOptions, pollEndTime: $pollEndTime, audioRoomId: $audioRoomId, isAudioRoomActive: $isAudioRoomActive, audioRoomParticipants: $audioRoomParticipants)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Tweet &&
        other.text == text &&
        listEquals(other.hashtags, hashtags) &&
        other.link == link &&
        listEquals(other.imageLinks, imageLinks) &&
        other.uid == uid &&
        other.tweetType == tweetType &&
        other.tweetedAt == tweetedAt &&
        listEquals(other.likes, likes) &&
        listEquals(other.commentIds, commentIds) &&
        other.id == id &&
        other.reshareCount == reshareCount &&
        other.retweetedBy == retweetedBy &&
        other.repliedTo == repliedTo &&
        other.quotedTweetId == quotedTweetId &&
        other.videoUrl == videoUrl &&
        other.gifUrl == gifUrl &&
        other.audioUrl == audioUrl &&
        other.locationData == locationData &&
        other.threadParentId == threadParentId &&
        listEquals(other.pollOptions, pollOptions) &&
        other.pollEndTime == pollEndTime &&
        other.audioRoomId == audioRoomId &&
        other.isAudioRoomActive == isAudioRoomActive &&
        listEquals(other.audioRoomParticipants, audioRoomParticipants);
  }

  @override
  int get hashCode {
    return text.hashCode ^
        hashtags.hashCode ^
        link.hashCode ^
        imageLinks.hashCode ^
        uid.hashCode ^
        tweetType.hashCode ^
        tweetedAt.hashCode ^
        likes.hashCode ^
        commentIds.hashCode ^
        id.hashCode ^
        reshareCount.hashCode ^
        retweetedBy.hashCode ^
        repliedTo.hashCode ^
        quotedTweetId.hashCode ^
        videoUrl.hashCode ^
        gifUrl.hashCode ^
        audioUrl.hashCode ^
        locationData.hashCode ^
        threadParentId.hashCode ^
        pollOptions.hashCode ^
        pollEndTime.hashCode ^
        audioRoomId.hashCode ^
        isAudioRoomActive.hashCode ^
        audioRoomParticipants.hashCode;
  }
}
