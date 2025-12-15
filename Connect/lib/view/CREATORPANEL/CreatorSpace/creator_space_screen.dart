import 'dart:developer';
import 'dart:io';

import 'package:connectapp/data/response/status.dart';
import 'package:connectapp/res/api_urls/api_urls.dart';
import 'package:connectapp/res/assets/image_assets.dart';
import 'package:connectapp/res/component/round_button.dart';
import 'package:connectapp/res/fonts/app_fonts.dart';
import 'package:connectapp/view_models/controller/allspaces/get_all_spaces_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../res/color/app_colors.dart';
import '../../../res/routes/routes_name.dart';
import '../../../utils/utils.dart';
import '../../../view_models/controller/allspaces/enroll_in_space_controller.dart';

class CreatorSpaceScreen extends StatefulWidget {
  const CreatorSpaceScreen({super.key});

  @override
  State<CreatorSpaceScreen> createState() => _CreatorSpaceScreenState();
}

class _CreatorSpaceScreenState extends State<CreatorSpaceScreen> {
  String selectedTab = "Live Now";

  @override
  Widget build(BuildContext context) {
    Get.put(AllSpacesController());
    Get.put(EnrollSpaceController());
    double screenWidth = MediaQuery.of(context).size.width;
    // double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          selectedTab,
          style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontFamily: AppFonts.opensansRegular),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _tabItem("Live Now", selectedTab == "Live Now"),
                SizedBox(width: screenWidth * 0.05),
                _tabItem("Upcoming", selectedTab == "Upcoming"),
                SizedBox(width: screenWidth * 0.05),
                _tabItem("Recorded", selectedTab == "Recorded"),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: _getTabContent(),
        ),
      ),
    );
  }

  Widget _tabItem(String label, bool isSelected, {int badgeCount = 0}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = label;
        });
      },
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              // color: isSelected ? AppColors.textfieldColor : Colors.transparent,
              gradient: isSelected
                  ? AppColors.primaryGradient
                  : AppColors.exploreGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.whiteColor : AppColors.blackColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.purple,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _getTabContent() {
    final spacesController = Get.find<AllSpacesController>();
    String statusFilter;
    switch (selectedTab) {
      case "Live Now":
        statusFilter = "live";
        break;
      case "Recorded":
        statusFilter = "recorded";
        break;
      case "Upcoming":
      default:
        statusFilter = "scheduled";
        break;
    }

    return Obx(() {
      if (spacesController.rxRequestStatus.value == Status.LOADING) {
        return const Center(child: CircularProgressIndicator());
      } else if (spacesController.rxRequestStatus.value == Status.ERROR) {
        return Center(
          child: Text(
            spacesController.error.value,
            style: const TextStyle(
                fontSize: 18,
                color: Colors.black,
                fontFamily: AppFonts.opensansRegular),
          ),
        );
      }

      final filteredSpaces = spacesController.spaces
          .where((space) =>
              space.status?.toLowerCase() == statusFilter.toLowerCase())
          .toList();

      if (filteredSpaces.isEmpty) {
        return Center(
          child: Text(
            "No $selectedTab spaces available",
            style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontFamily: AppFonts.opensansRegular),
          ),
        );
      }

      return ListView.builder(
        itemCount: filteredSpaces.length,
        itemBuilder: (context, index) {
          return _buildSessionCard(filteredSpaces[index]);
        },
      );
    });
  }

  Widget _buildSessionCard(space) {
    final enrollController = Get.find<EnrollSpaceController>();
    String formattedStartTime = "N/A";
    if (space.startTime != null) {
      final utcDate = DateTime.parse(space.startTime!).toUtc();
      final istDate = utcDate.add(const Duration(hours: 5, minutes: 30));
      formattedStartTime = DateFormat('MMM d, yyyy h:mm a').format(istDate);
    }

    final tags = space.tags ?? [];
    final displayedTags = tags.take(3).toList();
    final remainingTagsCount = tags.length > 3 ? tags.length - 3 : 0;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppColors.primaryGradient),
      child: Card(
        color: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Image.asset(
                      ImageAssets.profileIcon,
                      height: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    space.creator?.fullName ?? "Host",
                    style: const TextStyle(
                        color: AppColors.whiteColor,
                        fontFamily: AppFonts.opensansRegular),
                  ),
                  Spacer(),
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 16,
                        color: AppColors.whiteColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${space.totalJoined ?? 0} joined",
                        style: const TextStyle(
                            color: AppColors.whiteColor,
                            fontFamily: AppFonts.opensansRegular),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                space.title ?? "Untitled Space",
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.whiteColor,
                    fontFamily: AppFonts.opensansRegular),
              ),
              const SizedBox(height: 4),
              Text(
                space.description ?? "No description available",
                style: TextStyle(
                    color: Colors.grey[600],
                    fontFamily: AppFonts.opensansRegular),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  ...displayedTags.map((tag) => _Tag(tag)),
                  if (remainingTagsCount > 0) _Tag("+$remainingTagsCount more"),
                ],
              ),
              const Divider(height: 30),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.whiteColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formattedStartTime,
                    style: const TextStyle(
                        color: AppColors.whiteColor,
                        fontFamily: AppFonts.opensansRegular),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Obx(() {
                      final buttonText = enrollController.getButtonText(
                          space.sId ?? "", space.status ?? "");

                      final isLoading =
                          enrollController.rxRequestStatus[space.sId] ==
                              Status.LOADING;

                      return ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : buttonText == "Enroll"
                                ? () => enrollController
                                    .enrollInSpace(space.sId ?? "")
                                : buttonText == "Join Now"
                                    ? () {
                                        final spaceId = space.sId;

                                        if (spaceId == null ||
                                            spaceId.isEmpty) {
                                          Get.snackbar(
                                              "Error", "Space ID is missing.");
                                          return;
                                        }
                                        log("Navigating to JoinMeetingScreen with spaceId: $spaceId");
                                        Get.toNamed(
                                          RouteName.joinMeeting,
                                          arguments: {'spaceId': spaceId},
                                        );
                                      }
                                    : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonColor,
                          foregroundColor: AppColors.whiteColor,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.whiteColor,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(buttonText),
                      );
                    }),
                  ),
                  const SizedBox(width: 16),
                  RoundButton(
                      height: 40,
                      buttonColor: AppColors.buttonColor,
                      title: 'Share Space',
                      onPress: () async {
  debugPrint('Share button tapped for space: ${space.title}');

  try {
    final shareUrl = "${ApiUrls.baseUrl}/others?spaceId=${space.sId}";

    // 📝 Build formatted share text
    String shareText = '''
🏠 ${space.title ?? 'Untitled Space'}

📝 ${space.description ?? 'No description available.'}

🔗 View it here:
$shareUrl
''';

    // 🟦 Show temporary snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Preparing to share...'),
          ],
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.blue,
      ),
    );

    // 📷 Download thumbnail (if available)
    File? imageFile;
    if (space.thumbnail?.isNotEmpty == true) {
      try {
        final response = await http.get(Uri.parse(space.thumbnail!));
        if (response.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          final filePath = '${tempDir.path}/space_thumbnail.jpg';
          imageFile = File(filePath);
          await imageFile.writeAsBytes(response.bodyBytes);
        } else {
          debugPrint('Thumbnail download failed: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Error downloading thumbnail: $e');
      }
    }

    debugPrint('Opening share dialog...');

    // 📤 Share with or without image
    if (imageFile != null && imageFile.existsSync()) {
      await Share.shareXFiles(
        [XFile(imageFile.path)],
        text: shareText,
        subject: 'Check out this Space!',
      );
    } else {
      await Share.share(
        shareText,
        subject: 'Check out this Space!',
      );
    }
  } catch (e) {
    debugPrint('Error sharing space: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to share Space'),
        backgroundColor: Colors.red,
      ),
    );
  }
})
                      ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.grey.shade200,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
