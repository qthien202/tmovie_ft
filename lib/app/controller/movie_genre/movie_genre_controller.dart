import 'package:app_ft_movies/app/data/apis/services.dart';
import 'package:app_ft_movies/app/data/repository/get_film_by_category.dart';
import 'package:get/get.dart';

class MovieGenreController extends GetxController{
  
  final Services2 api = Get.find();
  
  Rxn<GetFilmByCategory>movieGenre = Rxn();
  Rxn<int>selectIndex = Rxn(0);
  

  @override
  void onReady() async{
    // TODO: implement onReady
    super.onReady();
    
    
  }

  

  Future<GetFilmByCategory?>getMovieGenre({required String? slug})async{
    movieGenre.value = await api.getMovieGenre(path: slug??"", slug: slug??"",page: (selectIndex.value??0)+1);
    movieGenre.refresh();
    return movieGenre.value;
  }
}