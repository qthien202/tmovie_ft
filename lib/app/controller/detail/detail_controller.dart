import 'package:app_ft_movies/app/data/apis/services.dart';

import 'package:app_ft_movies/app/data/repository/get_film_details.dart';
import 'package:get/get.dart';

class DetailController extends GetxController{
  final Services2 api = Get.find();
  Rxn<GetFilmDetails>filmDetail = Rxn();
  Rxn<String>selectTab = Rxn();

  Future<GetFilmDetails?>getFilmDetail({required String slug})async{
    filmDetail.value = await api.getFilmDetails(slug: slug,path: slug);
    filmDetail.refresh();
    return filmDetail.value;
  }
}