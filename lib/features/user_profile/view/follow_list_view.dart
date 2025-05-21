import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/common/common.dart';
import 'package:snippet/features/user_profile/controller/user_profile_controller.dart';
import 'package:snippet/features/user_profile/widget/user_list_tile.dart';
import 'package:snippet/models/user_model.dart';
import 'package:snippet/theme/pallete.dart';

enum FollowListType { followers, following }

class FollowListView extends ConsumerWidget {
  static route({
    required UserModel user,
    required FollowListType type,
  }) =>
      MaterialPageRoute(
        builder: (context) => FollowListView(
          user: user,
          type: type,
        ),
      );

  final UserModel user;
  final FollowListType type;

  const FollowListView({
    Key? key,
    required this.user,
    required this.type,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String title = type == FollowListType.followers ? 'Followers' : 'Following';
    final String param = "${user.uid}:${type == FollowListType.followers ? 'followers' : 'following'}";

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: ref.watch(getUserFollowListProvider(param)).when(
            data: (users) {
              if (users.isEmpty) {
                return Center(
                  child: Text(
                    type == FollowListType.followers
                        ? '${user.name} has no followers yet'
                        : '${user.name} isn\'t following anyone',
                    style: TextStyle(
                      color: Pallete.greyColor,
                      fontSize: 16,
                    ),
                  ),
                );
              }
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final followUser = users[index];
                  return UserListTile(user: followUser);
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
