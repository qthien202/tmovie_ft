import 'dart:ui';

import 'package:app_ft_movies/app/core/dependency_injections.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/core/routes.dart';
import 'package:app_ft_movies/app/view/home/home_view.dart';
import 'package:app_ft_movies/app/view/splash/splash.dart';
import 'package:app_ft_movies/app/widgets/connect_wrap/connect_wrap_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      getPages: Routes.routes,
      // initialRoute: '/',
      scrollBehavior: MyCustomScrollBehavior(),
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
      
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}


