import 'package:app_ft_movies/app/view/index/index_view.dart';
import 'package:get/get.dart';

class SplashController extends GetxController{
  @override
  void onReady() {
    // TODO: implement onReady
    super.onReady();
    // Get.offAll(IndexView());
    Future.delayed(const Duration(seconds: 3),()=>Get.offAll(const IndexView()));
  }
}