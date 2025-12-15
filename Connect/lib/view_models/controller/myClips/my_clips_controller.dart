import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/response/status.dart';
import '../../../models/MyAllClips/my_all_clips_model.dart';
import '../../../repository/MyClips/my_clips_repository.dart';
import '../userPreferences/user_preferences_screen.dart';

class MyClipsController extends GetxController {
  final _api = MyClipsRepository();
  final _prefs = UserPreferencesViewmodel();
  DateTime? _lastRefresh;

  final rxRequestStatus = Status.LOADING.obs;
  final myClips = Rxn<MyAllClipsModel>();
  final error = ''.obs;

  void setError(String value) => error.value = value;
  void setRxRequestStatus(Status value) => rxRequestStatus.value = value;
  void setMyClips(MyAllClipsModel? value) => myClips.value = value;

  // Separate getters for public & private
  List<Clips> get publicClips =>
      myClips.value?.clips?.where((c) => c.isPrivate == false).toList() ?? [];

  List<Clips> get privateClips =>
      myClips.value?.clips?.where((c) => c.isPrivate == true).toList() ?? [];

  @override
  void onInit() {
    super.onInit();
    fetchMyClips();
  }

  Future<void> _loadMyClips({bool isRefresh = false}) async {
    setRxRequestStatus(Status.LOADING);

    try {
      final loginData = await _prefs.getUser();
      if (loginData == null || loginData.token.isEmpty) {
        setError("User not authenticated. Token not found.");
        setRxRequestStatus(Status.ERROR);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      if (!isRefresh) {
        final cachedData = prefs.getString('my_clips_cache');
        if (cachedData != null) {
          setMyClips(MyAllClipsModel.fromJson(jsonDecode(cachedData)));
          setRxRequestStatus(Status.COMPLETED);
          return;
        }
      }

      final response = await _api.myAllClips(loginData.token);
      setMyClips(response);
      setRxRequestStatus(Status.COMPLETED);

      await prefs.setString('my_clips_cache', jsonEncode(response.toJson()));
    } catch (err) {
      setError(err.toString());
      setRxRequestStatus(Status.ERROR);
    }
  }

  Future<void> fetchMyClips() async {
    await _loadMyClips();
  }

  Future<void> refreshMyClips() async {
    final now = DateTime.now();
    if (_lastRefresh != null && now.difference(_lastRefresh!).inSeconds < 5) {
      return;
    }
    _lastRefresh = now;
    await _loadMyClips(isRefresh: true);
  }
}
