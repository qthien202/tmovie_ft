// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:app_ft_movies/app/view/list_movie/list_movie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/movie_genre/movie_genre_view.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({
    Key? key,
     this.slug,
  }) : super(key: key);
   final String? slug;
  @override
  _FilterPageState createState() => _FilterPageState();
  
}

class _FilterPageState extends State<FilterPage> {
  String? selectedGenre;
  String? selectedCountry;
  int? selectedYear;
  

  List<Map<String, dynamic>> drawerItems = [
    // {"title":"Tất thể loại","slug":""},
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

  List<Map<String, dynamic>> countries = [
    {"name":"Tất cả quốc gia","slug":""},
    {"name": "Trung Quốc", "slug": "trung-quoc"},
    {"name": "Hàn Quốc", "slug": "han-quoc"},
    {"name": "Nhật Bản", "slug": "nhat-ban"},
    {"name": "Thái Lan", "slug": "thai-lan"},
    {"name": "Âu Mỹ", "slug": "au-my"},
    {"name": "Đài Loan", "slug": "dai-loan"},
    {"name": "Hồng Kông", "slug": "hong-kong"},
    {"name": "Ấn Độ", "slug": "an-do"},
    {"name": "Anh", "slug": "anh"},
    {"name": "Pháp", "slug": "phap"},
    {"name": "Canada", "slug": "canada"},
    {"name": "Quốc Nga", "slug": "quoc-nga"},
    {"name": "Mexico", "slug": "mexico"},
    {"name": "Ba lan", "slug": "ba-lan"},
    {"name": "Úc", "slug": "uc"},
    {"name": "Thụy Điển", "slug": "thuy-dien"},
    {"name": "Malaysia", "slug": "malaysia"},
    {"name": "Brazil", "slug": "brazil"},
    {"name": "Philippines", "slug": "philippines"},
    {"name": "Bồ Đào Nha", "slug": "bo-dao-nha"},
    {"name": "Ý", "slug": "y"},
    {"name": "Đan Mạch", "slug": "dan-mach"},
    {"name": "UAE", "slug": "uae"},
    {"name": "Na Uy", "slug": "na-uy"},
    {"name": "Thụy Sĩ", "slug": "thuy-si"},
    {"name": "Châu Phi", "slug": "chau-phi"},
    {"name": "Nam Phi", "slug": "nam-phi"},
    {"name": "Ukraina", "slug": "ukraina"},
    {"name": "Ả Rập Xê Út", "slug": "arap-xe-ut"},
  ];

  // Lấy năm hiện tại


// Tạo danh sách các năm từ 2010 đến năm hiện tại
List<Map<String, dynamic>> yearsList = List.generate(
  DateTime.now().year - 2009, // Số lượng năm là hiện tại trừ 2010 + 1
  (index) => {"year": 2010 + index}, // Tạo map cho mỗi năm
);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColor.backgroundColor,
      appBar: AppBar(
        backgroundColor: GlobalColor.backgroundColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GlobalColor.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              onPressed: () {
               if(widget.slug!=null){
                Get.to(ListMovieView(
                  
                  country: selectedCountry??"",
                  year: selectedYear.toString()??"",
                  category: selectedGenre ?? "",
                  slug: widget.slug,
                ));
               }
               else{
                 if(selectedGenre==null){
                  Get.snackbar("Thông báo", "Bạn cần chọn thể loại phim trước");
                }
                else{
                  Get.to(MovieGenreview(
                   
                  slug: selectedGenre ?? "",
                  country: selectedCountry??"",
                  year: selectedYear.toString()??"",
                ));
                }
               }
              },
              child: const Text("Duyệt phim", style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
      body: Column(
        // crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ListTile(
            title: Text('Thể loại', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Expanded(
            child: buildFilterList(drawerItems, selectedGenre, (genre) {
              setState(() {
                
                selectedGenre = genre["slug"];
                
              });
            }),
          ),
          const ListTile(
            title: Text('Quốc gia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Expanded(
            child: buildFilterList(countries, selectedCountry, (country) {
              setState(() {
                selectedCountry = country["slug"];
              });
            }),
          ),
          const ListTile(
            title: Text('Năm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Expanded(
            child: buildFilterList(yearsList, selectedYear, (year) {
              setState(() {
                selectedYear = year["year"];
              });
            }),
          ),
        ],
      ),
    );
  }

  Widget buildFilterList(List<Map<String, dynamic>> items, dynamic selectedItem, Function(Map<String, dynamic>) onTap) {
    return GridView.builder(
      scrollDirection: Axis.horizontal,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        // mainAxisExtent: 3,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
        childAspectRatio: 7 / 35,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () {
            onTap(item);
          },
          child: buildFilterItem(
            text: item["title"] ?? item["name"] ?? item["year"].toString(),
            isSelected: selectedItem!=null?((selectedItem == item["slug"] || selectedItem == item["year"] || selectedItem == item["name"])):false,
          ),
        );
      },
    );
  }

  Widget buildFilterItem({required String text, required bool isSelected}) {
  
  
  return Center(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xff252836) : null,
        
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        textAlign: TextAlign.start,
        style: TextStyle(
          fontSize: 11,
          color: !isSelected ? Colors.white : GlobalColor.primary,
          
        ),
      ),
    ),
  );
}



}
