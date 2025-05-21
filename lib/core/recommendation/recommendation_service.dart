import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/apis/tweet_api.dart';
import 'package:snippet/apis/user_api.dart';
import 'package:snippet/models/tweet_model.dart';
import 'package:snippet/models/user_model.dart';

// Provider for the recommendation service
final recommendationServiceProvider = Provider((ref) {
  return RecommendationService(
    tweetAPI: ref.watch(tweetAPIProvider),
    userAPI: ref.watch(userAPIProvider),
  );
});

class RecommendationService {
  final TweetAPI _tweetAPI;
  final UserAPI _userAPI;

  RecommendationService({
    required TweetAPI tweetAPI,
    required UserAPI userAPI,
  })  : _tweetAPI = tweetAPI,
        _userAPI = userAPI;

  // Infer user interests based on their activity
  Map<String, double> inferUserInterests(UserModel user, List<Tweet> userLikedTweets) {
    Map<String, double> interests = {};
    
    print('DEBUG: Inferring interests for user ${user.name} from ${userLikedTweets.length} liked tweets');
    
    // Extract interests from hashtags in liked tweets
    for (final tweet in userLikedTweets) {
      for (final hashtag in tweet.hashtags) {
        // Remove # symbol and normalize
        final topic = hashtag.replaceAll('#', '').toLowerCase();
        interests[topic] = (interests[topic] ?? 0) + 1.0;
      }
      
      // Extract topics from tweet text (simple keyword extraction)
      final words = tweet.text.toLowerCase().split(' ');
      for (final word in words) {
        if (word.length > 5 && !word.startsWith('http')) { // Filter out short words and links
          interests[word] = (interests[word] ?? 0) + 0.5; // Lower weight than hashtags
        }
      }
    }
    
    // Consider followers' interests too (people you follow suggest interests)
    if (user.following.isNotEmpty) {
      print('DEBUG: Also considering interests from ${user.following.length} followed users');
    }
    
    // Normalize interest scores
    final totalScore = interests.values.fold<double>(0, (sum, score) => sum + score);
    if (totalScore > 0) {
      interests.forEach((topic, score) {
        interests[topic] = score / totalScore;
      });
    }
    
    // Log top interests for debugging
    final topInterests = Map.fromEntries(
      interests.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(5)
    );
    
    print('DEBUG: Top interests for ${user.name}: $topInterests');
    
    return interests;
  }

  // Score a tweet based on user interests
  double scoreTweet(Tweet tweet, UserModel currentUser, Map<String, double> userInterests) {
    double score = 0.0;
    List<String> scoreFactors = [];
    
    // Base score - recency (0-1 scale, newer is higher)
    final now = DateTime.now();
    final hoursAgo = now.difference(tweet.tweetedAt).inHours;
    final recencyScore = 1.0 / (1 + (hoursAgo / 24)); // Decay over time
    score += recencyScore * 2.0; // Base weight for recency
    scoreFactors.add('recency: +${(recencyScore * 2.0).toStringAsFixed(1)}');
    
    // Interest match from hashtags
    double hashtagMatchScore = 0.0;
    for (final hashtag in tweet.hashtags) {
      final topic = hashtag.replaceAll('#', '').toLowerCase();
      if (userInterests.containsKey(topic)) {
        final matchScore = userInterests[topic]! * 3.0;
        hashtagMatchScore += matchScore;
        scoreFactors.add('hashtag $topic: +${matchScore.toStringAsFixed(1)}');
      }
    }
    score += hashtagMatchScore;
    
    // Text content match
    double contentMatchScore = 0.0;
    final words = tweet.text.toLowerCase().split(' ');
    for (final word in words) {
      if (userInterests.containsKey(word)) {
        final matchScore = userInterests[word]! * 1.5;
        contentMatchScore += matchScore;
        scoreFactors.add('keyword $word: +${matchScore.toStringAsFixed(1)}');
      }
    }
    score += contentMatchScore;
    
    // Engagement score
    final engagementScore = (tweet.likes.length + tweet.commentIds.length + tweet.reshareCount) / 10.0;
    final cappedEngagementScore = engagementScore.clamp(0.0, 3.0); // Cap very viral posts
    score += cappedEngagementScore;
    scoreFactors.add('engagement: +${cappedEngagementScore.toStringAsFixed(1)}');
    
    // Network score (content from followed users)
    if (currentUser.following.contains(tweet.uid)) {
      score += 1.5; // Boost content from followed users
      scoreFactors.add('following: +1.5');
    }
    
    // Author interactions (if user frequently interacts with this author)
    if (tweet.likes.contains(currentUser.uid)) {
      score += 0.5; // Already liked
      scoreFactors.add('already liked: +0.5');
    }
    
    // Content freshness bias
    if (hoursAgo < 6) {
      score += 1.0; // Boost very fresh content
      scoreFactors.add('fresh content: +1.0');
    }
    
    // Log scoring details for debugging
    if (score > 5.0) { // Only log high-scoring tweets to reduce noise
      print('DEBUG: Tweet "${tweet.text.substring(0, tweet.text.length.clamp(0, 30))}..." score: $score');
      print('DEBUG: Score factors: ${scoreFactors.join(', ')}');
    }
    
    return score;
  }

