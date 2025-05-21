import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/apis/user_api.dart';
import 'package:snippet/models/user_model.dart';
import 'package:snippet/core/recommendation/recommendation_service.dart';
import 'package:snippet/features/auth/controller/auth_controller.dart';

final exploreControllerProvider = StateNotifierProvider<ExploreController, bool>((ref) {
  return ExploreController(
    userAPI: ref.watch(userAPIProvider),
  );
});

final searchUserProvider = FutureProvider.family((ref, String name) async {
  final exploreController = ref.watch(exploreControllerProvider.notifier);
  return exploreController.searchUser(name);
});

final userListProvider = StateNotifierProvider<UserListNotifier, List<UserModel>>((ref) {
  final userAPI = ref.watch(userAPIProvider);
  return UserListNotifier(userAPI: userAPI);
});

// Provider for suggested users (who to follow)
final suggestedUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  // Get the first batch of users from userListProvider
  final allUsers = await ref.watch(userListProvider.notifier).getInitialUsers();
  
  // Shuffle the list to get random suggestions
  allUsers.shuffle();
  
  // Return up to 5 users for suggestions
  return allUsers.take(5).toList();
});

// Provider for recommended users based on the recommendation service
final recommendedUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final userAPI = ref.watch(userAPIProvider);
  final recommendationService = ref.watch(recommendationServiceProvider);
  final currentUser = ref.watch(currentUserDetailsProvider).value;
  
  if (currentUser == null) {
    return ref.watch(suggestedUsersProvider).value ?? [];
  }
  
  // Basic interests map from user profile
  Map<String, double> userInterests = {};
  
  // Extract possible interests from bio
  final bioWords = currentUser.bio.toLowerCase().split(' ');
  for (final word in bioWords) {
    if (word.length > 4) {
      userInterests[word] = (userInterests[word] ?? 0) + 1.0;
    }
  }
  
  // If no interests found, use some defaults
  if (userInterests.isEmpty) {
    userInterests = {
      'technology': 1.0,
      'news': 0.8,
      'entertainment': 0.7,
    };
  }
  
  // Get recommended users
  return recommendationService.getRecommendedUsersToFollow(
    currentUser,
    userInterests,
    limit: 10
  );
});

class UserListNotifier extends StateNotifier<List<UserModel>> {
  final UserAPI _userAPI;
  int _currentPage = 0;
  static const int _limit = 10;
  bool _isLoading = false;
  bool _hasMore = true;

  UserListNotifier({required UserAPI userAPI})
      : _userAPI = userAPI,
        super([]) {
    loadInitialUsers();
  }

  Future<void> loadInitialUsers() async {
    if (state.isNotEmpty) return;
    
    _currentPage = 0;
    final users = await _userAPI.getUsers(limit: _limit, offset: 0);
    state = users.map((doc) => UserModel.fromMap(doc.data)).toList();
    _hasMore = users.length >= _limit;
  }

  Future<void> loadMoreUsers() async {
    if (_isLoading || !_hasMore) return;
    
    _isLoading = true;
    _currentPage++;
    final offset = _currentPage * _limit;
    
    final users = await _userAPI.getUsers(limit: _limit, offset: offset);
    if (users.isEmpty) {
      _hasMore = false;
    } else {
      state = [...state, ...users.map((doc) => UserModel.fromMap(doc.data)).toList()];
      _hasMore = users.length >= _limit;
    }
    
    _isLoading = false;
  }

  Future<List<UserModel>> getInitialUsers() async {
    if (state.isEmpty) {
      await loadInitialUsers();
    }
    return state;
  }

  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
}

class ExploreController extends StateNotifier<bool> {
  final UserAPI _userAPI;
  ExploreController({
    required UserAPI userAPI,
  })  : _userAPI = userAPI,
        super(false);

  Future<List<UserModel>> searchUser(String name) async {
    final users = await _userAPI.searchUserByName(name);
    return users.map((e) => UserModel.fromMap(e.data)).toList();
  }
}
