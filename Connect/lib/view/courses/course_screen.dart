import 'dart:developer';
import 'dart:io';
import 'package:connectapp/res/api_urls/api_urls.dart';
import 'package:connectapp/res/color/app_colors.dart';
import 'package:connectapp/res/custom_widgets/custome_appbar.dart';
import 'package:connectapp/res/custom_widgets/responsive_padding.dart';
import 'package:connectapp/res/fonts/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../data/response/status.dart';
import '../../models/Courses/all_courses_model.dart';
import 'package:share_plus/share_plus.dart';
import '../../res/assets/image_assets.dart';
import '../../view_models/controller/allcourses/all_course_controller.dart';
import '../../view_models/controller/enrollincourse/enroll_in_course_controller.dart';

class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  String selectedFilter = "All Courses";
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final AllCoursesController controller = Get.put(AllCoursesController());
    // Initialize CourseEnrollmentController
    Get.put(CourseEnrollmentController());
    return Scaffold(
      appBar: CustomAppBar(
        automaticallyImplyLeading: true,
        title: 'courses'.tr,
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: ResponsivePadding.symmetricPadding(context, horizontal: 2),
          child: Column(
            children: [
              // Search box
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search courses, instructors, or topics...',
                    hintStyle: const TextStyle(
                      color: Colors.white54,
                      fontFamily: AppFonts.opensansRegular,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent, // Keep it transparent!
                    contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.trim().toLowerCase();
                    });
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Dynamic courses list
              Expanded(
                child: Obx(() {
                  switch (controller.rxRequestStatus.value) {
                    case Status.LOADING:
                      return const Center(child: CircularProgressIndicator());
                    case Status.ERROR:
                      return Center(
                        child: Text(
                          controller.error.value.isNotEmpty
                              ? controller.error.value
                              : 'Error loading courses',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    case Status.COMPLETED:
                      List<Course> filteredCourses = controller.courses;

                      if (selectedFilter != "All Courses") {
                        filteredCourses = filteredCourses.where((course) {
                          return course.tags
                              .map((e) => e.toLowerCase())
                              .contains(selectedFilter.toLowerCase());
                        }).toList();
                      }

                      if (searchQuery.isNotEmpty) {
                        filteredCourses = filteredCourses.where((course) {
                          final title = course.title.toLowerCase();
                          final instructor =
                              course.createdBy.fullName.toLowerCase();
                          final tags =
                              course.tags.map((e) => e.toLowerCase()).join(" ");
                          final description = course.description.toLowerCase();

                          final combined =
                              "$title $instructor $tags $description";

                          return combined.contains(searchQuery);
                        }).toList();
                      }

                      if (filteredCourses.isEmpty) {
                        return Center(
                          child: Text(
                            "No courses available.",
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: AppFonts.opensansRegular,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredCourses.length,
                        itemBuilder: (context, index) {
                          final course = filteredCourses[index];
                          return CourseCard(course: course);
                        },
                      );
                  }
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  final Course course;
  const CourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    // double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    final enrollmentController = Get.find<CourseEnrollmentController>();
    final totalLessons = course.sections.fold<int>(
      0,
      (sum, section) => sum + section.lessons.length,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color.fromARGB(179, 252, 216, 14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: ClipOval(
              child: course.thumbnail.isNotEmpty
                  ? Image.network(
                      course.thumbnail,
                      width: 55,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          ImageAssets.profilePic,
                          width: 55,
                          height: 90,
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Image.asset(
                      ImageAssets.profileIcon,
                      width: 55,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
            ),
            title: Text(
              course.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: AppFonts.opensansRegular,
              ),
            ),
            subtitle: Text(
              "Created By: ${course.createdBy.fullName}",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontFamily: AppFonts.opensansRegular,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            course.description,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontFamily: AppFonts.opensansRegular,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          if (course.tags.isNotEmpty)
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: course.tags
                  .map(
                    (tag) => Chip(
                      label: Text(
                        tag,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize:
                              12, // reduce font size to reduce overall chip size
                          fontFamily: AppFonts.opensansRegular,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                "${course.sections.length} sections • $totalLessons lessons",
                style: const TextStyle(
                  color: Colors.white54,
                  fontFamily: AppFonts.opensansRegular,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  SizedBox(width: screenWidth * 0.01),
                  Text(
                    course.averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: AppFonts.opensansRegular,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Obx(
                () => ElevatedButton(
                  onPressed:
                      enrollmentController.loadingStatus[course.id] == true
                          ? null
                          : () {
                              log('Enroll button tapped for course: ${course.id}',
                                  name: 'CourseCard');
                              enrollmentController.enrollCourse(course);
                            },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: enrollmentController.loadingStatus[course.id] == true
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          enrollmentController.isUserEnrolled(course.id)
                              ? "Already Enrolled"
                              : "Enroll for ${course.coins ?? 0} Coins",
                          style: TextStyle(
                              fontFamily: AppFonts.opensansRegular,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () async {
  debugPrint('Share button tapped for course: ${course.id}');

  try {
    final shareUrl = "${ApiUrls.deepBaseUrl}/course-details/${course.id}";

    String shareText = '''
🎓 ${course.title}

📝 ${course.description}

🔗 View it here:
$shareUrl
''';

    // Show "Preparing to share" snackbar
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

    File? imageFile;
    if (course.thumbnail.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(course.thumbnail));
        if (response.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          final filePath = '${tempDir.path}/course_thumbnail.jpg';
          imageFile = File(filePath);
          await imageFile.writeAsBytes(response.bodyBytes);
        }
      } catch (e) {
        debugPrint('Error downloading thumbnail: $e');
      }
    }

    debugPrint('Opening share dialog...');

    if (imageFile != null && imageFile.existsSync()) {
      await Share.shareXFiles(
        [XFile(imageFile.path)],
        text: shareText,
        subject: 'Check out this Course!',
      );
    } else {
      await Share.share(
        shareText,
        subject: 'Check out this Course!',
      );
    }
  } catch (e) {
    debugPrint('Error sharing course: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to share course'),
        backgroundColor: Colors.red,
      ),
    );
  }
},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  "Share",
                  style: TextStyle(fontFamily: AppFonts.opensansRegular),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
