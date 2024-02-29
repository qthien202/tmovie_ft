import 'package:app_ft_movies/app/view/detail/detail_view.dart';
import 'package:app_ft_movies/app/view/home/home_view.dart';
import 'package:app_ft_movies/app/view/list_movie/list_movie.dart';
import 'package:app_ft_movies/app/view/movie_genre/movie_genre_view.dart';
import 'package:app_ft_movies/app/view/splash/splash.dart';
import 'package:get/get.dart';


class Routes {
  static final List<GetPage> routes = [
    
    GetPage(name: '/', page: () =>  HomeView()),
    GetPage(name: '/chi-tiet/:slug', page: ()=>const DetailView()),
    GetPage(name: '/the-loai/:category', page: ()=>const MovieGenreview()),
    GetPage(name: '/loai-phim/:slug', page: ()=>const ListMovieView())
    
    // Các route khác ở đây
  ];
}
