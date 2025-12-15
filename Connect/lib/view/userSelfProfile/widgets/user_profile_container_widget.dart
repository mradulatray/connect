import 'package:connectapp/res/routes/routes_name.dart';
import 'package:connectapp/view_models/controller/profile/user_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/response/status.dart';
import '../../../res/assets/image_assets.dart';
import '../../../res/color/app_colors.dart';
import '../../../res/fonts/app_fonts.dart';
import '../../../view_models/CREATORPANEL/CreatorController/creator_controller.dart';
import '../../../view_models/CREATORPANEL/CreatorController/switch_creator_controller.dart';

class UserProfileContainerWidget extends StatelessWidget {
  const UserProfileContainerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final userData = Get.put(UserProfileController());
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    Orientation orientation = MediaQuery.of(context).orientation;
    Get.put(CreatorController());
    Get.put(CreatorModeController());
    return RefreshIndicator(
      onRefresh: () async {
        userData.refreshApi();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.02),
              ListTile(
                leading: IconButton(
                  onPressed: () {
                    Get.back();
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                trailing: IconButton(
                  onPressed: () {
                    Get.toNamed(
                      RouteName.settingScreen,
                    );
                  },
                  icon: Icon(
                    Icons.settings,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Obx(() {
                    switch (userData.rxRequestStatus.value) {
                      case Status.LOADING:
                        return Text(
                          "Loading...",
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: AppFonts.opensansRegular,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        );
                      case Status.ERROR:
                        return CircleAvatar(
                          radius: 25,
                          child: IconButton(
                            onPressed: () {
                              Get.toNamed(RouteName.profileScreen);
                            },
                            icon: Image.asset(
                              ImageAssets.profileIcon,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );

                      case Status.COMPLETED:
                        final imageUrl =
                            userData.userList.value.avatar?.imageUrl;
                        return IconButton(
                          onPressed: () {
                            Get.toNamed(RouteName.profileScreen);
                          },
                          icon: imageUrl?.isNotEmpty == true
                              ? ClipOval(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(60),
                                      color: Colors.tealAccent,
                                      border: Border.all(
                                          color: AppColors.blackColor,
                                          width: 2),
                                    ),
                                    child: Image.network(
                                      imageUrl!,
                                      fit: BoxFit.cover,
                                      height:
                                          orientation == Orientation.portrait
                                              ? screenHeight * 0.1
                                              : screenHeight * 0.2,
                                      width: orientation == Orientation.portrait
                                          ? screenWidth * 0.2
                                          : screenWidth * 0.11,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Image.asset(
                                          ImageAssets.profileIcon,
                                          fit: BoxFit.cover,
                                          width: screenHeight * 0.1,
                                          height: screenHeight * 0.1,
                                        );
                                      },
                                    ),
                                  ),
                                )
                              : Image.asset(
                                  ImageAssets.profileIcon,
                                  fit: BoxFit.cover,
                                  width: 50,
                                  height: 50,
                                ),
                        );
                    }
                  }),
                ],
              ),
              Obx(() {
                switch (userData.rxRequestStatus.value) {
                  case Status.LOADING:
                    return Text(
                      "Loading...",
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: AppFonts.opensansRegular,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    );
                  case Status.ERROR:
                    return Text(
                      "No Name",
                      style: TextStyle(
                        fontFamily: AppFonts.opensansRegular,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    );
                  case Status.COMPLETED:
                    return Text(
                      userData.userList.value.fullName!,
                      style: TextStyle(
                        fontSize: 25,
                        fontFamily: AppFonts.helveticaBold,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    );
                }
              }),
              Obx(() {
                switch (userData.rxRequestStatus.value) {
                  case Status.LOADING:
                    return Text(
                      "Loading...",
                      style: TextStyle(
                        fontSize: 17,
                        fontFamily: AppFonts.opensansRegular,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    );
                  case Status.ERROR:
                    return const Text("Null");
                  case Status.COMPLETED:
                    return (userData.userList.value.subscription?.status ==
                            "Active")
                        ? Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: const Color.fromARGB(255, 221, 199, 2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '@${userData.userList.value.username}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: AppFonts.opensansRegular,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.redColor,
                                  ),
                                ),
                                if (userData.userList.value.subscriptionFeatures
                                            ?.premiumIconUrl !=
                                        null &&
                                    userData
                                        .userList
                                        .value
                                        .subscriptionFeatures!
                                        .premiumIconUrl!
                                        .isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: Image.network(
                                      userData
                                          .userList
                                          .value
                                          .subscriptionFeatures!
                                          .premiumIconUrl!,
                                      width: screenWidth * 0.05,
                                      height: screenHeight * 0.02,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ),
                              ],
                            ))
                        : Text(
                            '@${userData.userList.value.username}',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: AppFonts.opensansRegular,
                              fontWeight: FontWeight.bold,
                              color: AppColors.redColor,
                            ),
                          );
                }
              }),
              SizedBox(height: screenHeight * 0.03),
              Obx(() {
                final profile = userData.userList.value;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStat("${profile.totalPost ?? 0}", "Clips"),
                    const SizedBox(width: 15),
                    InkWell(
                        onTap: () {
                          Get.toNamed(RouteName.allFollowersScreen);
                        },
                        child: _buildStat(
                            "${profile.followerCount ?? 0}", "Followers")),
                    const SizedBox(width: 15),
                    InkWell(
                        onTap: () {
                          Get.toNamed(RouteName.allFollowersScreen);
                        },
                        child: _buildStat(
                            "${profile.followingCount ?? 0}", "Following")),
                    const SizedBox(width: 15),
                    _buildStat("${profile.totalLikes ?? 0}", "Total Likes"),
                  ],
                );
              }),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  InkWell(
                    onTap: () {
                      Get.toNamed(RouteName.editProfileScreen);
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppColors.blueColor,
                          borderRadius: BorderRadius.circular(5),
                          gradient: AppColors.primaryGradient),
                      child: Text(
                        'Edit Profile',
                        style: TextStyle(
                            fontSize: 14,
                            fontFamily: AppFonts.opensansRegular,
                            color: AppColors.whiteColor),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Get.toNamed(RouteName.allAvatarsScreen);
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        color: AppColors.blueColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'All Avatar',
                        style: TextStyle(
                            fontSize: 14,
                            fontFamily: AppFonts.opensansRegular,
                            color: AppColors.whiteColor),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Get.toNamed(RouteName.usersAvatarScreen);
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(5),
                        color: AppColors.blueColor,
                      ),
                      child: Text(
                        'My Avatar',
                        style: TextStyle(
                            fontSize: 14,
                            fontFamily: AppFonts.opensansRegular,
                            color: AppColors.whiteColor),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildStat(
    String value,
    String label,
  ) {
    return Container(
      width: 75,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: AppFonts.opensansRegular),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFamily: AppFonts.opensansRegular),
          ),
        ],
      ),
    );
  }
}
