import 'package:app_ft_movies/app/controller/index/index_controller.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/history/history_view.dart';
import 'package:app_ft_movies/app/view/home/home_view.dart';
import 'package:app_ft_movies/app/view/search/search_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class IndexView extends StatelessWidget {
  const IndexView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(IndexController());
    final List<Map<String, dynamic>> items = [
      {
        "screen": const HomeView(),
        "icon": Icons.home_outlined,
        "title": "Trang chủ"
      },
      {
        "screen": const SearchView(),
        "icon": Icons.search_outlined,
        "title": "Tìm kiếm"
      },
      {
        "screen": const HistoryView(),
        "icon": Icons.history_outlined,
        "title": "Lịch sử"
      },
    ];

    return Scaffold(
      
      body: Obx(() {
        return Row(
          children: [
            NavigationRail(
              // elevation: 0,
              groupAlignment: 0.0,
              useIndicator: false,
              indicatorColor: GlobalColor.primary,
              backgroundColor: GlobalColor.background2,
              unselectedIconTheme:
                  IconThemeData(color: Colors.white, opacity: 1),
              unselectedLabelTextStyle: TextStyle(
                color: Colors.white,
              ),
              selectedIconTheme:
                  IconThemeData(color: GlobalColor.primary),
              extended: false,
              selectedIndex: controller.tabIndex.value ?? 0,
              onDestinationSelected: (int index) {
                controller.tabIndex.value = index;
              },
              labelType: NavigationRailLabelType.all,
              
              destinations: items.map((item) {
                return NavigationRailDestination(

                  icon: Icon(item['icon'],size: 25,),
                  label: Text(""),
                  
                  
                   // Đặt chiều rộng tối thiểu tại đây
                );
              }).toList(),
            ),
            Expanded(
              flex: 4,
              child: items[controller.tabIndex.value ?? 0]['screen'],
            ),
          ],
        );
      }),
    );
  }
}
