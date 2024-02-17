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
  Rx<int> tabIndex = Rx(0);
  Rxn<String>pathFilm = Rxn();
  Rx<int>currentIndex = Rx(0);
  Rx<int>selectTab = Rx(0);
  Rx<bool>isFocusSlider = RxBool(false);
  Rx<bool>isFocusSeeAll = RxBool(false);

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
    {"id":"10","title": "Viễn tưởng", "slug": "vien-tuong"},
    {"id":"11","title": "Phiêu lưu", "slug": "phieu-luu"},
    {"id":"12","title": "Khoa học", "slug": "khoa-hoc"},
    
  ];
  RxList<Map<String, dynamic>> categories = RxList();
  Rxn<ScrollController> scrollController = Rxn();
  Rx<int>page = Rx(1);

  @override
  void onReady() async {
    // TODO: implement onReady
    super.onReady();
    categories.addAll(categoryList);
    pathFilm.value = "phim-bo";
     getFilm(slug: "phim-bo");
    await getFilmByCategory(slug: "phim-bo");
    // getFimCategory.refresh();
    
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

  Future<void> watchNow({required String slug}) async {
    await detail.getFilmDetail(slug: slug);
    final data = detail.filmDetail.value?.pageProps?.data?.item;

    Get.to(ChewieVideoPlayer(
        slug: data?.slug ?? "",
        videoUrl: data?.episodes?.first.serverData?.first.linkM3u8 ?? "",
        fileName: data?.name ?? "",
        episode: data?.episodes?.first.serverData?.first.name ?? ""));
        
  }
}
