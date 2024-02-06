import 'package:app_ft_movies/app/controller/search/search_widget_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchWidget extends StatelessWidget {
  final Widget? toPage;
  const SearchWidget({super.key,  this.toPage});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SearchWidgetController());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        onSubmitted: (val)async{
          controller.selectIndex.value = 0;
          await controller.getSearch();
        },
        onChanged: (val)async{
          controller.selectIndex.value = 0;

          await controller.getSearch();
        },
        controller: controller.keywordController,
        readOnly: false,
        decoration: InputDecoration(
          hintText: 'Nhập phim bạn cần tìm',
          hintStyle: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w300,
            fontSize: 14
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 10,horizontal: 20),
          suffixIcon: Icon(Icons.search,color: Colors.grey,size: 20,),
          filled: true,
          fillColor: Color(0xff252836),
          border: OutlineInputBorder(
      
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
                color: Colors.transparent
            ),
      
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
                color: Colors.transparent
            ),
          ),
          enabledBorder:  OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
                color: Colors.transparent
            ),
          ),
      
        ),
      ),
    );
  }
}