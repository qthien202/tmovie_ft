import 'dart:developer';
import 'package:app_ft_movies/app/data/apis/services.dart';
import 'package:app_ft_movies/app/data/repository/get_film_by_category.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class SearchWidgetController extends GetxController {
  final Services api = Get.find();
  Rxn<GetFilmByCategory> search = Rxn();
  TextEditingController keywordController = TextEditingController();
  Rxn<int> selectPage = Rxn(0);
  Rxn<int> selectIndex = Rxn(0);
  Rxn<int> totalPage = Rxn();
  RxBool isFocusPage = RxBool(false);
  RxBool isFocusMenu = RxBool(false);
  Rx<int> currentPage = RxInt(1);
  // final  genre = Get.put(MovieGenreController());

  void onReady() async {
    super.onReady();
    search.value = await api.getMovieGenre(
        path: "hanh-dong", page: 1, country: "", year: "2024");
    // await getSearch(page: 1);
  }

  Future<GetFilmByCategory?> getSearch({int? page}) async {
    search.value =
        await api.getSearch(keyWord: keywordController.text, page: page);
    for (var i = 0;
        i < (search.value?.pageProps?.data?.items?.length ?? 0);
        i++) {
      search.value?.pageProps?.data?.items
          ?.removeWhere((element) => element.category?.first.slug == "phim-18");
    }
    search.refresh();
    final double itemLength =
        (search.value?.pageProps?.data?.params?.pagination?.totalItems ?? 0) /
            (search.value?.pageProps?.data?.params?.pagination
                    ?.totalItemsPerPage ??
                0);
    totalPage.value = itemLength.round();
    //  final data = search.value?.pageProps?.data;
    // for(var i =0; i<=(data?.items?.length ?? 0);i++){
    //   if(data?.items?[i].slug!="phim-18"){
    //     totalSearch.value = data?.items?.length??0;
    //   }
    // }
    return search.value;
  }
}
