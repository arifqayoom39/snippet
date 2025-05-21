import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/common/error_page.dart';
import 'package:snippet/common/loading_page.dart';
import 'package:snippet/features/explore/controller/explore_controller.dart';
import 'package:snippet/features/explore/widgets/search_tile.dart';
import 'package:snippet/features/explore/widgets/tweet_search_tile.dart';
import 'package:snippet/features/tweet/controller/tweet_controller.dart';
import 'package:snippet/theme/pallete.dart';

class ExploreView extends ConsumerStatefulWidget {
  const ExploreView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ExploreViewState();
}

class _ExploreViewState extends ConsumerState<ExploreView> with TickerProviderStateMixin {
  final searchController = TextEditingController();
  bool isSearchMode = false;
  final ScrollController _scrollController = ScrollController();
  TabController? _tabController;
  TabController? _suggestionsTabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _suggestionsTabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (!isSearchMode &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final userListNotifier = ref.read(userListProvider.notifier);
      if (!userListNotifier.isLoading && userListNotifier.hasMore) {
        userListNotifier.loadMoreUsers();
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _tabController?.dispose();
    _suggestionsTabController?.dispose();
    super.dispose();
  }

  void _startSearch(String value) {
    if (value.trim().isNotEmpty) {
      setState(() {
        isSearchMode = true;
      });
    } else {
      setState(() {
        isSearchMode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBarTextFieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(50),
      borderSide: BorderSide.none,
    );

    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      appBar: AppBar(
        backgroundColor: Pallete.backgroundColor,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: TextField(
            controller: searchController,
            onSubmitted: _startSearch,
            style: TextStyle(
              fontSize: 16,
              color: Pallete.textColor,
            ),
            cursorColor: Pallete.blueColor,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 16,
              ),
              fillColor: Pallete.searchBarColor,
              filled: true,
              enabledBorder: appBarTextFieldBorder,
              focusedBorder: appBarTextFieldBorder,
              hintText: 'Search Snippet',
              hintStyle: TextStyle(
                color: Pallete.greyColor.withOpacity(0.8),
              ),
              prefixIcon: Icon(Icons.search, color: Pallete.greyColor, size: 20),
              suffixIcon: searchController.text.isNotEmpty 
                ? IconButton(
                    icon: Icon(Icons.clear, color: Pallete.greyColor, size: 18),
                    onPressed: () {
                      searchController.clear();
                      setState(() {
                        isSearchMode = false;
                      });
                    },
                  )
                : null,
            ),
            onChanged: (value) {
              setState(() {
                // Force rebuild to show/hide clear button
              });
            },
          ),
        ),
        bottom: isSearchMode ? TabBar(
          controller: _tabController,
          labelColor: Pallete.blueColor,
          unselectedLabelColor: Pallete.greyColor,
          indicatorColor: Pallete.blueColor,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Top'),
            Tab(text: 'People'),
          ],
        ) : null,
      ),
      body: !isSearchMode 
        ? _buildSuggestionsView()
        : TabBarView(
            controller: _tabController,
            children: [
              _buildTweetSearchResults(),
              _buildUserSearchResults(),
            ],
          ),
    );
  }

  Widget _buildSuggestionsView() {
    return Column(
      children: [
        TabBar(
          controller: _suggestionsTabController,
          labelColor: Pallete.blueColor,
          unselectedLabelColor: Pallete.greyColor,
          indicatorColor: Pallete.blueColor,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'For you'),
            Tab(text: 'Users'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _suggestionsTabController,
            children: [
              _buildSuggestedTweets(),
              _buildSuggestedUsers(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestedTweets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ref.watch(rankedTweetsProvider).when(
            data: (tweets) {
              if (tweets.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: tweets.length,
                itemBuilder: (context, index) {
                  final tweet = tweets[index];
                  return Column(
                    children: [
                      if (index == 0)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: [
                              Icon(Icons.auto_awesome, size: 16, color: Pallete.blueColor),
                              const SizedBox(width: 4),
                              Text(
                                'Recommended for you',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Pallete.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      TweetSearchTile(tweet: tweet),
                    ],
                  );
                },
              );
            },
            error: (error, stack) => Center(
              child: Text(
                'Error loading recommendations',
                style: TextStyle(color: Pallete.textColor),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestedUsers() {
    return ref.watch(recommendedUsersProvider).when(
      data: (recommendedUsers) {
        if (recommendedUsers.isEmpty) {
          return _buildDefaultUsersList();
        }
        
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: Pallete.blueColor),
                  const SizedBox(width: 4),
                  Text(
                    'Recommended for you',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Pallete.textColor,
                    ),
                  ),
                ],
              ),
            ),
            ...recommendedUsers.map((user) => SearchTile(
              userModel: user,
              showRecommendationReason: true,
            )),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'People to follow',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Pallete.textColor,
                ),
              ),
            ),
            _buildDefaultUsersList(showHeader: false),
          ],
        );
      },
      error: (error, stack) => _buildDefaultUsersList(),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
  
  Widget _buildDefaultUsersList({bool showHeader = true}) {
    return Consumer(
      builder: (context, ref, child) {
        final userList = ref.watch(userListProvider);
        final isLoading = ref.watch(userListProvider.notifier).isLoading;

        if (userList.isEmpty && isLoading) {
          return const Loader();
        }

        if (userList.isEmpty) {
          return Center(
            child: Text(
              'No users available',
              style: TextStyle(color: Pallete.textColor),
            ),
          );
        }

        return ListView(
          controller: _scrollController,
          shrinkWrap: true,
          physics: showHeader ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            if (showHeader)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: Pallete.blueColor),
                    const SizedBox(width: 4),
                    Text(
                      'People to follow',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Pallete.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ...userList.map((user) => SearchTile(userModel: user)),
            if (ref.watch(userListProvider.notifier).hasMore)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildUserSearchResults() {
    return ref.watch(searchUserProvider(searchController.text)).when(
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Text(
              'No users found',
              style: TextStyle(color: Pallete.textColor),
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: users.length,
          itemBuilder: (BuildContext context, int index) {
            final user = users[index];
            return SearchTile(userModel: user);
          },
        );
      },
      error: (error, st) => ErrorText(
        error: error.toString(),
      ),
      loading: () => const Loader(),
    );
  }

  Widget _buildTweetSearchResults() {
    return ref.watch(searchTweetsProvider(searchController.text)).when(
      data: (tweets) {
        if (tweets.isEmpty) {
          return Center(
            child: Text(
              'No tweets found',
              style: TextStyle(color: Pallete.textColor),
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: tweets.length,
          itemBuilder: (BuildContext context, int index) {
            final tweet = tweets[index];
            return TweetSearchTile(tweet: tweet);
          },
        );
      },
      error: (error, st) => ErrorText(
        error: error.toString(),
      ),
      loading: () => const Loader(),
    );
  }
}
