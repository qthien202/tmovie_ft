import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tmovie_app/app/core/dependency_injections.dart';
import 'package:tmovie_app/app/core/global_color.dart';
import 'package:tmovie_app/app/view/splash/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DependencyInjections().dependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TMOVIE',
      theme: ThemeData(
        primaryColor: GlobalColor.backgroundColor,
        useMaterial3: true,
        indicatorColor: GlobalColor.primary,
        progressIndicatorTheme: ProgressIndicatorThemeData(
          // circularTrackColor: GlobalColor.primary,
          color: GlobalColor.primary,
        ),
      ),
      home: const SplashView(),
    );
  }
}
