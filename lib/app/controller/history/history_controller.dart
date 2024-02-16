import 'package:app_ft_movies/app/core/global_data.dart';
import 'package:app_ft_movies/app/data/apis/services.dart';
import 'package:app_ft_movies/app/data/repository/get_history_response.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryController extends GetxController{
   final Services api = Get.find();
   Rxn<GetHistoryRespone>getHistoryData = Rxn();

   @override
   onReady(){
    getHistory();
    super.onReady();
   }

   Future<GetHistoryRespone?>getHistory()async{
     final SharedPreferences sharedPreferences  = await SharedPreferences.getInstance();
     String userToken = await sharedPreferences.getString(GlobalData.userToken)??"";
    
    getHistoryData.value=await api.getHistory(token: userToken);
    return getHistoryData.value;
   }
}