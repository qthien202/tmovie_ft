import 'package:app_ft_movies/app/controller/splash/splash_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SplashController());
    return Scaffold(
      backgroundColor: GlobalColor.backgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(child: SvgPicture.asset("assets/images/logo.svg")),
          const SizedBox(height: 5,),
          CircularProgressIndicator(
            color: GlobalColor.primary,
            strokeWidth: 5,
            backgroundColor: const Color(0xff252836),
          ),
          const SizedBox(height: 10,),
          Text("Đang tải")
        ],
      )
    );
  }
}
