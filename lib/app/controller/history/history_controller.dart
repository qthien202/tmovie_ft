import 'package:app_ft_movies/app/core/global_data.dart';
import 'package:app_ft_movies/app/data/apis/services.dart';
import 'package:app_ft_movies/app/data/repository/get_history_response.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryController extends GetxController{
   final Services api = Get.find();
   Rxn<GetHistoryRespone>getHistoryData = Rxn();
   Rx<int>limit = Rx(10);
   RxBool isLoadmore = RxBool(false);

   @override
   onReady(){
    super.onReady();
    getHistory();
    loadMore();
    
   }

   Future<GetHistoryRespone?>getHistory()async{
  
     final SharedPreferences sharedPreferences  = await SharedPreferences.getInstance();
     String userToken = await sharedPreferences.getString(GlobalData.userToken)??"";
    
    getHistoryData.value=await api.getHistory(token: userToken,limit: limit.value);
    return getHistoryData.value;
   }

  final ScrollController scrollController = ScrollController();
  Future<void>loadMore()async {
    scrollController.addListener(() async{
      if(scrollController.position.maxScrollExtent == scrollController.offset){
        
        if((limit.value)<(getHistoryData.value?.total??0)){
          isLoadmore.value = true;
          
          limit.value+=10;
          
          await getHistory();
          isLoadmore.value = false;
        }



      }
    });
    
  }
}