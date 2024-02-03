import 'dart:developer';

import 'package:app_ft_movies/app/data/apis/services.dart';
import 'package:app_ft_movies/app/data/repository/get_film_by_category.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class SearchWidgetController extends GetxController{
  final Services2 api = Get.find();
  Rxn<GetFilmByCategory>search = Rxn();
  TextEditingController keywordController = TextEditingController();
  Rxn<int>totalSearch = Rxn(0);

  void onReady()async{
    super.onReady();
    await getSearch();
  }
  

  Future<GetFilmByCategory?>getSearch()async{
   
    search.value = await api.getSearch(keyWord: keywordController.text);
    search.refresh();
    //  final data = search.value?.pageProps?.data;
    // for(var i =0; i<=(data?.items?.length ?? 0);i++){
    //   if(data?.items?[i].slug!="[redacted]"){
    //     totalSearch.value = data?.items?.length??0;
    //   }
    // }
    return search.value;
  }

  
}