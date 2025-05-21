import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/common/common.dart';
import 'package:snippet/features/bookmark/controller/bookmark_controller.dart';
import 'package:snippet/features/tweet/widgets/tweet_card.dart';
import 'package:snippet/theme/pallete.dart';

class BookmarksView extends ConsumerWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const BookmarksView(),
      );
      
  const BookmarksView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkedTweets = ref.watch(getBookmarkedTweetsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        centerTitle: true,
      ),
      body: bookmarkedTweets.when(
        data: (tweets) {
          if (tweets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.bookmark_border,
                    size: 50,
                    color: Pallete.greyColor,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'You haven\'t bookmarked any tweets yet',
                    style: TextStyle(
                      fontSize: 16,
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
