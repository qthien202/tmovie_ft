import 'package:app_ft_movies/app/data/apis/services.dart';
import 'package:app_ft_movies/app/data/repository/get_film_by_category.dart';
import 'package:get/get.dart';

class ListMovieController extends GetxController {
  final Services api = Get.find();

  Rxn<GetFilmByCategory> listMovie = Rxn();
  Rxn<int> selectPage = Rxn(0);
  Rxn<int> selectIndex = Rxn(0);
  Rxn<int> totalPage = Rxn();
  RxBool isFocusPage = RxBool(false);
  RxBool isFocusMenu = RxBool(false);
  Future<GetFilmByCategory?> getListMovie(
      {int? page,
      String? path,
      String? category,
      String? country,
      String? year}) async {
    // final path = Get.parameters['slug'];
    // final category = Get.parameters['category'];
    // final country = Get.parameters['country'];
    // final year = Get.parameters['year'];
    listMovie.value = await api.getFilmByCategory(
        path: path ?? "",
        page: page,
        category: category ?? "",
        country: country ?? "",
        year: year ?? "");
    for (var i = 0;
        i < (listMovie.value?.pageProps?.data?.items?.length ?? 0);
        i++) {
      listMovie.value?.pageProps?.data?.items
          ?.removeWhere((element) => element.category?.first.slug == "phim-18");
    }

    listMovie.refresh();
    final double itemLength =
        (listMovie.value?.pageProps?.data?.params?.pagination?.totalItems ??
                0) /
            (listMovie.value?.pageProps?.data?.params?.pagination
                    ?.totalItemsPerPage ??
                0);
    totalPage.value = itemLength.round();
    return listMovie.value;
  }
}
