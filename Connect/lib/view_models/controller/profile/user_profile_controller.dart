import 'package:connectapp/models/userProfile/user_profile_model.dart';
import 'package:connectapp/repository/UserProfile/user_profile_repository.dart';
import 'package:get/get.dart';
import '../../../data/response/status.dart';
import '../../../models/UserProfile/user_profile_media_list_model.dart';
import '../userPreferences/user_preferences_screen.dart';

class UserProfileController extends GetxController {
  final _api = GetUserProfileRepository();
  final _prefs = UserPreferencesViewmodel();

  final rxRequestStatus = Status.LOADING.obs;
  final userList = UserProfileModel().obs;
  final userMediaList = <Media>[].obs;
  final error = ''.obs;

  void setError(String value) {
    error.value = value;
    // log('Error set: $value');
  }

  void setRxRequestStatus(Status value) => rxRequestStatus.value = value;
  void setUserList(UserProfileModel value) {
    userList.value = value;
    // log('UserList updated: xp=${value.xp}, nextLevelAt=${value.nextLevelAt}');
  }

  void setUserMediaList(UserProfileMediaListModel value) {
    userMediaList.value = value.media;

    // log('UserMediaList updated: count=${userMediaList.length}, items=${userMediaList}');
  }

  @override
  void onInit() {
    super.onInit();
    userListApi();
  }

  Future<void> userListApi() async {
    setRxRequestStatus(Status.LOADING);
    try {
      final loginData = await _prefs.getUser();
      if (loginData == null || loginData.token.isEmpty) {
        setError("User not authenticated. Token not found.");
        print("============User Profile Controller logout called");
        setRxRequestStatus(Status.ERROR);
        return;
      }
      // log("TOKEN: ${loginData.token}");
      final value = await _api.userProfileData(loginData.token.toString());
      // log("API Response: $value");
      setUserList(value);
      setRxRequestStatus(Status.COMPLETED);
    } catch (e) {
      // log("API Error: $e", stackTrace: stackTrace);
      setError(e.toString());
      setRxRequestStatus(Status.ERROR);
    }
  }

  Future<void> mediaListApi(String chatType, String userId) async {
    setRxRequestStatus(Status.LOADING);
    try {
      final loginData = await _prefs.getUser();
      if (loginData == null || loginData.token.isEmpty) {
        setError("User not authenticated. Token not found.");
        print("============User Profile controller logout called");
        setRxRequestStatus(Status.ERROR);
        return;
      }
      // log("TOKEN: ${loginData.token}");
      final value = await _api.userMediaListData(
          loginData.token.toString(), chatType, userId);
      // log("API Response: $value");
      setUserMediaList(value);
      setRxRequestStatus(Status.COMPLETED);
    } catch (e) {
      // log("API Error: $e", stackTrace: stackTrace);
      setError(e.toString());
      setRxRequestStatus(Status.ERROR);
    }
  }

  Future<void> refreshApi() async {
    setRxRequestStatus(Status.LOADING);
    try {
      final loginData = await _prefs.getUser();
      if (loginData == null || loginData.token.isEmpty) {
        setError("User not authenticated. Token not found.");
        setRxRequestStatus(Status.ERROR);
        return;
      }
      // log("Refresh TOKEN: ${loginData.token}");
      final value = await _api.userProfileData(loginData.token);

      setUserList(value);
      setRxRequestStatus(Status.COMPLETED);
    } catch (e) {
      setError(e.toString());
      setRxRequestStatus(Status.ERROR);
    }
  }
}
