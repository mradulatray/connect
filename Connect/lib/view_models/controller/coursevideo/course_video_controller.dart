import 'dart:async';
import 'package:connectapp/models/EnrolledCourses/enrolled_courses_model.dart';
import 'package:connectapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../models/CourseProgress/course_progress_model.dart';

import '../../../res/api_urls/api_urls.dart';
import '../../../res/routes/routes_name.dart';
import '../profile/user_profile_controller.dart';
import '../userPreferences/user_preferences_screen.dart';

class CourseVideoController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final userData = Get.find<UserProfileController>();
  // final Course course = Get.arguments as Course;
  final EnrolledCourses course = Get.arguments as EnrolledCourses;
  late TabController tabController;
  final Rx<VideoPlayerController?> videoPlayerController =
      Rx<VideoPlayerController?>(null);
  final RxBool isVideoInitialized = false.obs;
  final Rx<Lesson?> currentLesson = Rx<Lesson?>(null);
  final RxInt currentLessonIndex = (-1).obs;
  final RxList<Lesson> allLessons = <Lesson>[].obs;
  final RxBool isLandscape = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isCourseSubmitted = false.obs;
  final _prefs = UserPreferencesViewmodel();
  static const String baseUrl = ApiUrls.baseUrl;

  final Rx<CourseProgressModel?> courseProgress =
      Rx<CourseProgressModel?>(null);
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt selectedRating = 0.obs;
  final RxString reviewText = ''.obs;
  final RxBool isSubmittingReview = false.obs;
  final showControls = true.obs;
  Timer? _hideControlsTimer;

  static const String courseSubmissionPath =
      '/connect/v1/api/user/course/complete-course';

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
    fetchCourseProgress(course.id);
    initializeLessons();
    checkCourseSubmissionStatus();
    initializeVideoPlayer();
  }

  void updateRating(int rating) {
    selectedRating.value = rating;
  }

  void updateReviewText(String text) {
    reviewText.value = text;
  }

  Future<void> submitReview(String courseId) async {
    if (selectedRating.value == 0) {
      Utils.snackBar(
        'Please select a rating',
        'Info',
      );
      return;
    }
    if (reviewText.value.trim().isEmpty) {
      Utils.snackBar(
        'Please enter a review',
        'Info',
      );
      return;
    }

    try {
      isSubmittingReview.value = true;
      final user = await _prefs.getUser();
      if (user == null || user.token.isEmpty) {
        Utils.snackBar(
            'Authentication Error', 'Please log in to submit a review');
        Get.offNamed(RouteName.loginScreen);
        return;
      }

      final url = '$baseUrl/connect/v1/api/user/add-course-review/$courseId';
      // developer.log('Submitting review, url: $url',
      //     name: 'CourseVideoController');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
        body: jsonEncode({
          'rating': selectedRating.value,
          'review': reviewText.value,
        }),
      );

      // developer.log('Review Submission Status: ${response.statusCode}',
      //     name: 'CourseVideoController');
      // developer.log('Review Submission Body: ${response.body}',
      //     name: 'CourseVideoController');

      if (response.statusCode == 200 || response.statusCode == 201) {
        Utils.snackBar(
          'Review submitted successfully',
          'Success',
        );
        selectedRating.value = 0;
        reviewText.value = '';
      } else if (response.statusCode == 401) {
        Utils.snackBar('Session Expired', 'Please log in again');
        await _prefs.removeUser();
        Get.offNamed(RouteName.loginScreen);
      } else {
        final errorMessage =
            jsonDecode(response.body)['message'] ?? 'Failed to submit review';
        Utils.snackBar(errorMessage, 'Error');
      }
    } catch (e) {
      // developer.log('Review Submission Error: $e',
      //     name: 'CourseVideoController');
      String errorMessage = e.toString();
      if (errorMessage.contains('SocketException')) {
        errorMessage = 'No internet connection. Please check your network.';
      } else if (errorMessage.contains('TimeoutException')) {
        errorMessage = 'Request timed out. Please try again later.';
      }
      Utils.snackBar(
        errorMessage,
        'Info',
      );
    } finally {
      isSubmittingReview.value = false;
    }
  }

  void initializeLessons() {
    allLessons.assignAll(
      course.sections
              ?.expand((section) => section.lessons ?? <Lesson>[])
              .toList() ??
          [],
    );

    if (allLessons.isEmpty) {
      Get.snackbar(
        'Info',
        'No lessons available for this course.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
      return;
    }

    for (int i = 0; i < allLessons.length; i++) {
      if (allLessons[i].contentType == 'video' &&
          allLessons[i].videoUrl != null) {
        currentLesson.value = allLessons[i];
        currentLessonIndex.value = i;
        break;
      }
    }
  }

  Future<void> checkCourseSubmissionStatus() async {
    try {
      final user = await _prefs.getUser();
      if (user == null || user.token.isEmpty) {
        return;
      }
      final response = await http.get(
        Uri.parse('$baseUrl/connect/v1/api/user/profile'),
        headers: {
          'Authorization': 'Bearer ${user.token}',
        },
      );
      if (response.statusCode == 200) {
        final profile = jsonDecode(response.body);
        final completedCourses = profile['completedCourses'];
        if (completedCourses is List) {
          isCourseSubmitted.value = completedCourses.contains(course.id);
        } else {
          isCourseSubmitted.value =
              courseProgress.value?.progress?.isCompleted ?? false;
        }
      }
    } catch (e) {
      // developer.log('Error checking submission status: $e',
      //     name: 'CourseVideoController');
    }
  }

  void initializeVideoPlayer() {
    if (currentLesson.value != null && currentLesson.value!.videoUrl != null) {
      videoPlayerController.value =
          VideoPlayerController.network(currentLesson.value!.videoUrl!)
            ..initialize().then((_) {
              isVideoInitialized.value = true;
            }).catchError((error) {
              isVideoInitialized.value = false;
            });
    }
  }

  void playNextVideo() {
    for (int i = currentLessonIndex.value + 1; i < allLessons.length; i++) {
      if (allLessons[i].contentType == 'video' &&
          allLessons[i].videoUrl != null) {
        currentLesson.value = allLessons[i];
        currentLessonIndex.value = i;
        isVideoInitialized.value = false;
        videoPlayerController.value?.dispose();
        videoPlayerController.value =
            VideoPlayerController.network(currentLesson.value!.videoUrl!)
              ..initialize().then((_) {
                isVideoInitialized.value = true;
                videoPlayerController.value!.play();
              }).catchError((error) {
                isVideoInitialized.value = false;
              });
        return;
      }
    }
    videoPlayerController.value?.pause();
  }

  Future<void> markLessonCompleted({Map<String, String>? answers}) async {
    if (isCourseSubmitted.value) {
      Get.snackbar(
        'Info',
        'Course already submitted.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
      return;
    }

    try {
      final user = await _prefs.getUser();
      if (user == null || user.token.isEmpty) {
        throw Exception('No authentication token found');
      }
      if (currentLesson.value?.id == null) {
        throw Exception('No lesson selected');
      }

      // developer.log(
      //     'Marking lesson as completed, lessonId: ${currentLesson.value!.id}, contentType: ${currentLesson.value!.contentType}, answers: $answers',
      //     name: 'CourseVideoController');

      final response = await http.post(
        Uri.parse(
            '$baseUrl/connect/v1/api/user/course/${course.id}/mark-lesson-completed/${currentLesson.value!.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
        body: jsonEncode({'userAnswer': answers}),
      );

      // developer.log('Mark Lesson Response Status: ${response.statusCode}',
      //     name: 'CourseVideoController');
      // developer.log('Mark Lesson Response Body: ${response.body}',
      //     name: 'CourseVideoController');

      if (response.statusCode == 200) {
        allLessons.value = allLessons.map((lesson) {
          if (lesson.id == currentLesson.value?.id) {
            // developer.log('Updating lesson ${lesson.id} to isCompleted: true',
            //     name: 'CourseVideoController');
            return Lesson(
              id: lesson.id,
              title: lesson.title,
              contentType: lesson.contentType,
              videoUrl: lesson.videoUrl,
              textContent: lesson.textContent,
              quiz: lesson.quiz,
              isCompleted: true,
            );
          }
          return lesson;
        }).toList();
        update();
        await Future.delayed(const Duration(milliseconds: 500));
        await fetchCourseProgress(course.id);

        Get.snackbar(
          'Success',
          'Lesson completed successfully!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        throw Exception('Failed to mark lesson as completed: ${response.body}');
      }
    } catch (err) {
      // developer.log('Mark Lesson Error: $err',
      //     stackTrace: stackTrace, name: 'CourseVideoController');
      Get.snackbar(
        'Error',
        err.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> submitCourse() async {
    if (isCourseSubmitted.value) {
      Get.snackbar(
        'Info',
        'Course already submitted.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
      return;
    }

    if (!allLessons.every((lesson) => lesson.isCompleted!)) {
      Get.snackbar(
        'Error',
        'Please complete all lessons before submitting the course.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;
      final user = await _prefs.getUser();
      if (user == null || user.token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final url = '$baseUrl$courseSubmissionPath/${course.id}';
      // developer.log(
      //     'Submitting course, url: $url, courseId: ${course.id}, token: ${user.token.substring(0, 10)}...',
      //     name: 'CourseVideoController');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
        body: jsonEncode({}),
      );

      // developer.log('Submit Course Response Status: ${response.statusCode}',
      //     name: 'CourseVideoController');
      // developer.log('Submit Course Response Body: ${response.body}',
      //     name: 'CourseVideoController');

      if (response.statusCode == 200) {
        isCourseSubmitted.value = true;
        await userData.userList();
        await fetchCourseProgress(course.id);
        Get.dialog(
          AlertDialog(
            title: const Text('Course Completed!'),
            content: Text('You have completed ${course.title}.'),
            actions: [
              TextButton(
                onPressed: () => Get.offNamed(RouteName.homeScreen),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else if (response.statusCode == 401) {
        Get.snackbar(
          'Session Expired',
          'Your session has expired. Please log in again.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        await _prefs.removeUser();
        Get.offNamed(RouteName.loginScreen);
      } else {
        String errorMessage = 'Failed to submit course.';
        try {
          final errorBody = jsonDecode(response.body);
          errorMessage = errorBody['message'] ?? errorMessage;
        } catch (e) {
          // developer.log('Failed to parse error response: $e',
          //     name: 'CourseVideoController');
          errorMessage = 'Unexpected server response: ${response.body}';
        }
        Get.snackbar(
          'Error',
          errorMessage,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (err) {
      // developer.log('Submit Course Error: $err',
      //     stackTrace: stackTrace, name: 'CourseVideoController');
      String errorMessage = err.toString();
      if (errorMessage.contains('SocketException')) {
        errorMessage = 'No internet connection. Please check your network.';
      } else if (errorMessage.contains('TimeoutException')) {
        errorMessage = 'Request timed out. Please try again later.';
      } else if (errorMessage.contains('FormatException')) {
        errorMessage = 'Unexpected server response. Please contact support.';
      }
      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void playLesson(Lesson lesson, int index) async {
    currentLesson.value = lesson;
    currentLessonIndex.value = index;
    // developer.log(
    //     'Playing lesson: ${lesson.title}, type: ${lesson.contentType}, id: ${lesson.id}',
    //     name: 'CourseVideoController');
    if (lesson.contentType == 'video' && lesson.videoUrl != null) {
      isVideoInitialized.value = false;
      videoPlayerController.value?.dispose();
      videoPlayerController.value =
          VideoPlayerController.network(lesson.videoUrl!)
            ..initialize().then((_) {
              isVideoInitialized.value = true;
              if (lesson.isCompleted!) {
                videoPlayerController.value!.play();
              }
            }).catchError((error) {
              isVideoInitialized.value = false;
            });
    } else if (lesson.contentType == 'quiz') {
      Get.toNamed(RouteName.quizScreen, arguments: lesson)?.then((result) {
        // developer.log('QuizScreen returned result: $result',
        //     name: 'CourseVideoController');
        if (result != null && result is Map<String, dynamic>) {
          final total = result['total'] as int?;
          final answers = result['answers'] as Map<String, String>?;
          if (total != null && answers != null && answers.isNotEmpty) {
            // developer.log(
            //     'Calling markLessonCompleted for quiz lesson ${lesson.id} with answers: $answers',
            //     name: 'CourseVideoController');
            markLessonCompleted(answers: answers);
          } else {
            // developer.log('Invalid quiz result: total=$total, answers=$answers',
            //     name: 'CourseVideoController');
            Get.snackbar(
              'Error',
              'Failed to process quiz submission. Please try again.',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        }
      });
    } else if (lesson.contentType == 'text') {
      Get.toNamed(RouteName.contentLession, arguments: lesson)?.then((result) {
        // developer.log('ContentLessonScreen returned result: $result',
        //     name: 'CourseVideoController');
        if (result == true) {
          markLessonCompleted();
        }
      });
    }
    update();
  }

  void submitLesson(Lesson lesson) async {
    if (isCourseSubmitted.value || lesson.isCompleted!) {
      Get.snackbar(
        'Info',
        lesson.isCompleted!
            ? 'Lesson already completed.'
            : 'Course already submitted.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
      return;
    }
    currentLesson.value = lesson;
    await markLessonCompleted();
  }

  void handleEnroll() async {
    isLoading.value = true;
    if (allLessons.isNotEmpty) {
      playLesson(allLessons[0], 0);
    }
    isLoading.value = false;
  }

  void togglePlayPause() {
    final controller = videoPlayerController.value;
    if (controller != null) {
      if (controller.value.isPlaying) {
        controller.pause();
        showControls.value = true;
        _hideControlsTimer?.cancel();
      } else {
        controller.play();
        showControls.value = true;
        _startHideControlsTimer();
      }
    }
  }

  void toggleControlsVisibility() {
    showControls.value = !showControls.value;

    if (showControls.value &&
        videoPlayerController.value?.value.isPlaying == true) {
      _startHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      showControls.value = false;
    });
  }

  void toggleOrientation() {
    isLandscape.value = !isLandscape.value;
    SystemChrome.setPreferredOrientations([
      isLandscape.value
          ? DeviceOrientation.landscapeRight
          : DeviceOrientation.portraitUp,
    ]);
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void onClose() {
    videoPlayerController.value?.dispose();
    tabController.dispose();
    _hideControlsTimer?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.onClose();
  }

  Future<void> fetchCourseProgress(String? courseId) async {
    // developer.log('Fetching course progress for course ID: $courseId',
    //     name: 'CourseVideoController');
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final user = await _prefs.getUser();
      if (user == null || user.token.isEmpty) {
        Utils.snackBar(
          'Authentication Error',
          'Please log in to view course progress.',
        );
        Get.offNamed(RouteName.loginScreen);
        return;
      }

      final url =
          '${ApiUrls.baseUrl}/connect/v1/api/user/course/progress/$courseId';
      // developer.log('Fetching course progress, url: $url',
      //     name: 'CourseVideoController');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${user.token}',
          'Content-Type': 'application/json',
        },
      );

      // developer.log('Course Progress Response Status: ${response.statusCode}',
      //     name: 'CourseVideoController');
      // developer.log('Course Progress Response Body: ${response.body}',
      //     name: 'CourseVideoController');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        courseProgress.value = CourseProgressModel.fromJson(jsonResponse);
        // developer.log('Course Progress: ${courseProgress.value!.toJson()}',
        //     name: 'CourseVideoController');
      } else if (response.statusCode == 401) {
        Utils.snackBar(
          'Session Expired',
          'Please log in again.',
        );
        await _prefs.removeUser();
        Get.offNamed(RouteName.loginScreen);
      } else {
        throw Exception('Failed to fetch course progress: ${response.body}');
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      // developer.log('Course Progress Error: $e', name: 'CourseVideoController');

      String message;
      if (e.toString().contains('SocketException')) {
        message = 'No internet connection. Please check your network.';
      } else if (e.toString().contains('TimeoutException')) {
        message = 'Request timed out. Please try again later.';
      } else if (e.toString().contains('401')) {
        message = 'Session expired. Please log in again.';
        await _prefs.removeUser();
        Get.offNamed(RouteName.loginScreen);
        return;
      } else if (e.toString().contains('404')) {
        message = 'Course progress not found. Verify the course ID.';
      } else {
        message = 'Failed to load course progress.';
      }

      Utils.snackBar(
        message,
        'Error',
      );
    } finally {
      isLoading.value = false;
    }
  }
}
