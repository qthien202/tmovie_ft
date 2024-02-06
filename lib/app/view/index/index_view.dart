import 'package:app_ft_movies/app/controller/index/index_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/drawer/drawer_view.dart';
import 'package:app_ft_movies/app/view/home/home_view.dart';
import 'package:app_ft_movies/app/view/search/search_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class IndexView extends StatelessWidget {
  const IndexView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(IndexController());
    final List<Map<String,dynamic>>items = [
      {
        "screen":const HomeView(),
        "icon":Icons.home,
        "title":"Trang chủ"
      },

      {
        "screen":const SearchView(),
        "icon":Icons.search,
        "title":"Tìm kiếm"
      }
    ];
    final GlobalKey<ScaffoldState> key = GlobalKey<ScaffoldState>();
    return Scaffold(
      key: key,
      endDrawer:  Drawer(
        child: FilterPage(),
      ),
      // appBar: AppBar(
      //   backgroundColor: GlobalColor.backgroundColor,
      //   centerTitle: false,
      //   title: Text("TMOVIE",style: TextStyle(
      //     color: GlobalColor.primary,
      //     fontSize: 16,
      //     fontWeight: FontWeight.bold
      //   ),),
      //   actions: [
          
      //     InkWell(
      //       onTap: (){
      //         key.currentState?.openEndDrawer();
      //       },
      //       child: Padding(
      //         padding: const EdgeInsets.symmetric(horizontal:8.0),
      //         child: const Icon(
      //           Icons.menu,
      //           color: Colors.white,
      //         ),
      //       ),
      //     ),
      //   ],
      // ),
      backgroundColor: GlobalColor.backgroundColor,
      body: Obx(() => items[controller.tabIndex.value??0]['screen']),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Container(
          decoration: BoxDecoration(
            color: GlobalColor.backgroundColor,
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                color: Colors.black.withOpacity(.1),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(

              onTabChange: (value)=>controller.tabIndex.value=value,
                // rippleColor: Colors.grey[800], // tab button ripple color when pressed
                // hoverColor: Colors.grey[700], // tab button hover color
                 rippleColor: Color(0xff252836),
                    hoverColor: Color(0xff252836),
                    gap: 5,
                    activeColor: GlobalColor.primary,
                    iconSize: 25,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    duration: Duration(milliseconds: 400),
                    tabBackgroundColor: Color(0xff252836),
                    color: Colors.grey,
                tabs: items.map((e){
                  return GButton(
                    icon: e['icon'],
                    text: e['title'],
                  );
                }).toList()
            ),
          ),
        ),
      ),
    );
  }
}
