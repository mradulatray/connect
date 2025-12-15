import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectapp/models/UserAvatar/user_avatar_model.dart';
import 'package:connectapp/data/network/network_api_services.dart';
import 'package:connectapp/res/api_urls/api_urls.dart';
import '../userPreferences/user_preferences_screen.dart';

class UserAvatarController extends GetxController {
  final _apiService = NetworkApiServices();
  final _dio = Dio();
  final userPreferences = UserPreferencesViewmodel();

  var purchasedAvatars = <PurchasedAvatars>[].obs;
  var currentAvatar = Rxn<CurrentAvatar>();
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var isUpdating = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Listen to errorMessage and show snackbar safely
    ever(errorMessage, (String msg) {
      if (msg.isNotEmpty && Get.context != null && !Get.isSnackbarOpen) {
        Get.snackbar(
          'Error',
          msg,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    });

    // Start fetching data
    fetchUserAvatars();
  }

  Future<void> fetchUserAvatars({bool isRefresh = false}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = await userPreferences.getUser();
      final token = user?.token;

      if (token == null || token.isEmpty) {
        errorMessage.value = 'Please log in to view your avatars.';
        return;
      }

      final response = await _apiService.getApi(ApiUrls.userAvatarApi, token: token);
      final userAvatarModel = UserAvatarModel.fromJson(response);

      purchasedAvatars.assignAll(userAvatarModel.purchasedAvatars ?? []);
      currentAvatar.value = userAvatarModel.currentAvatar;
    } catch (e) {
      errorMessage.value = 'Failed to load avatars. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateCurrentAvatar(String newAvatarId) async {
    try {
      isUpdating.value = true;

      final user = await userPreferences.getUser();
      final token = user?.token;

      if (token == null || token.isEmpty) {
        _showSnack('Error', 'Please log in to change your avatar.', isError: true);
        return false;
      }

      final response = await _dio.post(
        '${ApiUrls.baseUrl}/connect/v1/api/user/select-active-avatar',
        data: {'avatarId': newAvatarId},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final selectedAvatar = purchasedAvatars.firstWhere(
              (avatar) => avatar.sId == newAvatarId,
          orElse: () => PurchasedAvatars(sId: newAvatarId),
        );
        currentAvatar.value = CurrentAvatar(
          sId: selectedAvatar.sId,
          name: selectedAvatar.name,
          imageUrl: selectedAvatar.imageUrl,
        );
        await fetchUserAvatars(isRefresh: true);
        _showSnack('Success', 'Avatar changed successfully!', isError: false);
        return true;
      } else {
        _showSnack('Error', 'Failed to change avatar: ${response.statusMessage}', isError: true);
        return false;
      }
    } on DioException catch (e) {
      String msg = 'Failed to change avatar';
      if (e.response?.statusCode == 401) {
        msg = 'Authentication failed. Please log in again.';
        Get.offAllNamed('/login');
      } else {
        msg = e.message ?? msg;
      }
      _showSnack('Error', msg, isError: true);
      return false;
    } catch (e) {
      _showSnack('Error', 'An unexpected error occurred: $e', isError: true);
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  // Safe Snackbar Helper
  void _showSnack(String title, String message, {bool isError = true}) {
    if (Get.context != null && !Get.isSnackbarOpen) {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: isError ? Colors.red : Colors.green,
        colorText: Colors.white,
      );
    }
  }

  bool isAvatarPurchased(String avatarId) {
    return purchasedAvatars.any((avatar) => avatar.sId == avatarId);
  }
}