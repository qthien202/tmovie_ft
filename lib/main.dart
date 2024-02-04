import 'package:app_ft_movies/app/core/dependency_injections.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/splash/splash.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() async{
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
          circularTrackColor: GlobalColor.primary
        ),
        textTheme: TextTheme(
          bodyText1:TextStyle(
            color: Colors.white,
            fontSize: 14
          ),
          bodyText2:TextStyle(
            color: Colors.white,
            fontSize: 14
          )  
        )

        
      ),
      home: const SplashView(),
    );
  }
}


