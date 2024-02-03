import 'package:app_ft_movies/app/controller/search/search_widget_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/home/card_cinema/card_cinema.dart';
import 'package:app_ft_movies/app/widgets/search_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SearchWidgetController());
    return Scaffold(
      backgroundColor: GlobalColor.backgroundColor,
      body: ListView(
        children: [
          const SearchWidget(),
          const SizedBox(height: 20,),
          Obx((){
               final data = controller.search.value?.pageProps?.data;
              
              if(data?.items?.isEmpty==true){
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
                return Visibility(
                  visible: items?.category?.first.slug!="[redacted]",
                  child: CardCinema(
                    imageLink: items?.thumbUrl ?? "",
                    nameProduct: items?.name,
                    originName: items?.originName ?? "",
                    slug: items?.slug ?? "",
                  ),
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
            const SizedBox(height: 20,),

        ],


      ),
    );
  }
}