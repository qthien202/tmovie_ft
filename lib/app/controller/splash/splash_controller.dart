import 'package:app_ft_movies/app/controller/home/home_controller.dart';
import 'package:app_ft_movies/app/view/index/index_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashController extends GetxController{
  final homeController = Get.put(HomeController());
  @override
  void onReady() async{
    // TODO: implement onReady
    super.onReady();
    await homeController.getFilm(slug: "phim-bo");
    Get.offAll(const IndexView());
    
  }
}