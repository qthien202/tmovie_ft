import 'package:app_ft_movies/app/controller/index/index_controller.dart';
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

    WidgetsBinding.instance?.addPostFrameCallback((_) {
      Scaffold.of(context).openDrawer();
    });

    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[200],
              child: ListView(
                padding: EdgeInsets.zero,
                children: ListTile.divideTiles(
                  context: context,
                  tiles: items.map((item) {
                    return ListTile(
                      leading: Icon(item['icon']),
                      title: Text(item['title']),
                      onTap: () {
                        controller.tabIndex.value = items.indexOf(item);
                      },
                    );
                  }),
                ).toList(),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Obx(() => items[controller.tabIndex.value ?? 0]['screen']),
          ),
        ],
      ),
    );
  }
}
