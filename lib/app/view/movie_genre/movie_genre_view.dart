import 'package:app_ft_movies/app/controller/movie_genre/movie_genre_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/detail/detail_view.dart';
import 'package:app_ft_movies/app/view/home/card_cinema/card_cinema.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MovieGenreview extends StatelessWidget {
  final String slug;
  final String titlePage;
  const MovieGenreview({super.key, required this.slug, required this.titlePage});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MovieGenreController());
    controller.getMovieGenre(slug: slug);
    return Scaffold(
        backgroundColor: GlobalColor.backgroundColor,
        appBar: AppBar(
          backgroundColor: GlobalColor.backgroundColor,
          foregroundColor: Colors.white,
          title: Text(titlePage),
        ),
        body: ListView(
          children: [
            const SizedBox(
              height: 10,
            ),
            Obx((){
               final data = controller.movieGenre.value?.pageProps?.data;
              
              if(data?.items==null){
                return Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 5,
                    backgroundColor: GlobalColor.primary,
                  ),
                );
              }
              return GridView.builder(
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
                childAspectRatio: 12 / 20,
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
            );
            }),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
        bottomNavigationBar: Obx((){
          final int totalPage = int.parse(((controller.movieGenre.value?.pageProps?.data?.params?.pagination?.pageRanges??0).toString()));
          return Visibility(
          visible: totalPage!=0,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: totalPage,
                itemBuilder: (context, index) {
                  return Obx(() {
                    return InkWell(
                      onTap: () async{
                        controller.selectIndex.value = index;
                        print(">>>>>>>>>>>>>${controller.selectIndex.value}");
                        controller.movieGenre.value=null;
                        await controller.getMovieGenre(slug: slug);
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        decoration: BoxDecoration(
                            //  border: Border.all(color: GlobalColor.primary)
                            color: Color(0xff252836),
                            border: Border.all(
                                color: controller.selectIndex.value == index
                                    ? GlobalColor.primary
                                    : Colors.transparent)),
                        child: Text("${index + 1}"),
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
      );
  }
}