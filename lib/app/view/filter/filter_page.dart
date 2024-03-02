import 'dart:convert';

import 'package:app_ft_movies/app/controller/filter/filter_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FilterPage extends StatelessWidget {
  const FilterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FilterController());
    if(MediaQuery.of(context).size.width<600){
      return const InMobile();
    }
   return const InWeb();
  }
}

class InWeb extends StatelessWidget {
  const InWeb({super.key});

 @override
  Widget build(BuildContext context) {
    final controller = Get.put(FilterController());
   return Obx(() => Container(
    width: MediaQuery.of(context).size.width,
    padding: EdgeInsets.symmetric(horizontal: 10,vertical: 10),
    decoration: BoxDecoration(
      // color: GlobalColor.background2,
      borderRadius: BorderRadius.circular(5)
    ),
    margin: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Lọc phim",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
          const SizedBox(width: 30,),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            height: 40,
            decoration: BoxDecoration(
              color: GlobalColor.background2,
              borderRadius: BorderRadius.circular(5),
              
            ),
            child: DropdownButton(
              hint: const Text("Thể loại",style: TextStyle(color: Colors.white),),
              dropdownColor: GlobalColor.background2,
              style: const TextStyle(color: Colors.white),
              value: controller.selectedGenre.value,
              
              underline: const SizedBox(),
              
              items: controller.genreList.map((e){
                return DropdownMenuItem(
                  value: e["slug"].toString(),
                  child: Text(e["title"]));
              }).toList(),
               onChanged: (value){
                controller.selectedGenre.value = value;
                controller.getFilmFilter();
               }
               
            ),
          ),
          const SizedBox(width: 30,),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            height: 40,
            decoration: BoxDecoration(
              color: GlobalColor.background2,
              borderRadius: BorderRadius.circular(5),
             
            ),
            child: DropdownButton(
              underline: const SizedBox(),
              hint: const Text("Quốc gia",style: TextStyle(color: Colors.white),),
               dropdownColor: GlobalColor.background2,
              style: const TextStyle(color: Colors.white),
              value: controller.selectedCountry.value,
              items: controller.countries.map((e){
                return DropdownMenuItem(
                  value: e["slug_country"].toString(),
                  child: Text(e["name"]));
              }).toList(),
               onChanged: (value){
                controller.selectedCountry.value = value;
                controller.getFilmFilter();
               }
               
            ),
          ),
      
           const SizedBox(width: 30,),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            height: 40,
            decoration: BoxDecoration(
              color: GlobalColor.background2,
              borderRadius: BorderRadius.circular(5),
              // border: Border.all(color: Colors.white)
            ),
            child: DropdownButton(
              underline: const SizedBox(),
              hint: const Text("Năm",style: TextStyle(color: Colors.white),),
               dropdownColor: GlobalColor.background2,
              style: const TextStyle(color: Colors.white),
              value: controller.selectedYear.value,
              items: controller.yearList.map((e){
                return DropdownMenuItem(
                  value: e["year"].toString(),
                  child: Text(e["year"].toString()));
              }).toList(),
               onChanged: (value){
                controller.selectedYear.value = value;
                controller.getFilmFilter();
               }
               
            ),
          ),
         
          
          
        ],
      ),
    ));
  }
}

class InMobile extends StatelessWidget {
  const InMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FilterController());
   return Obx(() => Container(
    width: MediaQuery.of(context).size.width,
    
    decoration: BoxDecoration(
      // color: GlobalColor.background2,
      borderRadius: BorderRadius.circular(5)
    ),
    margin: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(width: 5,),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            height: 40,
            decoration: BoxDecoration(
              color: GlobalColor.background2,
              borderRadius: BorderRadius.circular(5),
              // border: Border.all(color: Colors.white)
            ),
            child: DropdownButton(
              hint: const Text("Thể loại",style: TextStyle(color: Colors.white),),
              dropdownColor: GlobalColor.background2,
              style: const TextStyle(color: Colors.white),
              value: controller.selectedGenre.value,
              
              underline: const SizedBox(),
              
              items: controller.genreList.map((e){
                return DropdownMenuItem(
                  value: e["slug"].toString(),
                  child: Text(e["title"]));
              }).toList(),
               onChanged: (value){
                controller.selectedGenre.value = value;
                print(">>>>>>>>>>>>${controller.selectedGenre.value}");
                controller.getFilmFilter();
               }
               
            ),
          ),
          const SizedBox(width: 10,),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            height: 40,
            decoration: BoxDecoration(
              color: GlobalColor.background2,
              borderRadius: BorderRadius.circular(5),
              // border: Border.all(color: Colors.white)
            ),
            child: DropdownButton(
              underline: const SizedBox(),
              hint: const Text("Quốc gia",style: TextStyle(color: Colors.white),),
               dropdownColor: GlobalColor.background2,
              style: const TextStyle(color: Colors.white),
              value: controller.selectedCountry.value,
              items: controller.countries.map((e){
                return DropdownMenuItem(
                  value: e["slug_country"].toString(),
                  child: Text(e["name"]));
              }).toList(),
               onChanged: (value){
                controller.selectedCountry.value = value;
                controller.getFilmFilter();
               }
               
            ),
          ),
      
           const SizedBox(width: 10,),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            height: 40,
            decoration: BoxDecoration(
              color: GlobalColor.background2,
              borderRadius: BorderRadius.circular(5),
              // border: Border.all(color: Colors.white)
            ),
            child: DropdownButton(
              underline: const SizedBox(),
              hint: const Text("Năm",style: TextStyle(color: Colors.white),),
               dropdownColor: GlobalColor.background2,
              style: const TextStyle(color: Colors.white),
              value: controller.selectedYear.value,
              items: controller.yearList.map((e){
                return DropdownMenuItem(
                  value: e["year"].toString(),
                  child: Text(e["year"].toString()));
              }).toList(),
               onChanged: (value){
                controller.selectedYear.value = value;
                controller.getFilmFilter();
               }
               
            ),
          ),
          
          
          
        ],
      ),
    ));
  }
}