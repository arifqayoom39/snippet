import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/features/tweet/widgets/tweet_card.dart';
import 'package:snippet/models/tweet_model.dart';

class TweetSearchTile extends ConsumerWidget {
  final Tweet tweet;

  const TweetSearchTile({
    Key? key,
    required this.tweet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the existing tweet card component for consistent UI
    return tweetCard(tweet: tweet);
  }
}
