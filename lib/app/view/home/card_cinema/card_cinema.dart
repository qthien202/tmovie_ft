import 'package:app_ft_movies/app/core/global_data.dart';
import 'package:app_ft_movies/app/view/detail/detail_view.dart';
import 'package:app_ft_movies/app/widgets/global_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class CardCinema extends StatelessWidget {
  final String? imageLink;
  final String? nameProduct;
  final String? originName;
  final String? slug;

  // final String? shortDescript;
  const CardCinema({
    Key? key,
    this.imageLink,
    this.nameProduct,
    this.originName,
    this.slug,

    // this.shortDescript
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.to(DetailView(
        slug: slug,
        name: nameProduct,
      )),
      child: Container(
        // height: MediaQuery.of(context).size.height*.25,
        // padding: EdgeInsets.symmetric(vertical: 20),
        width: MediaQuery.of(context).size.width * .4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          // border: Border.all(color: Colors.red),
          border: Border.all(color: Colors.transparent, width: 0),
          color: const Color(0xff252836),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              // borderRadius: const BorderRadius.only(
              //   topLeft: Radius.circular(3),
              //   topRight: Radius.circular(3)
              // ),
              borderRadius: BorderRadius.circular(3),
              child: GlobalImage(
                 imageUrl: imageLink??"",
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * .25,
                boxFit: BoxFit.fill,
              ),
            ),

            // Image.network(
            //   widget.badgesLink??"",

            //   height: 10,
            //   fit: BoxFit.cover,
            // ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
              child: Text(
                nameProduct ?? '--',
                // textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    height: 1.5,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3),
              child: Text(
                originName??"--",
                // textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    height: 1.5,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
