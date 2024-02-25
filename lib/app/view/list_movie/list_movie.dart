import 'package:app_ft_movies/app/controller/list_movie/list_movie_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/detail/detail_view.dart';
import 'package:app_ft_movies/app/view/filter/filter_page.dart';
import 'package:app_ft_movies/app/view/home/card_cinema/card_cinema.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class ListMovieView extends StatelessWidget {
  const ListMovieView({super.key,  this.slug,  this.country, this.category, this.year});
  final String? slug;
  
  final String? country;
  final String? category;
  final String? year;
  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> key = GlobalKey<ScaffoldState>();
    final controller = Get.put(ListMovieController());
    controller.getListMovie(slug: slug,category: category??"",country: country??"",year: year??"");
     
   
      return RefreshIndicator(
        backgroundColor: GlobalColor.backgroundColor,
        color: GlobalColor.primary,
        onRefresh: ()async=>controller.getListMovie(slug: slug,category: category??"",country: country??"",year: year??""),
        child: Scaffold(
         
          backgroundColor: GlobalColor.backgroundColor,
          appBar: AppBar(
            
            backgroundColor: GlobalColor.backgroundColor,
            foregroundColor: Colors.white,
            title: Obx(() => Text(controller.listMovie.value?.pageProps?.data?.titlePage??""),),
            actions: [
              Obx(() => InkWell(
                onHover: (hasFocus){
                  controller.isFocusMenu.value = hasFocus;
                  print(">>>>>>>>>>>>>>>>>$hasFocus");
                },
              onTap: (){
                Get.to( FilterPage(slug: slug??""),transition: Transition.rightToLeft);
              },
              child:  Padding(
                padding: EdgeInsets.symmetric(horizontal:8.0),
                child: AnimatedContainer(
                  duration: Duration(seconds: 200),
                 curve: Curves.easeInOut, 
                  child: Transform.scale(
                    scale: controller.isFocusMenu.value?1.2:1,
                    child: Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        border: Border.all(color: controller.isFocusMenu.value?Colors.white:Colors.transparent,width: 2)
                      ),
                      child: Icon(
                        Icons.filter_alt_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),)
            ],
          ),
          body: ListView(
            children: [
              const SizedBox(
                height: 10,
              ),
              Obx((){
                final isLoading = controller.listMovie.value==null;
                 final data = controller.listMovie.value?.pageProps?.data;
                
                
                return GridView.builder(
                  padding: const EdgeInsets.all(5),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: isLoading?16:data?.items?.length ?? 0,
                itemBuilder: (context, index) {
                  final items = data?.items?[index];
                  return Visibility(
                    visible: !isLoading ,
                    replacement: SizedBox(
                     width: MediaQuery.of(context).size.width*.4,
                     child: Shimmer.fromColors(
                                baseColor: Colors.grey,
                                highlightColor: Colors.grey.shade600,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    
                                    
                                    color: Colors.grey,
                                  ),
                                ),
                    )
                                
                  ),
                    child: CardCinema(
                      imageLink: items?.thumbUrl ?? "",
                      nameProduct: items?.name,
                      originName: items?.originName ?? "",
                      slug: items?.slug ?? "",
                    ),
                  );
                },
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  childAspectRatio: MediaQuery.of(context).size.width < 600?18/33:7 / 10,
              crossAxisCount: MediaQuery.of(context).size.width < 600?3:6,
              crossAxisSpacing: MediaQuery.of(context).size.width < 600?5:15,
              mainAxisSpacing: MediaQuery.of(context).size.width < 600?5:20,
                ),
              );
              }),
              const SizedBox(
                height: 20,
              ),
               Obx((){
            return Visibility(
            visible: controller.totalPage.value!=0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 20),
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.totalPage.value??0,
                  itemBuilder: (context, index) {
                    return Obx(() {
                      return InkWell(
                        onHover: (value) {
                          controller.isFocusPage.value=value;
                          controller.selectIndex.value = index;
                        },
                        onTap: () async{
                          controller.selectPage.value = index;
                          print(">>>>>>>>>>>>>${controller.selectIndex.value}");
                          controller.listMovie.value=null;
                          await controller.getListMovie(slug: slug,category: category,country: country);
                        },
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          decoration: BoxDecoration(
                              //  border: Border.all(color: GlobalColor.primary)
                              color: const Color(0xff252836),
                              border: Border.all(
                                  color: controller.selectIndex.value == index && controller.isFocusPage.value
                                      ? GlobalColor.primary
                                      : Colors.transparent)),
                          child: Text("${index + 1}",style: TextStyle(fontSize: 13,color: controller.selectPage.value == index 
                                      ? GlobalColor.primary
                                      : Colors.white),),
                        ),
                      );
                    });
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return const SizedBox(
                      width: 20,
                    );
                  },
                ),
              ),
            ),
          );
          })
            ],
          ),
         
        ),
      );
  }
}
