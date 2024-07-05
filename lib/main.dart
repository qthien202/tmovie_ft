import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tmovie_app/app/core/dependency_injections.dart';
import 'package:tmovie_app/app/core/global_color.dart';
import 'package:tmovie_app/app/view/splash/splash.dart';
import 'package:universal_io/io.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DependencyInjections().dependencies();

  // Check if the app is running on a mobile device
  if (Platform.isAndroid || Platform.isIOS) {
    runApp(const MyApp());
  } else {
    // Optionally, you can show a message or a different widget for non-mobile devices
    runApp(const UnsupportedDevice());
  }
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
        textTheme: const TextTheme(
          bodyText1: TextStyle(color: Colors.white, fontSize: 14),
          bodyText2: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      home: const SplashView(),
    );
  }
}

class UnsupportedDevice extends StatelessWidget {
  const UnsupportedDevice({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: GlobalColor.backgroundColor,
        // appBar: AppBar(
        //   title: const Text('Unsupported Device'),
        // ),
        body: const Center(
          child: Text(
            'Ứng dụng chỉ hỗ trợ trên thiết bị di động Android / Ios',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
