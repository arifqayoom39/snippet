import 'package:flutter/foundation.dart';

@immutable
class UserModel {
  final String email;
  final String name;
  final String username;
  final List<String> followers;
  final List<String> following;
  final String profilePic;
  final String bannerPic;
  final String uid;
  final String bio;
  final bool istweetBlue;
  final String oneSignalId;
  final String affiliatedUserId; // Added affiliated user ID

  const UserModel({
    required this.email,
    required this.name,
    this.username = '',
    required this.followers,
    required this.following,
    required this.profilePic,
    required this.bannerPic,
    required this.uid,
    required this.bio,
    required this.istweetBlue,
    this.oneSignalId = '',
    this.affiliatedUserId = '', // Default empty string
  });

  UserModel copyWith({
    String? email,
    String? name,
    String? username,
    List<String>? followers,
    List<String>? following,
    String? profilePic,
    String? bannerPic,
    String? uid,
    String? bio,
    bool? istweetBlue,
    String? oneSignalId,
    String? affiliatedUserId,
  }) {
    return UserModel(
      email: email ?? this.email,
      name: name ?? this.name,
      username: username ?? this.username,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      profilePic: profilePic ?? this.profilePic,
      bannerPic: bannerPic ?? this.bannerPic,
      uid: uid ?? this.uid,
      bio: bio ?? this.bio,
      istweetBlue: istweetBlue ?? this.istweetBlue,
      oneSignalId: oneSignalId ?? this.oneSignalId,
      affiliatedUserId: affiliatedUserId ?? this.affiliatedUserId,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'email': email});
    result.addAll({'name': name});
    result.addAll({'username': username});
    result.addAll({'followers': followers});
    result.addAll({'following': following});
    result.addAll({'profilePic': profilePic});
    result.addAll({'bannerPic': bannerPic});
    result.addAll({'bio': bio});
    result.addAll({'istweetBlue': istweetBlue});
    result.addAll({'oneSignalId': oneSignalId});
    result.addAll({'affiliatedUserId': affiliatedUserId}); // Add to map

    return result;
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      followers: List<String>.from(map['followers']),
      following: List<String>.from(map['following']),
      profilePic: map['profilePic'] ?? '',
      bannerPic: map['bannerPic'] ?? '',
      uid: map['\$id'] ?? '',
      bio: map['bio'] ?? '',
      istweetBlue: map['istweetBlue'] ?? false,
      oneSignalId: map['oneSignalId'] ?? '',
      affiliatedUserId: map['affiliatedUserId'] ?? '', // Parse from map
    );
  }

  @override
  String toString() {
    return 'UserModel(email: $email, name: $name, username: $username, followers: $followers, following: $following, profilePic: $profilePic, bannerPic: $bannerPic, uid: $uid, bio: $bio, istweetBlue: $istweetBlue, oneSignalId: $oneSignalId, affiliatedUserId: $affiliatedUserId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.email == email &&
        other.name == name &&
        other.username == username &&
        listEquals(other.followers, followers) &&
        listEquals(other.following, following) &&
        other.profilePic == profilePic &&
        other.bannerPic == bannerPic &&
        other.uid == uid &&
        other.bio == bio &&
        other.istweetBlue == istweetBlue &&
        other.oneSignalId == oneSignalId &&
        other.affiliatedUserId == affiliatedUserId;
  }

  @override
  int get hashCode {
    return email.hashCode ^
        name.hashCode ^
        username.hashCode ^
        followers.hashCode ^
        following.hashCode ^
        profilePic.hashCode ^
        bannerPic.hashCode ^
        uid.hashCode ^
        bio.hashCode ^
        istweetBlue.hashCode ^
        oneSignalId.hashCode ^
        affiliatedUserId.hashCode;
  }
}