  // Get recommended users to follow based on shared interests
  Future<List<UserModel>> getRecommendedUsersToFollow(
    UserModel currentUser, 
    Map<String, double> userInterests,
    {int limit = 10}
  ) async {
    try {
      // Get a sample of users to analyze
      final users = await _userAPI.getUsers(limit: 50);
      
      // Convert to UserModel objects
      final userModels = users.map((doc) => UserModel.fromMap(doc.data)).toList();
      
      // Filter out users already being followed and the current user
      final filteredUsers = userModels.where((user) => 
        user.uid != currentUser.uid && 
        !currentUser.following.contains(user.uid)
      ).toList();
      
      // Score each user based on relevance to current user
      List<Map<String, dynamic>> scoredUsers = [];
      
      for (final user in filteredUsers) {
        double score = 0.0;
        
        // Score based on shared followers/following
        for (final followerId in user.followers) {
          if (currentUser.following.contains(followerId)) {
            // Users that current user follows also follow this user
            score += 0.5;
          }
        }
        
        for (final followingId in user.following) {
          if (currentUser.following.contains(followingId)) {
            // This user follows the same people as current user
            score += 0.3;
          }
        }
        
        // Extract bio keywords and match against interests
        final bioWords = user.bio.toLowerCase().split(' ');
        for (final word in bioWords) {
          if (userInterests.containsKey(word) && word.length > 4) {
            score += userInterests[word]! * 2.0;
          }
        }
        
        // Active users get a boost
        if (user.followers.length > 5) {
          score += 1.0;
        }
        
        scoredUsers.add({
          'user': user,
          'score': score,
          'reason': _determineRecommendationReason(user, currentUser, score),
        });
      }
      
      // Sort by score
      scoredUsers.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
      
      // Return top recommendations with reasons
      return scoredUsers.take(limit).map((item) {
        final user = item['user'] as UserModel;
        // Add recommendation reason to user metadata
        return user.copyWith(
          bio: "${user.bio}\n\n${item['reason'] as String}",
        );
      }).toList();
    } catch (e) {
      print('Error getting recommended users: $e');
      return [];
    }
  }
  
  // Determine why a user is being recommended
  String _determineRecommendationReason(
    UserModel recommendedUser, 
    UserModel currentUser,
    double score
  ) {
    // Find mutual connections
    final mutualFollowing = recommendedUser.following
        .where((id) => currentUser.following.contains(id))
        .length;
    
    if (mutualFollowing > 0) {
      return "Based on $mutualFollowing mutual connections";
    }
    
    // Check if they have similar interests (based on bio keywords)
    final currentUserBioWords = currentUser.bio.toLowerCase().split(' ')
        .where((word) => word.length > 4)
        .toSet();
    
    final recommendedUserBioWords = recommendedUser.bio.toLowerCase().split(' ')
        .where((word) => word.length > 4)
        .toSet();
    
    final commonWords = currentUserBioWords.intersection(recommendedUserBioWords);
    
    if (commonWords.isNotEmpty) {
      return "Has similar interests to you";
    }
    
    // Default reason
    return "Popular in your network";
  }
}
