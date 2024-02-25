import 'package:app_ft_movies/app/controller/search/search_widget_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/filter/filter_page.dart';
import 'package:app_ft_movies/app/view/home/card_cinema/card_cinema.dart';
import 'package:app_ft_movies/app/widgets/search_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SearchWidgetController());
    return SliverList.list(
      
      children: [

      Padding(
        padding: EdgeInsets.symmetric(horizontal: 20,vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() => Text("Kết quả tìm kiếm: ${controller.textSearch.value??"--"}",style: TextStyle(fontSize: 16),)),
            const SizedBox(height: 10,),
        Obx(() {
          final isLoading = controller.search.value == null;
          final data = controller.search.value?.pageProps?.data;
        
          if (data?.items == null) {
            return Center(
              child: CircularProgressIndicator(
               color: GlobalColor.primary,
            strokeWidth: 5,
            backgroundColor: const Color(0xff252836),
              ),
            );
          }
          if (data?.items?.isEmpty == true) {
            return const Center(
              child: Text("Rất tiếc phim bạn tìm kiếm không tồn tại!"),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(5),
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: isLoading ? 16 : data?.items?.length ?? 0,
            itemBuilder: (context, index) {
              final items = data?.items?[index];
              return Visibility(
                visible: !isLoading,
                replacement: SizedBox(
                    width: MediaQuery.of(context).size.width * .4,
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey,
                      highlightColor: Colors.grey.shade600,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                        ),
                      ),
                    )),
                child: CardCinema(
                  imageLink: items?.thumbUrl ?? "",
                  nameProduct: items?.name,
                  originName: items?.originName ?? "",
                  slug: items?.slug ?? "",
                ),
              );
            },
            gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
              childAspectRatio: MediaQuery.of(context).size.width < 600?12/33:6 / 10,
              crossAxisCount: MediaQuery.of(context).size.width < 600?3:6,
              crossAxisSpacing: MediaQuery.of(context).size.width < 600?5:15,
              mainAxisSpacing: MediaQuery.of(context).size.width < 600?5:20,
            ),
          );
        }),
        const SizedBox(
          height: 20,
        ),
        Obx(() {
          return Visibility(
            visible: controller.totalPage.value != 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.totalPage.value ?? 0,
                  itemBuilder: (context, index) {
                    return Obx(() {
                      return InkWell(
                        onHover: (value) {
                          controller.isFocusPage.value = value;
                          controller.selectIndex.value = index;
                        },
                        onTap: () async {
                          controller.selectIndex.value = index;
                          print(">>>>>>>>>>>>>${controller.selectIndex.value}");
                          controller.search.value = null;
                          await controller.getSearch(page: index + 1);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 15),
                          decoration: BoxDecoration(
                              //  border: Border.all(color: GlobalColor.primary)
                              color: const Color(0xff252836),
                              border: Border.all(
                                  color: controller.selectIndex.value == index &&
                                          controller.isFocusPage.value
                                      ? GlobalColor.primary
                                      : Colors.transparent)),
                          child: Text(
                            "${index + 1}",
                            style: TextStyle(
                                fontSize: 13,
                                color: controller.selectPage.value == index
                                    ? GlobalColor.primary
                                    : Colors.white),
                          ),
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
      )
    ]);
  }
}
