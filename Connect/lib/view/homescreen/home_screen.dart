import 'package:connectapp/res/assets/image_assets.dart';
import 'package:connectapp/res/custom_widgets/responsive_padding.dart';
import 'package:connectapp/res/routes/routes_name.dart';
import 'package:connectapp/view/homescreen/widgets/progress_container_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/response/status.dart';
import '../../res/color/app_colors.dart';
import '../../res/fonts/app_fonts.dart';
import '../../view_models/controller/leaderboard/user_leaderboard_controller.dart';
import '../../view_models/controller/notification/notification_controller.dart';
import '../../view_models/controller/profile/user_profile_controller.dart';
import '../settings/log_out_dialog_screen.dart';
import 'FullLeaderBoard/full_leaderboard_screen.dart';
import 'widgets/featured_course_widget.dart';
import 'widgets/stats_row_widget.dart';
import 'widgets/top_learner_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final userData = Get.put(UserProfileController());
  final userLeaderboardData = Get.put(UserLeaderboardController());
  final NotificationController controller = Get.find<NotificationController>();

  @override
  void initState() {
    super.initState();
    userData.userListApi();
  }

  Future<void> onRefresh() async {
    userData.userListApi();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidht = MediaQuery.of(context).size.width;
    Orientation orientation = MediaQuery.of(context).orientation;

    return Scaffold(
      // Add Drawer to Scaffold
      key: _scaffoldKey,
      drawer: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Drawer(
          backgroundColor: Colors.transparent,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(),
                child: Image.asset(ImageAssets.splashLogo),
              ),
              ListTile(
                leading: Icon(
                  Icons.add,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                title: Text(
                  'Create Avatar',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 15,
                    fontFamily: AppFonts.opensansRegular,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Get.toNamed(RouteName.avatarCreatorScreen);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.inventory_2_outlined,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                title: Text(
                  'Inventory',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 15,
                    fontFamily: AppFonts.opensansRegular,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Get.toNamed(RouteName.inventoryAvatarScreen);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.star_border,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                title: Text(
                  'Collection',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 15,
                    fontFamily: AppFonts.opensansRegular,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Get.toNamed(RouteName.myAvatarCollection);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.shop,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                title: Text(
                  'MarketPlace',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 15,
                    fontFamily: AppFonts.opensansRegular,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Get.toNamed(RouteName.myMarketPlaceAvatar);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: AppColors.redColor,
                ),
                title: Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: AppFonts.opensansRegular,
                  ),
                ),
                onTap: () {
                  debugPrint("============Home Page logout called");
                  showLogoutDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        toolbarHeight: 70,
        title: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.menu,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
            Obx(() {
              switch (userData.rxRequestStatus.value) {
                case Status.LOADING:
                  return SizedBox(
                    height: 40,
                    width: 40,
                    child: ClipOval(
                      child: Image.asset(
                        ImageAssets.defaultProfileImg,
                        height: orientation == Orientation.portrait
                            ? screenHeight * 0.1
                            : screenHeight * 0.2,
                        width: orientation == Orientation.portrait
                            ? screenWidht * 0.2
                            : screenWidht * 0.11,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );

                case Status.ERROR:
                  return CircleAvatar(
                    radius: 25,
                    child: IconButton(
                      onPressed: () {
                        Get.toNamed(RouteName.profileScreen);
                      },
                      icon: Image.asset(ImageAssets.profileIcon),
                    ),
                  );

                case Status.COMPLETED:
                  final imageUrl = userData.userList.value.avatar?.imageUrl;
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
                                    color: AppColors.blackColor, width: 2),
                              ),
                              child: Image.network(
                                imageUrl!,
                                fit: BoxFit.cover,
                                width: 40,
                                height: 40,
                                // This part handles 401 or any other load failure
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    ImageAssets.defaultProfileImg,
                                    fit: BoxFit.cover,
                                    width: 40,
                                    height: 40,
                                  );
                                },
                              ),
                            ),
                          )
                        : Image.asset(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            ImageAssets.profileIcon,
                            fit: BoxFit.cover,
                            width: 25,
                            height: 25,
                          ),
                  );
              }
            }),
            SizedBox(width: screenWidht * 0.01),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {
                  switch (userData.rxRequestStatus.value) {
                    case Status.LOADING:
                      return Text(
                        "Loading...",
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: AppFonts.opensansRegular,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      );
                    case Status.ERROR:
                      return const Text("No Name");
                    case Status.COMPLETED:
                      return Text(
                        '${userData.userList.value.fullName}',
                        style: TextStyle(
                          fontFamily: AppFonts.helveticaMedium,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      );
                  }
                }),
              ],
            ),
            const Spacer(),
            Obx(
              () => Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    onPressed: () {
                      Get.toNamed(RouteName.notificationScreen);
                    },
                  ),
                  if (controller.unreadCount.value > 0)
                    Positioned(
                      right: 10,
                      top: 8,
                      child: Container(
                        height: 18,
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${controller.unreadCount.value}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 7,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.6),
          child: Container(
            color: Colors.blueGrey.shade100,
            height: 1.0,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding:
                  ResponsivePadding.symmetricPadding(context, horizontal: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),

                  // ***********************Dashboard container *******************************
                  Center(
                    child: DashboardScreen(),
                  ),

                  //*************************Performance********************** */

                  Text(
                    'Your Performance',
                    style: TextStyle(
                      fontSize: 17,
                      fontFamily: AppFonts.opensansRegular,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: 10),

                  InkWell(
                    onTap: () {
                      Get.toNamed(RouteName.streakExploreScreen);
                    },
                    child: Container(
                      width: screenWidht * 0.96,
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.grey.shade400, width: 1),
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.loginContainerColor,
                      ),
                      child: Padding(
                        padding: ResponsivePadding.symmetricPadding(context,
                            horizontal: 3),
                        child: Column(
                          children: [
                            SizedBox(height: 15),
                            Row(
                              children: [
                                Icon(
                                  PhosphorIconsFill.chartBar,
                                  color: AppColors.blackColor,
                                  size: 22,
                                ),
                                Text(
                                  'Performance',
                                  style: TextStyle(
                                      color: AppColors.blackColor,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: AppFonts.helveticaBold),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Obx(() {
                                  switch (userData.rxRequestStatus.value) {
                                    case Status.LOADING:
                                      return SizedBox(
                                        height: 10,
                                        width: 10,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1,
                                          color: AppColors.blackColor,
                                        ),
                                      );
                                    case Status.ERROR:
                                      return const Text("Null");
                                    case Status.COMPLETED:
                                      return Text(
                                        'Progress to level ${userData.userList.value.level.toString()}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontFamily: AppFonts.opensansRegular,
                                          color: AppColors.blackColor,
                                        ),
                                      );
                                  }
                                }),
                                Obx(() {
                                  switch (userData.rxRequestStatus.value) {
                                    case Status.LOADING:
                                      return const Text(
                                        "Loading...",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: AppFonts.opensansRegular,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      );
                                    case Status.ERROR:
                                      return const Text("Null");
                                    case Status.COMPLETED:
                                      return Text(
                                        '${userData.userList.value.xp.toString()}XP',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: AppFonts.helveticaMedium,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.lightBlue,
                                        ),
                                      );
                                  }
                                }),
                              ],
                            ),
                            SizedBox(height: 10),
                            Obx(() {
                              switch (userData.rxRequestStatus.value) {
                                case Status.LOADING:
                                  return GFProgressBar(
                                    lineHeight: 10,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    percentage: 0.0,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.3),
                                    progressBarColor: AppColors.greenColor,
                                  );
                                case Status.ERROR:
                                  return Text(
                                    userData.error.value.isNotEmpty
                                        ? userData.error.value.toString()
                                        : "Unknown Error",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontFamily: AppFonts.opensansRegular,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  );
                                case Status.COMPLETED:
                                  final xp = userData.userList.value.xp;
                                  final nextLevelAt =
                                      userData.userList.value.nextLevelAt;
                                  final percentage = nextLevelAt! > 0
                                      ? (xp! / nextLevelAt).clamp(0.0, 1.0)
                                      : 0.0;
                                  return GFProgressBar(
                                    lineHeight: 20,
                                    percentage: percentage,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 9),
                                    backgroundColor: Colors.grey.shade300,
                                    linearGradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6A11CB),
                                        Color(0xFF2575FC),
                                        Color(0xFF00C6FF),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                  );
                              }
                            }),
                            SizedBox(height: 10),

                            //**********************************stats row*************************** */
                            Center(
                              child: StatsRow(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Padding(
                  //   padding: ResponsivePadding.customPadding(context,
                  //       right: orientation == Orientation.portrait ? 54 : 70,
                  //       top: 2,
                  //       left: orientation == Orientation.portrait ? 4 : 3,
                  //       bottom: 1),
                  //   child: Text(
                  //     'quick_access'.tr,
                  //     style: TextStyle(
                  //       color: Theme.of(context).textTheme.bodyLarge?.color,
                  //       fontSize: 17,
                  //       fontWeight: FontWeight.bold,
                  //       fontFamily: AppFonts.opensansRegular,
                  //     ),
                  //   ),
                  // ),
                  // GridView.builder(
                  //   shrinkWrap: true,
                  //   physics: const NeverScrollableScrollPhysics(),
                  //   gridDelegate:
                  //       const SliverGridDelegateWithFixedCrossAxisCount(
                  //     crossAxisCount: 4,
                  //     childAspectRatio: 01,
                  //     crossAxisSpacing: 12,
                  //     mainAxisSpacing: 12,
                  //   ),
                  //   itemCount: items.length,
                  //   itemBuilder: (context, index) {
                  //     final item = items[index];
                  //     return GestureDetector(
                  //       onTap: () {
                  //         if (index == 0) {
                  //           Get.toNamed(RouteName.enrolledCourses);
                  //         } else if (index == 1) {
                  //           Get.toNamed(RouteName.messageScreen);
                  //         } else if (index == 2) {
                  //           Get.toNamed(RouteName.reelsScreen);
                  //         } else if (index == 3) {
                  //           Get.to(
                  //             () => FullLeaderboardScreen(
                  //               leaderboard: userLeaderboardData
                  //                   .userLeaderboard.value.leaderboard,
                  //             ),
                  //           );
                  //         }
                  //       },
                  //       child: Column(
                  //         mainAxisAlignment: MainAxisAlignment.center,
                  //         children: [
                  //           Container(
                  //             padding: const EdgeInsets.all(12),
                  //             decoration: BoxDecoration(
                  //               color:
                  //                   (item['color'] as Color).withOpacity(0.15),
                  //               borderRadius: BorderRadius.circular(16),
                  //             ),
                  //             child: Icon(
                  //               item['icon'] as IconData,
                  //               color: item['color'] as Color,
                  //               size: 24,
                  //             ),
                  //           ),
                  //           SizedBox(height: screenHeight * 0.01),
                  //           Text(
                  //             item['title'] as String,
                  //             style: TextStyle(
                  //                 fontSize: 8,
                  //                 color: Theme.of(context)
                  //                     .textTheme
                  //                     .bodyLarge
                  //                     ?.color,
                  //                 fontFamily: AppFonts.opensansRegular,
                  //                 fontWeight: FontWeight.w900),
                  //             textAlign: TextAlign.center,
                  //           ),
                  //         ],
                  //       ),
                  //     )
                  //         .animate()
                  //         .fade(
                  //             delay:
                  //                 Duration(milliseconds: 1000 + (index * 150)))
                  //         .scale(
                  //             alignment: Alignment.center,
                  //             begin: const Offset(0.0, 0.0),
                  //             end: const Offset(1.0, 1.0),
                  //             curve: Curves.elasticOut,
                  //             duration: const Duration(milliseconds: 800));
                  //   },
                  // ),
                  SizedBox(height: 10),
                  Padding(
                    padding: ResponsivePadding.customPadding(
                      context,
                      right: orientation == Orientation.portrait ? 2 : 4,
                      left: orientation == Orientation.portrait ? 2 : 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'top_learners'.tr,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            fontFamily: AppFonts.opensansRegular,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Get.to(() => FullLeaderboardScreen(
                                  leaderboard: userLeaderboardData
                                      .userLeaderboard.value.leaderboard,
                                ));
                          },
                          child: Text(
                            'view_rank'.tr,
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                              fontWeight: FontWeight.bold,
                              fontFamily: AppFonts.opensansRegular,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),

// *******************************************Top Learner widget**********************************//
                  TopLearnerWidget(),
//************************follow suggestion user*************************************************//

                  // Row(
                  //   children: [
                  //     Image.asset(
                  //       ImageAssets.telescope,
                  //       height: 25,
                  //       color: Theme.of(context).textTheme.bodyLarge?.color,
                  //     ),
                  //     SizedBox(width: 10),
                  //     Text(
                  //       'Explore',
                  //       style: TextStyle(
                  //         fontSize: 18,
                  //         fontWeight: FontWeight.bold,
                  //         fontFamily: AppFonts.helveticaBold,
                  //         color: Theme.of(context).textTheme.bodyLarge?.color,
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  // SizedBox(
                  //   height: 300,
                  //   child: FollowListScreen(),
                  // ),
                  SizedBox(height: 20),

                  Row(
                    children: [
                      Image.asset(
                        ImageAssets.openbook,
                        height: 25,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Courses',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppFonts.helveticaBold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 20),
//*****************************************Continue course widget**************************/

                  FeaturedCourseWidget(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
