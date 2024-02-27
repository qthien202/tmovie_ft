import 'package:app_ft_movies/app/controller/history/history_controller.dart';
import 'package:app_ft_movies/app/core/global_data.dart';
import 'package:app_ft_movies/app/data/apis/services.dart';

import 'package:app_ft_movies/app/data/repository/get_film_details.dart';
import 'package:app_ft_movies/app/data/repository/post_add_history.dart';
import 'package:app_ft_movies/app/data/repository/post_create_token.dart';
import 'package:app_ft_movies/app/data/repository/post_create_token_response.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailController extends GetxController{
  final Services api = Get.find();
  Rxn<GetFilmDetails>filmDetail = Rxn();
  Rxn<int>selectTab = Rxn(0);
  Rxn<int>selectIndex = Rxn(0);
  Rxn<PostCreateTokenResponse>postCreateTokenData = Rxn();
  RxBool isFocus = RxBool(false);
  RxBool isFocusEp = RxBool(false);
  Rxn<int>selectIndexServer = Rxn(0);

  @override
  void onReady()async{
    super.onReady();
    selectIndexServer.value = 0;
  }
  
  Future<GetFilmDetails?>getFilmDetail({required String slug})async{
    
    selectIndexServer.value = 0;
    filmDetail.value = await api.getFilmDetails(path: slug);
    filmDetail.refresh();
    return filmDetail.value;
  }


  Future<void>createToken({ required String name, required String slug, required String thumbnail, required String originName, required String episode, required String description})async{
    final SharedPreferences sharedPreferences  = await SharedPreferences.getInstance();
    if(sharedPreferences.getString(GlobalData.userToken)==null){
      postCreateTokenData.value=await api.postCreateToken();
      await sharedPreferences.setString(GlobalData.userToken, postCreateTokenData.value?.token??"");
      
    }
    String userToken = await sharedPreferences.getString(GlobalData.userToken)??"";
      await api.postAddHistory(body: PostAddHistory(userToken: userToken, name: name, slug: slug, thumbnail: thumbnail, originName: originName, episode: episode, description: description));
      final controller = Get.put(HistoryController());
      controller.onReady();
     
  }

 
}