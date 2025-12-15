import 'package:connectapp/res/assets/image_assets.dart';
import 'package:flutter/material.dart';
import 'dart:developer';
import '../../view_models/services/splash_service_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final SplashServices splashServices = SplashServices();

  @override
  void initState() {
    super.initState();
    log('[SPLASH_SCREEN] initState triggered');
    splashServices.initSplash();
  }

  @override
  Widget build(BuildContext context) {
    log('[SPLASH_SCREEN] build triggered');
    return Scaffold(
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: Image.asset(ImageAssets.splashLogo),
        ),
      ),
    );
  }
}