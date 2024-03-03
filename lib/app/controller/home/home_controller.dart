import 'dart:convert';

import 'package:app_ft_movies/app/controller/detail/detail_controller.dart';
import 'package:app_ft_movies/app/data/apis/services.dart';
import 'package:app_ft_movies/app/data/repository/get_film_by_category.dart';
import 'package:app_ft_movies/app/data/repository/get_new_film.dart';
import 'package:app_ft_movies/app/widgets/video_player.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  final Services api = Get.find();
  final detail = Get.put(DetailController());
  Rxn<TabController> tabController = Rxn();
  Rxn<GetNewFilm> getNewFilmData = Rxn();
  Rx<Map<String, GetFilmByCategory>> getFimCategory = Rx({});
  Rxn<GetFilmByCategory> getFilmData = Rxn();
  RxBool isFocusTab = RxBool(false);
  RxBool isFocusInfo = RxBool(false);
  Rxn<int> activeIndex = Rxn();
  Rxn<int> tabIndex = Rxn(0);
  Rxn<String>pathFilm = Rxn();
  Rx<int>currentIndex = Rx(0);
  Rx<int>selectTab = Rx(0);
  Rx<bool>isFocusSlider = RxBool(false);
  Rx<bool>isFocusSeeAll = RxBool(false);
  Rxn<bool>isSearch = Rxn(false);

   final List<Map<String, dynamic>> tabItem = [
      {"slug": "phim-bo", "title": "Phim bộ"},
      {"slug": "phim-le", "title": "Phim lẻ"},
      {"slug": "tv-shows", "title": "TV Shows"},
      {"slug": "hoat-hinh", "title": "Hoạt hình"},
      // {"slug": "phim-vietsub", "title": "Phim vietsub"},
      // {"slug": "phim-thuyet-minh", "title": "Phim thuyết minh"},
      // {"slug": "phim-long-tieng", "title": "Phim lồng tiếng"},
      {"slug": "phim-bo-dang-chieu", "title": "Phim bộ đang chiếu"},
      // {"slug": "phim-hoan-thanh", "title": "Phim trọn bộ"},
      // {"slug": "phim-sap-chieu", "title": "Phim sắp chiếu"},
    ];
  List<Map<String, dynamic>> categoryList = [
    // {"title":"Tất thể loại","slug":""},
    {"id":"0","title": "Mới nhất",},
    {"id":"1","title": "Gia đình", "slug": "gia-dinh"},
    {"id":"2","title": "Học đường", "slug": "hoc-duong"},
    {"id":"3","title": "Tình cảm", "slug": "tinh-cam"},
    {"id":"4","title": "Hàn Quốc", "country": "han-quoc"},
    {"id":"5","title": "Trung Quốc", "country": "trung-quoc"},
    {"id":"6","title": "Hành động", "slug": "hanh-dong"},
    {"id":"7","title": "Cổ trang", "slug": "co-trang"},
    {"id":"8","title": "Tâm lý", "slug": "tam-ly"},
    {"id":"9","title": "Hình sự", "slug": "hinh-su"},
    
    
  ];
  RxList<Map<String, dynamic>> categories = RxList();
  Rxn<ScrollController> scrollController = Rxn();
  Rx<int>page = Rx(1);
  Rx<int>currentPage = Rx(0);
  
  @override
  void onReady() async {
    // TODO: implement onReady
    super.onReady();
    categories.addAll(categoryList);
    pathFilm.value = "phim-bo";
    getFilm(slug: "phim-bo");
     
    getFilmByCategory(slug:"phim-bo");
    getFimCategory.refresh();
    
    // getFimCategory.refresh();
  }
  @override
  void refresh()async{
    super.refresh();
    await getFilmByCategory(slug: "phim-bo");

  }

  Future<GetNewFilm?> getNewFilm() async {
    getNewFilmData.value = await api.getNewFilm();
    return getNewFilmData.value;
  }

  Future<void> getFilm(
      {required String slug,
      String? category,
      String? country,
      String? year}) async {
    getFilmData.value = null;

    getFilmData.value = await api.getFilmByCategory(
        path: slug, page: 1, category: category, country: country, year: year);
    getFilmData.refresh();
    // getFilmByCategory(slug: slug);
  }

  Future<void> getFilmByCategory(
      {required String slug,
      String? category,
      String? country,
      String? year}) async {
    for (var category in categories) {
      getFimCategory.value.remove(category['id']) ;
      


      getFimCategory.value[category['id']] = await api.getFilmByCategory(
          path: slug,
          page: 1,
          category: category['slug']??"",
          country: category['country']??"",
          year: year);
          
      getFimCategory.refresh();
      

     
    }
     
  }

 
}
