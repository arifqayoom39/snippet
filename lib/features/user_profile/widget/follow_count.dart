import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/features/user_profile/view/follow_list_view.dart';
import 'package:snippet/models/user_model.dart';
import 'package:snippet/theme/pallete.dart';

class FollowCount extends ConsumerWidget {
  final UserModel user;

  const FollowCount({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              FollowListView.route(
                user: user,
                type: FollowListType.following,
              ),
            );
          },
          child: Row(
            children: [
              Text(
                '${user.following.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Pallete.textColor,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                'Following',
                style: TextStyle(
                  fontSize: 16,
                  color: Pallete.greyColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              FollowListView.route(
                user: user,
                type: FollowListType.followers,
              ),
            );
          },
          child: Row(
            children: [
              Text(
                '${user.followers.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Pallete.textColor,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                'Followers',
                style: TextStyle(
                  fontSize: 16,
                  color: Pallete.greyColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
