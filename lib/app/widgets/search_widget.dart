import 'package:app_ft_movies/app/controller/search/search_widget_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchWidget extends StatelessWidget {
  final Widget? toPage;
  const SearchWidget({super.key,  this.toPage});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SearchWidgetController());
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16,vertical: 5),
      child: TextField(
        onSubmitted: (val)async{
          controller.isSearch.value=true;
          controller.textSearch.value = controller.keywordController.text;
          controller.selectIndex.value = 0;
          
          await controller.getSearch();
          
          
        },
        // onChanged: (val)async{
        //   controller.selectIndex.value = 0;

        //   await controller.getSearch();
        // },
        controller: controller.keywordController,
        readOnly: false,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm...',
          hintStyle: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w300,
            fontSize: 14
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10,horizontal: 20),
          suffixIcon: const Icon(Icons.search,color: Colors.white,size: 20,),
          filled: true,
          fillColor: GlobalColor.background2,
          border: OutlineInputBorder(
      
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
                color: Colors.transparent
            ),
      
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
                color: Colors.transparent
            ),
          ),
          enabledBorder:  OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
                color: Colors.transparent
            ),
          ),
      
        ),
      ),
    );
  }
}