import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../res/color/app_colors.dart';

class ThemeController extends GetxController {
  var isDarkMode = false.obs;

  final storage = GetStorage();

  @override
  void onInit() {
    super.onInit();

    bool? savedTheme = storage.read('isDarkMode');
    isDarkMode.value = savedTheme??false;
    }

  ThemeData get lightTheme => ThemeData(
        scaffoldBackgroundColor: AppColors.whiteColor,
        primaryColor: AppColors.blueShade,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.blackColor),
          bodyMedium: TextStyle(color: AppColors.blackColor),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.blueShade,
          foregroundColor: AppColors.blackColor,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.buttonColor,
            foregroundColor: AppColors.whiteColor,
          ),
        ),
      );

  ThemeData get darkTheme => ThemeData(
    scaffoldBackgroundColor: const Color(0xFF181A20),
    primaryColor: const Color(0xFF22232F),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFEAEAF0)),
      bodyMedium: TextStyle(color: Color(0xFFB1B3B9)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF22232F),
      foregroundColor: Color(0xFFEAEAF0),
      elevation: 0,
    ),
    cardColor: const Color(0xFF22232F),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.buttonColor,
        foregroundColor: Color(0xFFEAEAF0),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      fillColor: Color(0xFF24243e),
      hintStyle: TextStyle(color: Color(0xFF79808B)),
    ),
    dialogBackgroundColor: const Color(0xFF22232F),
    iconTheme: const IconThemeData(color: Color(0xFFB1B3B9)),
  );

  void switchTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeTheme(isDarkMode.value ? darkTheme : lightTheme);
    storage.write('isDarkMode', isDarkMode.value);
  }

  ThemeData get currentTheme => isDarkMode.value ? darkTheme : lightTheme;
}
