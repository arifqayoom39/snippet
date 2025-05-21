import 'dart:convert';

class TweetAnalytics {
  final String tweetId;
  final int impressions;
  final int profileClicks;
  final int linkClicks;
  final int mediaViews;
  final int detailExpansions;
  final List<String> viewerIds;
  final Map<String, int> hourlyImpressions;
  final Map<String, int> dailyImpressions;
  final Map<String, int> deviceTypes;
  final Map<String, int> regionCounts;
  final DateTime createdAt;
  final DateTime lastUpdated;
  
  TweetAnalytics({
    required this.tweetId,
    required this.impressions,
    required this.profileClicks,
    required this.linkClicks,
    required this.mediaViews,
    required this.detailExpansions,
    required this.viewerIds,
    required this.hourlyImpressions,
    required this.dailyImpressions,
    required this.deviceTypes,
    required this.regionCounts,
    required this.createdAt,
    required this.lastUpdated,
  });

  TweetAnalytics copyWith({
    String? tweetId,
    int? impressions,
    int? profileClicks,
    int? linkClicks,
    int? mediaViews,
    int? detailExpansions,
    List<String>? viewerIds,
    Map<String, int>? hourlyImpressions,
    Map<String, int>? dailyImpressions,
    Map<String, int>? deviceTypes,
    Map<String, int>? regionCounts,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return TweetAnalytics(
      tweetId: tweetId ?? this.tweetId,
      impressions: impressions ?? this.impressions,
      profileClicks: profileClicks ?? this.profileClicks,
      linkClicks: linkClicks ?? this.linkClicks,
      mediaViews: mediaViews ?? this.mediaViews,
      detailExpansions: detailExpansions ?? this.detailExpansions,
      viewerIds: viewerIds ?? this.viewerIds,
      hourlyImpressions: hourlyImpressions ?? this.hourlyImpressions,
      dailyImpressions: dailyImpressions ?? this.dailyImpressions,
      deviceTypes: deviceTypes ?? this.deviceTypes,
      regionCounts: regionCounts ?? this.regionCounts,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tweetId': tweetId,
      'impressions': impressions,
      'profileClicks': profileClicks,
      'linkClicks': linkClicks,
      'mediaViews': mediaViews,
      'detailExpansions': detailExpansions,
      'viewerIds': viewerIds,
      'hourlyImpressions': hourlyImpressions,
      'dailyImpressions': dailyImpressions,
      'deviceTypes': deviceTypes,
      'regionCounts': regionCounts,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  factory TweetAnalytics.fromMap(Map<String, dynamic> map) {
    return TweetAnalytics(
      tweetId: map['tweetId'] ?? '',
      impressions: map['impressions']?.toInt() ?? 0,
      profileClicks: map['profileClicks']?.toInt() ?? 0,
      linkClicks: map['linkClicks']?.toInt() ?? 0,
      mediaViews: map['mediaViews']?.toInt() ?? 0,
      detailExpansions: map['detailExpansions']?.toInt() ?? 0,
      viewerIds: List<String>.from(map['viewerIds'] ?? []),
      hourlyImpressions: Map<String, int>.from(map['hourlyImpressions'] ?? {}),
      dailyImpressions: Map<String, int>.from(map['dailyImpressions'] ?? {}),
      deviceTypes: Map<String, int>.from(map['deviceTypes'] ?? {}),
      regionCounts: Map<String, int>.from(map['regionCounts'] ?? {}),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'] ?? 0),
    );
  }

  String toJson() => json.encode(toMap());

  factory TweetAnalytics.fromJson(String source) => TweetAnalytics.fromMap(json.decode(source));

  // Analytics-specific methods
  int get uniqueViewers => viewerIds.length;
  
  double get engagementRate {
    final totalEngagements = profileClicks + linkClicks + mediaViews + detailExpansions;
    return impressions > 0 ? (totalEngagements / impressions) * 100 : 0;
  }
  
  Map<String, double> get hourlyDistribution {
    final result = <String, double>{};
    final totalImpressions = hourlyImpressions.values.fold(0, (sum, count) => sum + count);
    
    if (totalImpressions > 0) {
      hourlyImpressions.forEach((hour, count) {
        result[hour] = (count / totalImpressions) * 100;
      });
    }
    
    return result;
  }
  
  List<MapEntry<String, int>> get sortedHourlyImpressions {
    final entries = hourlyImpressions.entries.toList();
    // Sort by hour
    entries.sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));
    return entries;
  }
  
  List<MapEntry<String, int>> get sortedDailyImpressions {
    final entries = dailyImpressions.entries.toList();
    // Sort by day
    entries.sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));
    return entries;
  }
}
