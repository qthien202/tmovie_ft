import 'package:app_ft_movies/app/data/apis/services.dart';
import 'package:app_ft_movies/app/data/repository/get_film_by_category.dart';
import 'package:app_ft_movies/app/data/repository/get_new_film.dart';
import 'package:get/get.dart';

class HomeController extends GetxController { 
  final Services api = Get.find();
  final Services2 api2 = Get.find();
  Rxn<GetNewFilm>getNewFilmData = Rxn();
  Rxn<GetFilmByCategory>phimBo = Rxn();
  Rxn<GetFilmByCategory>phimLe = Rxn();
  Rxn<GetFilmByCategory>shows = Rxn();
  Rxn<GetFilmByCategory>hoatHinh = Rxn();
  Rxn<int>activeIndex = Rxn();

  @override
  void onReady() async{
    // TODO: implement onReady
    super.onReady();
    await getNewFilm();
    await getFilmByCategory();
  }

  Future<GetNewFilm?>getNewFilm()async{
    getNewFilmData.value = await api.getNewFilm(page: "1");
    return getNewFilmData.value;
  }

  Future<void>getFilmByCategory()async{
    phimLe.value = await api2.getFilmByCategory(path: "phim-le", slug: "phim-le",page: 1);
    phimBo.value = await api2.getFilmByCategory(path: "phim-bo", slug: "phim-bo",page: 1);
    shows.value = await api2.getFilmByCategory(path: "tv-shows", slug: "tv-shows",page: 1);
    hoatHinh.value = await api2.getFilmByCategory(path: "hoat-hinh", slug: "hoat-hinh",page: 1);
  }

}