import 'package:connectapp/res/custom_widgets/custome_appbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/response/status.dart';
import '../../models/AllFollowers/all_followers_model.dart';
import '../../models/AllFollowing/all_following_model.dart';
import '../../res/color/app_colors.dart';
import '../../res/fonts/app_fonts.dart';
import '../../view_models/controller/allFollowers/all_followers_controller.dart';
import '../../view_models/controller/allFollowings/all_followings_controller.dart';
import '../../view_models/controller/follow/user_follow_controller.dart'; // Adjust path to FollowUnfollowController
import 'package:cached_network_image/cached_network_image.dart';

class FollowersFollowingScreen extends StatefulWidget {
  const FollowersFollowingScreen({super.key});

  @override
  State<FollowersFollowingScreen> createState() =>
      _FollowersFollowingScreenState();
}

class _FollowersFollowingScreenState extends State<FollowersFollowingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final AllFollowersController followersController =
      Get.put(AllFollowersController());
  final AllFollowingsController followingsController =
      Get.put(AllFollowingsController());
  final FollowUnfollowController followUnfollowController =
      Get.put(FollowUnfollowController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        automaticallyImplyLeading: true,
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(
                      color: Colors.grey, fontFamily: AppFonts.opensansRegular),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.greyColor.withOpacity(0.4),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.blue,
              indicatorWeight: 2,
              labelColor: AppColors.textColor,
              unselectedLabelColor: Colors.grey,
              unselectedLabelStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: AppFonts.opensansRegular,
              ),
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: AppFonts.opensansRegular,
              ),
              tabs: const [
                Tab(text: 'Followers'),
                Tab(text: 'Following'),
              ],
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFollowersList(),
                  _buildFollowingList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowersList() {
    return Obx(() {
      switch (followersController.rxRequestStatus.value) {
        case Status.LOADING:
          return const Center(child: CircularProgressIndicator());
        case Status.ERROR:
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  followersController.error.value,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: followersController.fetchFollowers,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        case Status.COMPLETED:
          final allFollowers = followersController.followers;
          final filteredFollowers = allFollowers.where((followerItem) {
            final follower = followerItem.follower;
            if (follower == null) return false;
            final name = follower.fullName?.toLowerCase() ?? '';
            final username = follower.username?.toLowerCase() ?? '';
            return name.contains(_searchQuery) ||
                username.contains(_searchQuery);
          }).toList();

          if (filteredFollowers.isEmpty) {
            return Center(
              child: Text(
                _searchQuery.isEmpty
                    ? 'No followers found'
                    : 'No matching followers',
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontFamily: AppFonts.opensansRegular),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: followersController.refreshFollowers,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredFollowers.length,
              itemBuilder: (context, index) {
                final followerItem = filteredFollowers[index];
                final user = followerItem.follower;
                if (user == null) return const SizedBox.shrink();
                return _buildUserCard(user, showUnfollow: false);
              },
            ),
          );
      }
    });
  }

  Widget _buildFollowingList() {
    return Obx(() {
      switch (followingsController.rxRequestStatus.value) {
        case Status.LOADING:
          return const Center(child: CircularProgressIndicator());
        case Status.ERROR:
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  followingsController.error.value,
                  style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontFamily: AppFonts.opensansRegular),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: followingsController.fetchFollowings,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        case Status.COMPLETED:
          final allFollowings = followingsController.followings;
          final filteredFollowings = allFollowings.where((followingItem) {
            final followingUser = followingItem.following;
            if (followingUser == null) return false;
            final name = followingUser.fullName?.toLowerCase() ?? '';
            final username = followingUser.username?.toLowerCase() ?? '';
            return name.contains(_searchQuery) ||
                username.contains(_searchQuery);
          }).toList();

          if (filteredFollowings.isEmpty) {
            return Center(
              child: Text(
                _searchQuery.isEmpty
                    ? 'No following found'
                    : 'No matching following',
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontFamily: AppFonts.opensansRegular),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: followingsController.refreshFollowings,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredFollowings.length,
              itemBuilder: (context, index) {
                final followingItem = filteredFollowings[index];
                final user = followingItem.following;
                if (user == null) return const SizedBox.shrink();
                return _buildUserCardForFollowing(user, showUnfollow: true);
              },
            ),
          );
      }
    });
  }

  Widget _buildUserCard(Follower user, {required bool showUnfollow}) {
    final initials = user.fullName
            ?.split(' ')
            .map((s) => s.isNotEmpty ? s[0].toUpperCase() : '')
            .take(2)
            .join() ??
        'U';
    final hasAvatar =
        user.avatar?.imageUrl != null && user.avatar!.imageUrl!.isNotEmpty;

    return Container(
      // color: Theme.of(context).scaffoldBackgroundColor,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.greyColor.withOpacity(0.4),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundImage:
                hasAvatar ? CachedNetworkImageProvider(user.avatar!.imageUrl!) : null,
            backgroundColor: Colors.teal,
            child: hasAvatar
                ? null
                : Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppFonts.opensansRegular,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(width: 12),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppFonts.opensansRegular),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${user.username ?? ''}',
                  style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontFamily: AppFonts.opensansRegular),
                ),
              ],
            ),
          ),

          // Unfollow Button
          if (showUnfollow)
            ElevatedButton(
              onPressed: () {
                // Handle unfollow
                _handleUnfollow(user.id ?? '');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Unfollow',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: AppFonts.opensansRegular),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserCardForFollowing(Followings user,
      {required bool showUnfollow}) {
    final initials = user.fullName
            ?.split(' ')
            .map((s) => s.isNotEmpty ? s[0].toUpperCase() : '')
            .take(2)
            .join() ??
        'U';
    final hasAvatar =
        user.avatar?.imageUrl != null && user.avatar!.imageUrl!.isNotEmpty;
    final userId = user.id ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.greyColor.withOpacity(0.4),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundImage:
                hasAvatar ? CachedNetworkImageProvider(user.avatar!.imageUrl!) : null,
            backgroundColor: Colors.teal,
            child: hasAvatar
                ? null
                : Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppFonts.opensansRegular,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(width: 12),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppFonts.opensansRegular),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${user.username ?? ''}',
                  style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontFamily: AppFonts.opensansRegular),
                ),
              ],
            ),
          ),

          // Unfollow Button
          if (showUnfollow)
            Obx(
              () => ElevatedButton(
                onPressed: followUnfollowController.isLoadingUser(userId)
                    ? null
                    : () async {
                        await _handleUnfollow(userId);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: followUnfollowController.isLoadingUser(userId)
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Unfollow',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFamily: AppFonts.opensansRegular),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleUnfollow(String userId) async {
    final success = await followUnfollowController.unfollowUser(userId);
    if (success) {
      // Refresh the following list after successful unfollow
      await followingsController.refreshFollowings();
    }
  }
}
