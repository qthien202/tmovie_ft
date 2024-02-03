import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/movie_genre/movie_genre_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

List<Map<String, dynamic>> drawerItems = [
  {"title": "Hành Động", "slug": "hanh-dong"},
  {"title": "Tình Cảm", "slug": "tinh-cam"},
  {"title": "Hài Hước", "slug": "hai-huoc"},
  {"title": "Cổ Trang", "slug": "co-trang"},
  {"title": "Tâm Lý", "slug": "tam-ly"},
  {"title": "Hình Sự", "slug": "hinh-su"},
  {"title": "Chiến Tranh", "slug": "chien-tranh"},
  {"title": "Thể Thao", "slug": "the-thao"},
  {"title": "Võ Thuật", "slug": "vo-thuat"},
  {"title": "Viễn Tưởng", "slug": "vien-tuong"},
  {"title": "Phiêu Lưu", "slug": "phieu-luu"},
  {"title": "Khoa Học", "slug": "khoa-hoc"},
  {"title": "Kinh Dị", "slug": "kinh-di"},
  {"title": "Âm Nhạc", "slug": "am-nhac"},
  {"title": "Thần Thoại", "slug": "than-thoai"},
  {"title": "Tài Liệu", "slug": "tai-lieu"},
  {"title": "Gia Đình", "slug": "gia-dinh"},
  {"title": "Chính kịch", "slug": "chinh-kich"},
  {"title": "Bí ẩn", "slug": "bi-an"},
  {"title": "Học Đường", "slug": "hoc-duong"},
];

class FilterPage extends StatefulWidget {
  @override
  _FilterPageState createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  String? selectedGenre;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColor.backgroundColor,
      appBar: AppBar(
        backgroundColor: GlobalColor.backgroundColor,
        title: Text('Thể loại',style: TextStyle(color: Colors.white),),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: drawerItems.length,
              itemBuilder: (context, index) {
                final genre = drawerItems[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedGenre = genre["slug"];
                    });
                    Get.to(MovieGenreview(slug: genre["slug"],titlePage: genre["title"],));
                  },
                  child: Center(
                    child: Text(
                      genre["title"],
                      style: TextStyle(
                        fontSize: 16,
                        color: selectedGenre == genre["slug"]
                            ? GlobalColor.primary
                            : Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
        ],
      ),
    );
  }
}

// void main() {
//   runApp(MaterialApp(
//     home: FilterPage(),
//   ));
// }
