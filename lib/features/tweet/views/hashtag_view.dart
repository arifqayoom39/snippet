import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/common/common.dart';
import 'package:snippet/features/tweet/controller/tweet_controller.dart';
import 'package:snippet/features/tweet/widgets/tweet_card.dart';
import 'package:snippet/theme/pallete.dart';

class HashtagView extends ConsumerWidget {
  static route(String hashtag) => MaterialPageRoute(
        builder: (context) => HashtagView(
          hashtag: hashtag,
        ),
      );

  final String hashtag;
  
  const HashtagView({
    Key? key,
    required this.hashtag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '#$hashtag',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: ref.watch(getTweetsByHashtagProvider(hashtag)).when(
            data: (tweets) {
              if (tweets.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.tag,
                        size: 50,
                        color: Pallete.greyColor,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No tweets with #$hashtag yet',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Pallete.greyColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Be the first to tweet with this hashtag',
                        style: TextStyle(
                          color: Pallete.greyColor,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                itemCount: tweets.length,
                itemBuilder: (context, index) {
                  final tweet = tweets[index];
                  return tweetCard(tweet: tweet);
                },
              );
            },
            error: (error, stackTrace) => ErrorText(
              error: error.toString(),
            ),
            loading: () => const Loader(),
          ),
    );
  }
}
