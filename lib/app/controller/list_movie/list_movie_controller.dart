import 'package:app_ft_movies/app/data/apis/services.dart';
import 'package:app_ft_movies/app/data/repository/get_film_by_category.dart';
import 'package:get/get.dart';

class ListMovieController extends GetxController{
  final Services2 api = Get.find();
  
  Rxn<GetFilmByCategory>listMovie = Rxn();
  Rxn<int>selectIndex = Rxn(0);

  Future<GetFilmByCategory?>getListMovie({required String slug})async{
    listMovie.value = await api.getFilmByCategory(path: slug, slug: slug,page: (selectIndex.value??0)+1);
    listMovie.refresh();
    return listMovie.value;
  }


}