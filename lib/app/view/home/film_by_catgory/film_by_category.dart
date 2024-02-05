import 'package:app_ft_movies/app/controller/home/home_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/data/repository/get_film_by_category.dart';
import 'package:app_ft_movies/app/view/home/card_cinema/card_cinema.dart';
import 'package:app_ft_movies/app/view/list_movie/list_movie.dart';
import 'package:app_ft_movies/app/view/movie_genre/movie_genre_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class FilmByCategory extends StatelessWidget {
  const FilmByCategory({super.key, this.getFilmByCategory, this.type});
  final GetFilmByCategory? getFilmByCategory;
  final String? type;

  @override
   @override
  Widget build(BuildContext context) {
    final isLoading = getFilmByCategory==null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal:5),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(type??"",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
              TextButton(onPressed: (){
                Get.to(ListMovieView(slug: getFilmByCategory?.pageProps?.data?.typeList??"", titlePage: type??""));
              }, child: Text("Xem thêm",style: TextStyle(color: GlobalColor.primary),)
              )
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height*.4,
            child: ListView.separated(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: isLoading?5:getFilmByCategory?.pageProps?.data?.items?.length??0,
              itemBuilder: (context,index){
                final data = getFilmByCategory?.pageProps?.data?.items?[index];
                return Visibility(
                  visible: !isLoading,
                  replacement: SizedBox(
                     width: MediaQuery.of(context).size.width*.4,
                     child: Shimmer.fromColors(
                                baseColor: Colors.grey,
                                highlightColor: Colors.grey.shade600,
                                child: Container(
                                  decoration: BoxDecoration(
                                   
                                    color: Colors.grey,
                                  ),
                                ),
                    )
                                
                  ),
                  child: CardCinema(
                    nameProduct: data?.name,
                    imageLink:data?.thumbUrl,
                    originName: data?.originName,
                    slug: data?.slug,
                  ),
                );
              }, separatorBuilder: (BuildContext context, int index)=>const SizedBox(width: 8,),
            ),
          ),
        ],
      ),
    );
  }
}