import 'package:app_ft_movies/app/controller/home/home_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/drawer/filter_page.dart';
import 'package:app_ft_movies/app/view/home/film_by_category/film_by_category.dart';
import 'package:app_ft_movies/app/view/home/new_film/new_film.dart';
import 'package:app_ft_movies/app/view/home/most_popular/most_popular.dart';
import 'package:app_ft_movies/app/view/home/slider/slider_cinema.dart';
import 'package:app_ft_movies/app/widgets/search_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> listFilm = [
      {"slug": "phim-bo", "title": "Phim bộ"},
      {"slug": "phim-le", "title": "Phim lẻ"},
      {"slug": "tv-shows", "title": "TV Shows"},
      {"slug": "hoat-hinh", "title": "Hoạt hình"},
      {"slug": "phim-vietsub", "title": "Phim vietsub"},
      {"slug": "phim-thuyet-minh", "title": "Phim thuyết minh"},
      {"slug": "phim-long-tieng", "title": "Phim lồng tiếng"},
      {"slug": "phim-bo-dang-chieu", "title": "Phim bộ đang chiếu"},
      {"slug": "phim-hoan-thanh", "title": "Phim trọn bộ"},
      {"slug": "phim-sap-chieu", "title": "Phim sắp chiếu"}
    ];

    final controller = Get.put(HomeController());
    
    return DefaultTabController(
      length: listFilm.length,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: GlobalColor.backgroundColor,
        body: RefreshIndicator(
            backgroundColor: GlobalColor.backgroundColor,
            onRefresh: () async => controller.onReady(),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  centerTitle: false,
                  title: TabBar(
                    tabAlignment: TabAlignment.center,
                    indicatorWeight: 5,
                    isScrollable: true,
                    dividerColor: Colors.transparent,
                    indicatorColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 14),
                    labelColor: Colors.white,
                    labelStyle:
                        const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                        onTap: (ind)async{
                          controller.pathFilm.value = listFilm[ind]['slug'];
                          controller.tabIndex.value = ind;
                          await controller.getFilm(slug: listFilm[ind]['slug'],);
                          controller.getFilmByCategory(slug: listFilm[ind]['slug'],);
                          // controller.refresh();
                          // controller.update();
                         
                          
                          
                         
                        },
                    tabs: List<Widget>.generate(listFilm.length, (int index) {
                      return Tab(
                        text: listFilm[index]["title"],
                      );
                    }),
                  ),
                
                  elevation: 0.0,

                  backgroundColor: GlobalColor.backgroundColor,
                  systemOverlayStyle: const SystemUiOverlayStyle(
                      statusBarBrightness: Brightness.dark),
                  expandedHeight: MediaQuery.of(context).size.height * .6,
                  flexibleSpace: const FlexibleSpaceBar(
                    background: SliderCinema(),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: FilmByCategory(),
                )
              ],
            )),
      ),
    );
  }
}

