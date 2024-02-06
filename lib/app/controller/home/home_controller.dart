import 'package:app_ft_movies/app/controller/detail/detail_controller.dart';
import 'package:app_ft_movies/app/data/apis/services.dart';
import 'package:app_ft_movies/app/data/repository/get_film_by_category.dart';
import 'package:app_ft_movies/app/data/repository/get_new_film.dart';
import 'package:app_ft_movies/app/widgets/video_player.dart';
import 'package:get/get.dart';

class HomeController extends GetxController { 
  final Services api = Get.find();
  final detail = Get.put(DetailController());
  
  Rxn<GetNewFilm>getNewFilmData = Rxn();
  Rxn<GetFilmByCategory>phimBo = Rxn();
  Rxn<GetFilmByCategory>phimLe = Rxn();
  Rxn<GetFilmByCategory>shows = Rxn();
  Rxn<GetFilmByCategory>hoatHinh = Rxn();
  Rxn<GetFilmByCategory>vietSub = Rxn();
  Rxn<GetFilmByCategory>thuyetMinh = Rxn();
  Rxn<GetFilmByCategory>longTieng = Rxn();
  Rxn<GetFilmByCategory>dangChieu = Rxn();
  Rxn<GetFilmByCategory>tronBo = Rxn();
  Rxn<GetFilmByCategory>sapChieu = Rxn();
  
  Rxn<int>activeIndex = Rxn();

  @override
  void onReady() async{
    // TODO: implement onReady
    super.onReady();
    await getNewFilm();
    await getFilmByCategory();
  }

  Future<GetNewFilm?>getNewFilm()async{
    getNewFilmData.value = await api.getNewFilm();
    return getNewFilmData.value;
  }

  Future<void>getFilmByCategory()async{
    phimLe.value = await api.getFilmByCategory(path: "phim-le", page: 1);
    phimBo.value = await api.getFilmByCategory(path: "phim-bo", page: 1);
    shows.value = await api.getFilmByCategory(path: "tv-shows", page: 1);
    hoatHinh.value = await api.getFilmByCategory(path: "hoat-hinh", page: 1);
    vietSub.value = await api.getFilmByCategory(path: "phim-vietsub", page: 1);
    thuyetMinh.value = await api.getFilmByCategory(path: "phim-thuyet-minh", page: 1);
    longTieng.value = await api.getFilmByCategory(path: "phim-long-tieng", page: 1);
    dangChieu.value = await api.getFilmByCategory(path: "phim-bo-dang-chieu", page: 1);
    tronBo.value = await api.getFilmByCategory(path: "phim-hoan-thanh", page: 1);
    sapChieu.value = await api.getFilmByCategory(path: "phim-sap-chieu", page: 1);



  }

  Future<void>watchNow({required String slug})async{
    
    await detail.getFilmDetail(slug: slug);
    final data = detail.filmDetail.value?.pageProps?.data?.item;
    
    Get.to(ChewieVideoPlayer(
      videoUrl: data?.episodes?.first.serverData?.first.linkM3u8??"",
       fileName: data?.name??"",
        episode: data?.episodes?.first.serverData?.first.name??""
        ));

  }

}