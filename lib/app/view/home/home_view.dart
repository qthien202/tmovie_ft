import 'package:app_ft_movies/app/controller/home/home_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/drawer/drawer_view.dart';
import 'package:app_ft_movies/app/view/home/film_by_catgory/film_by_category.dart';
import 'package:app_ft_movies/app/view/home/most_popular/most_popular.dart';
import 'package:app_ft_movies/app/view/home/slider/slider_cinema.dart';
import 'package:app_ft_movies/app/widgets/search_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    
    return Scaffold(
      
      backgroundColor: GlobalColor.backgroundColor,
      
      body: RefreshIndicator(
        onRefresh: ()async=>controller.onReady(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: ListView(
            children: [
              Column(
                children:  [
                  
                  const SliderCinema(),
                  const MostPopular(),
                  Obx(() => FilmByCategory(type: "Phim bộ",getFilmByCategory: controller.phimBo.value),),
                  Obx(() => FilmByCategory(type: "Phim lẻ",getFilmByCategory: controller.phimLe.value,)),
                  Obx(() => FilmByCategory(type: "TV show",getFilmByCategory: controller.shows.value,)),
                  Obx(() => FilmByCategory(type: "Hoạt hình",getFilmByCategory: controller.hoatHinh.value,))
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
