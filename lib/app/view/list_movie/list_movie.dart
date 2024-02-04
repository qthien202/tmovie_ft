import 'package:app_ft_movies/app/controller/list_movie/list_movie_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/detail/detail_view.dart';
import 'package:app_ft_movies/app/view/drawer/drawer_view.dart';
import 'package:app_ft_movies/app/view/home/card_cinema/card_cinema.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class ListMovieView extends StatelessWidget {
  const ListMovieView({super.key, required this.slug, required this.titlePage});
  final String slug;
  final String titlePage;
  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> key = GlobalKey<ScaffoldState>();
    final controller = Get.put(ListMovieController());
    controller.getListMovie(slug: slug);
     
   
      return RefreshIndicator(
        backgroundColor: GlobalColor.backgroundColor,
        onRefresh: ()async=>controller.getListMovie(slug: slug),
        child: Scaffold(
          endDrawer: Drawer(
            child: FilterPage(),
          ),
          key: key,
          backgroundColor: GlobalColor.backgroundColor,
          appBar: AppBar(
            backgroundColor: GlobalColor.backgroundColor,
            foregroundColor: Colors.white,
            title: Text(titlePage),
            actions: [
              InkWell(
              onTap: (){
                key.currentState?.openEndDrawer();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal:8.0),
                child: const Icon(
                  Icons.menu,
                  color: Colors.white,
                ),
              ),
            ),
            ],
          ),
          body: ListView(
            children: [
              const SizedBox(
                height: 10,
              ),
              Obx((){
                 final data = controller.listMovie.value?.pageProps?.data;
                
                if(data?.items==null){
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 5,
                      backgroundColor: GlobalColor.primary,
                    ),
                  );
                }
                return GridView.builder(
                  padding: EdgeInsets.all(5),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: data?.items?.length ?? 0,
                itemBuilder: (context, index) {
                  final items = data?.items?[index];
                  return CardCinema(
                    imageLink: items?.thumbUrl ?? "",
                    nameProduct: items?.name,
                    originName: items?.originName ?? "",
                    slug: items?.slug ?? "",
                  );
                },
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  childAspectRatio: 12 / 33,
                  crossAxisCount: 3,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                ),
              );
              }),
              const SizedBox(
                height: 20,
              ),
            ],
          ),
         bottomNavigationBar: Obx((){
            
            
            
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
                        onTap: () async{
                          controller.selectIndex.value = index;
                          print(">>>>>>>>>>>>>${controller.selectIndex.value}");
                          controller.listMovie.value=null;
                          await controller.getListMovie(slug: slug);
                        },
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          decoration: BoxDecoration(
                              //  border: Border.all(color: GlobalColor.primary)
                              color: const Color(0xff252836),
                              border: Border.all(
                                  color: controller.selectIndex.value == index
                                      ? GlobalColor.primary
                                      : Colors.transparent)),
                          child: Text("${index + 1}",style: const TextStyle(fontSize: 13),),
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
        ),
      );
  }
}
