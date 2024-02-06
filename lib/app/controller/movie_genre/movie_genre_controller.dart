import 'package:app_ft_movies/app/data/apis/services.dart';
import 'package:app_ft_movies/app/data/repository/get_film_by_category.dart';
import 'package:get/get.dart';

class MovieGenreController extends GetxController{
  
  final Services api = Get.find();
  
  Rxn<GetFilmByCategory>movieGenre = Rxn();
  Rxn<int>selectIndex = Rxn(0);
  Rxn<int>totalPage = Rxn();
  

  @override
  void onReady() async{
    // TODO: implement onReady
    super.onReady();
    
    
  }

  

  Future<GetFilmByCategory?>getMovieGenre({required String? slug,required String country, required String year})async{
    movieGenre.value = await api.getMovieGenre(path: slug??"", page: (selectIndex.value??0)+1,country: country,year: year);
    movieGenre.refresh();
    final double itemLength = (movieGenre.value?.pageProps?.data?.params?.pagination?.totalItems??0) / (movieGenre.value?.pageProps?.data?.params?.pagination?.totalItemsPerPage??0);
    totalPage.value = itemLength.round();
    return movieGenre.value;
  }
}