import 'package:app_ft_movies/app/controller/filter/filter_controller.dart';
import 'package:app_ft_movies/app/controller/home/home_controller.dart';
import 'package:app_ft_movies/app/controller/search/search_widget_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';

import 'package:app_ft_movies/app/view/filter/filter_page.dart';
import 'package:app_ft_movies/app/view/header/header_view.dart';
import 'package:app_ft_movies/app/view/history/history_view.dart';

import 'package:app_ft_movies/app/view/home/film_by_category/film_by_category.dart';

import 'package:app_ft_movies/app/view/home/slider/slider_cinema.dart';
import 'package:app_ft_movies/app/view/list_movie/list_movie.dart';
import 'package:app_ft_movies/app/view/search/search_view.dart';
import 'package:app_ft_movies/app/widgets/search_widget.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
   
    final searchController = Get.put(SearchWidgetController());
    final filterController = Get.put(FilterController());
    final controller = Get.put(HomeController());
    
    return GetBuilder<HomeController>(
      init: controller,
      builder: (controller) {
        return DefaultTabController(
           length: controller.tabItem.length,
          initialIndex: controller.tabIndex.value ?? 0,
          child: Scaffold(
            backgroundColor: GlobalColor.backgroundColor,
            appBar:const HeaderPage(),
            body: RefreshIndicator(
                backgroundColor: GlobalColor.backgroundColor,
                color: GlobalColor.primary,
                onRefresh: () async {
                  searchController.isSearch.value = false;
                  controller.scrollController.value?.jumpTo(0);
                  await controller.getFilm(
                      slug: controller.tabItem[controller.tabIndex.value ?? 0]['slug']);
                  controller.getFilmByCategory(
                      slug: controller.tabItem[controller.tabIndex.value ?? 0]['slug']);
                },
                child: CustomScrollView(
                  controller: controller.scrollController.value,
                  slivers: [
                     
                     SliverToBoxAdapter(
                      child: Center(child: Container(
                        
                         color: GlobalColor.backgroundColor,
                    width: MediaQuery.of(context).size.width<600?MediaQuery.of(context).size.width:MediaQuery.of(context).size.width * .85,
                        child: Column(
                          children: [
                           SliderCinema(),
                           const SizedBox(height: 20,),
                            Obx(() => Visibility(
                              visible: searchController.isSearch.value==false,
                              child: const FilterPage()),)
                          ],
                        )
                        )),
                    ),
                    Obx(
                      () => Visibility(
                        visible: searchController.isSearch.value == true,
                        replacement: Visibility(
                          visible: filterController.onFilter.value==true,
                          replacement: const FilmByCategory(),
                          child: const ListMovieView(),
                          
                          ),
                        child: const SearchView(),
                      ),
                    )
                  ],
                )),
          ),
        );
      },
    );
  }
}
