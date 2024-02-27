import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/core/global_data.dart';
import 'package:app_ft_movies/app/view/detail/detail_view.dart';
import 'package:app_ft_movies/app/widgets/global_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class CardCinema extends StatefulWidget {
  final String? imageLink;
  final String? nameProduct;
  final String? originName;
  final String? slug;
  final String? path;

  const CardCinema({
    Key? key,
    this.imageLink,
    this.nameProduct,
    this.originName,
    this.slug, this.path,
  }) : super(key: key);

  @override
  State<CardCinema> createState() => _CardCinemaState();
}

class _CardCinemaState extends State<CardCinema> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.back();
        Get.to( DetailView(
      slug: widget.slug,
      name: widget.nameProduct,
      path: widget.path,
    ),);
        
        
//        Navigator.of(context).push(
//   MaterialPageRoute(
//     builder: (context) => DetailView(
//       slug: widget.slug,
//       name: widget.nameProduct,
//       path: widget.path,
//     ),
//   ),
// );

      },
      onHover: (hovering) {
        setState(() {
          isHovering = hovering;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: isHovering ? Matrix4.diagonal3Values(1.05, 1.05, 1) : Matrix4.identity(),


        child: Container(
          // height: 250,
          width: MediaQuery.of(context).size.width < 600?MediaQuery.of(context).size.width*.4:MediaQuery.of(context).size.width * 0.15,
          // decoration: BoxDecoration(
          //   borderRadius: BorderRadius.circular(3),
          //   // border: Border.all(color: isHovering ? Colors.white : Colors.transparent, width: 2),
          //   color: GlobalColor.background2,
          // ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: GlobalImage(
                  imageUrl: widget.imageLink ?? "",
                  width: MediaQuery.of(context).size.width < 600?MediaQuery.of(context).size.width:MediaQuery.of(context).size.width * 0.1,
                  height: MediaQuery.of(context).size.width < 600?MediaQuery.of(context).size.height*.28:MediaQuery.of(context).size.height * .4,
                  boxFit: BoxFit.fill,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
                child: Text(
                  widget.nameProduct ?? '--',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    height: 1.5,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3),
                child: Text(
                  widget.originName ?? "--",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    height: 1.5,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

