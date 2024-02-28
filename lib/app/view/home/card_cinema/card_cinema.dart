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
  State<CardCinema> createState() => _CardCinemaState();
}

class _CardCinemaState extends State<CardCinema> {
  bool isFocus = false;
  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
        },
      child: InkWell(
        
        
        onTap: () {
         Get.to(DetailView(
          slug: widget.slug,
          name: widget.nameProduct,
        ));
         
        },
        onFocusChange: (hasFocus){
          setState(() {
            isFocus = hasFocus;
          });
        },
        child: AnimatedContainer(
          color: Colors.transparent,
          duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: isFocus ? Matrix4.diagonal3Values(1.05, 1.05, 1) : Matrix4.identity(),
          child: Container(
            // height: MediaQuery.of(context).size.height*.5,
            // padding: EdgeInsets.symmetric(vertical: 20),
            width: MediaQuery.of(context).size.width * .15,
            color: GlobalColor.backgroundColor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isFocus?Colors.white:Colors.transparent,width: 2.5),
                     boxShadow: isFocus
                          ? [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5), // Màu của boxShadow
                                spreadRadius: 1, // Bán kính lan rộng của boxShadow
                                blurRadius: 5, // Độ mờ của boxShadow
                                offset: const Offset(0, 2), // Độ dịch chuyển của boxShadow
                              ),
                            ]
                          : [],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GlobalImage(
                        imageUrl:widget.imageLink??"",
                      width: MediaQuery.of(context).size.width*.2,
                      height: MediaQuery.of(context).size.height * .45,
                      boxFit: BoxFit.fill,
                    ),
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
                widget.nameProduct ?? '--',
                // textAlign: TextAlign.center,
                maxLines: 2,
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
                widget.originName??"--",
                // textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    height: 1.5,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: Colors.white),
                                ),
                              )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
