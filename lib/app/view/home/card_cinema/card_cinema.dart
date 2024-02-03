import 'package:app_ft_movies/app/view/detail/detail_view.dart';
import 'package:app_ft_movies/app/widgets/global_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';


class CardCinema extends StatelessWidget {
  final String? imageLink;
  final String? nameProduct;
  final String?  originName;
  final String? slug;
 
  // final String? shortDescript;
  const CardCinema({
    Key? key,
    this.imageLink,
    this.nameProduct,
    this.originName, this.slug,
  
    // this.shortDescript


  }) : super(key: key);


  @override
  Widget build(BuildContext context) {

    return Container(

      // height: MediaQuery.of(context).size.height*.25,
      // padding: EdgeInsets.symmetric(vertical: 20),
      width: MediaQuery.of(context).size.width*.4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        // border: Border.all(color: Colors.red),
        border: Border.all(color: Colors.transparent,width: 0),
        color: Color(0xff252836),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(5),
              topRight: Radius.circular(5)
            ),
            child: InkWell(
              onTap: ()=>Get.to(DetailView(slug: slug,name: nameProduct,)),
              child: GlobalImage(
                
                imageUrl: imageLink??"",
                
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height*.25,
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
            padding: const EdgeInsets.symmetric(horizontal: 8.0,vertical: 5),
            child: Text(nameProduct??'',
              // textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  height: 1.5,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                color: Colors.white
                  ),),
          ),
           Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0,vertical: 5),
            child: Text("( $originName )",
              // textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  height: 1.5,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                color: Colors.white
                  ),),
          ),

          // Visibility(
          //     visible: widget.shortDes!='',
          //     child:Column(
          //       children: [
          //         Text(
          //           widget.shortDes??'',
          //           style: const TextStyle(fontSize: 12,
          //             fontWeight: FontWeight.w300,
          //           ),
          //           maxLines: 1,),
          //         const SizedBox(height: 5,),
          //       ],
          //     )
          // ),
         
          
          
        ],
      ),
    );
  }
}
