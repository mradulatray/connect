import 'package:connectapp/res/assets/image_assets.dart';
import 'package:connectapp/res/color/app_colors.dart';
import 'package:connectapp/res/custom_widgets/responsive_padding.dart';
import 'package:connectapp/res/fonts/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../models/EnrolledCourses/enrolled_courses_model.dart';
import '../../view_models/controller/coursevideo/course_video_controller.dart';
import 'dart:developer' as developer;

String stripHtmlTags(String html) {
  if (html.isEmpty) return '';
  return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
}

class CourseVideoScreen extends StatelessWidget {
  const CourseVideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CourseVideoController controller = Get.put(CourseVideoController());
    // final Course course = Get.arguments as course;
    final EnrolledCourses course = Get.arguments as EnrolledCourses;
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Obx(() => Column(
                        children: [
                          Stack(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: MediaQuery.of(context).orientation ==
                                        Orientation.portrait
                                    ? screenHeight * 0.35
                                    : screenHeight * 0.95,
                                child: controller.isVideoInitialized.value &&
                                        controller
                                                .videoPlayerController.value !=
                                            null
                                    ? AspectRatio(
                                        aspectRatio: controller
                                            .videoPlayerController
                                            .value!
                                            .value
                                            .aspectRatio,
                                        child: GestureDetector(
                                          onTap: controller.togglePlayPause,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              VideoPlayer(controller
                                                  .videoPlayerController
                                                  .value!),

                                              /// Play/Pause Button (only when controls are visible)
                                              if (controller.showControls.value)
                                                IconButton(
                                                  icon: Icon(
                                                    controller
                                                            .videoPlayerController
                                                            .value!
                                                            .value
                                                            .isPlaying
                                                        ? Icons.pause
                                                        : Icons.play_arrow,
                                                    color: Colors.white,
                                                    size: 50,
                                                  ),
                                                  onPressed: controller
                                                      .togglePlayPause,
                                                ),

                                              /// Bottom Controls: Progress bar & Time (only when controls are visible)
                                              if (controller.showControls.value)
                                                Positioned(
                                                  bottom: 0,
                                                  left: 8,
                                                  right: 8,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .stretch,
                                                    children: [
                                                      ValueListenableBuilder<
                                                          VideoPlayerValue>(
                                                        valueListenable: controller
                                                            .videoPlayerController
                                                            .value!,
                                                        builder: (context,
                                                            value, child) {
                                                          return Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Text(
                                                                controller
                                                                    .formatDuration(
                                                                        value
                                                                            .position),
                                                                style:
                                                                    const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                              Text(
                                                                controller
                                                                    .formatDuration(
                                                                        value
                                                                            .duration),
                                                                style:
                                                                    const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      ),
                                                      VideoProgressIndicator(
                                                        controller
                                                            .videoPlayerController
                                                            .value!,
                                                        allowScrubbing: true,
                                                        colors:
                                                            const VideoProgressColors(
                                                          playedColor:
                                                              Colors.red,
                                                          bufferedColor:
                                                              AppColors
                                                                  .whiteColor,
                                                          backgroundColor:
                                                              AppColors
                                                                  .greyColor,
                                                        ),
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 4),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                              /// Orientation Button (only when controls are visible)
                                              if (controller.showControls.value)
                                                Positioned(
                                                  top: 0,
                                                  right: 0,
                                                  child: SafeArea(
                                                    child: IconButton(
                                                      icon: const Icon(
                                                        Icons.screen_rotation,
                                                        color: Colors.white,
                                                        size: 30,
                                                      ),
                                                      onPressed: controller
                                                          .toggleOrientation,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : Image.network(
                                        course.thumbnail ?? "",
                                        width: double.infinity,
                                        height: MediaQuery.of(context)
                                                    .orientation ==
                                                Orientation.portrait
                                            ? screenHeight * 0.35
                                            : screenHeight * 0.7,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Image.asset(
                                          ImageAssets.pythonIcon,
                                          width: double.infinity,
                                          height: MediaQuery.of(context)
                                                      .orientation ==
                                                  Orientation.portrait
                                              ? screenHeight * 0.35
                                              : screenHeight * 0.7,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                              ),
                            ],
                          ),

                          // Course Title
                          Padding(
                            padding: ResponsivePadding.symmetricPadding(context,
                                horizontal: 2),
                            child: Text(
                              course.title ?? 'No Title',
                              style: TextStyle(
                                fontSize: 17,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                                fontWeight: FontWeight.bold,
                                fontFamily: AppFonts.opensansRegular,
                              ),
                              maxLines: 6,
                            ),
                          ),

                          // Course Info
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Created by ${course.creator!.name}',
                                  style: TextStyle(
                                    fontFamily: AppFonts.opensansRegular,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        color: Colors.amber, size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      course.ratings!.avgRating!
                                          .toStringAsFixed(1),
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${course.sections!.fold(0, (sum, section) => sum + section.lessons!.length)} Lessons',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      )),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    GetBuilder<CourseVideoController>(
                      builder: (controller) => TabBar(
                        labelStyle: TextStyle(
                            fontFamily: AppFonts.opensansRegular,
                            color:
                                Theme.of(context).textTheme.bodyLarge?.color),
                        controller: controller.tabController,
                        isScrollable: false,
                        labelColor:
                            Theme.of(context).textTheme.bodyLarge?.color,
                        unselectedLabelColor: AppColors.textColor,
                        indicatorColor: Colors.blueAccent,
                        labelPadding: ResponsivePadding.symmetricPadding(
                            context,
                            horizontal: 6),
                        tabs: [
                          Tab(
                            text:
                                'Playlist ${course.sections!.fold(0, (sum, section) => sum + section.lessons!.length)}',
                          ),
                          Tab(
                            text: 'Description',
                          ),
                          const Tab(text: 'Review'),
                        ],
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: GetBuilder<CourseVideoController>(
              builder: (controller) => TabBarView(
                controller: controller.tabController,
                children: [
                  // Playlist Tab
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ...course.sections!.asMap().entries.expand((entry) {
                        final sectionIndex = entry.key;
                        final section = entry.value;
                        return [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              section.title ?? 'No title',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: AppFonts.opensansRegular,
                              ),
                            ),
                          ),
                          ...section.lessons!
                              .asMap()
                              .entries
                              .map((lessonEntry) {
                            final lessonIndex = lessonEntry.key;
                            final lesson = lessonEntry.value;
                            final globalIndex =
                                course.sections!.sublist(0, sectionIndex).fold(
                                          0,
                                          (sum, s) => sum + s.lessons!.length,
                                        ) +
                                    lessonIndex;
                            final isCompleted = controller.courseProgress.value
                                    ?.progress?.completedLessons
                                    ?.any((cl) =>
                                        cl.lessonId == lesson.id &&
                                        cl.isCompleted == true) ??
                                controller.allLessons[globalIndex].isCompleted;
                            developer.log(
                              'Lesson: ${lesson.title}, id: ${lesson.id}, isCompleted: $isCompleted, progressLessons: ${controller.courseProgress.value?.progress?.completedLessons?.map((cl) => "${cl.lessonId}:${cl.isCompleted}").toList() ?? []}',
                              name: 'CourseVideoScreen',
                            );
                            return playlistItem(
                              lesson,
                              isCompleted!,
                              () => controller.playLesson(lesson, globalIndex),
                              controller.isCourseSubmitted.value || isCompleted
                                  ? null
                                  : (lesson.contentType == 'video'
                                      ? () => controller.submitLesson(lesson)
                                      : () => controller.playLesson(
                                            lesson,
                                            globalIndex,
                                          )),
                            );
                          }),
                        ];
                      }).toList(),
                      const SizedBox(height: 20),
                    ],
                  ),

                  // Description Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.description ?? 'No Description',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // Review Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How was your experience with ${course.title}?',
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                              fontSize: 18,
                              fontFamily: AppFonts.opensansRegular),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Obx(() => Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                5,
                                (index) => IconButton(
                                  icon: Icon(
                                    index < controller.selectedRating.value
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: screenWidth * 0.08,
                                  ),
                                  onPressed: () =>
                                      controller.updateRating(index + 1),
                                ),
                              ),
                            )),
                        const SizedBox(height: 20),
                        Text(
                          'Write Your Review',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: 16,
                            fontFamily: AppFonts.opensansRegular,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.greyColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            maxLines: 4,
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                              fontFamily: AppFonts.opensansRegular,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Write review here...',
                              hintStyle: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                  fontFamily: AppFonts.opensansRegular),
                              border: InputBorder.none,
                            ),
                            onChanged: controller.updateReviewText,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Obx(() => Center(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurpleAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 50),
                                ),
                                onPressed: controller.isSubmittingReview.value
                                    ? null
                                    : () => controller
                                        .submitReview(course.id.toString()),
                                child: controller.isSubmittingReview.value
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Submit'),
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget playlistItem(
      lesson, bool isCompleted, VoidCallback onTap, VoidCallback? onAction) {
    IconData icon;
    switch (lesson.contentType) {
      case 'video':
        icon = Icons.play_circle_outline;
        break;
      case 'quiz':
        icon = Icons.quiz_outlined;
        break;
      case 'text':
        icon = Icons.article_outlined;
        break;
      default:
        icon = Icons.play_circle_outline;
    }

    return ListTile(
      leading: Icon(
        icon,
        color: Get.theme.textTheme.bodyLarge?.color,
      ),
      title: Text(
        lesson.title ?? 'No Title Available',
        style: TextStyle(
          color: Get.theme.textTheme.bodyLarge?.color,
        ),
      ),
      subtitle: Text(
        stripHtmlTags(lesson.textContent ?? 'No description available'),
        style: TextStyle(
          color: Get.theme.textTheme.bodyLarge?.color,
          fontSize: 12,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isCompleted
          ? const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 36,
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(80, 36),
              ),
              onPressed: onAction,
              child: Text(
                lesson.contentType == 'video' ? 'Submit' : 'Open',
                style: const TextStyle(
                  fontFamily: AppFonts.opensansRegular,
                  fontSize: 12,
                ),
              ),
            ),
      onTap: onTap,
    );
  }

  Widget feedbackCard(BuildContext context, double screenWidth) {
    return SizedBox(
      width: (screenWidth - 44) / 2,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.textfieldColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              'John Smith',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                fontFamily: AppFonts.opensansRegular,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'This course covers the essentials of modern web design, blending visual aesthetics',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                fontFamily: AppFonts.opensansRegular,
                fontSize: 12,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => 48.0;

  @override
  double get maxExtent => 48.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return true;
  }
}
