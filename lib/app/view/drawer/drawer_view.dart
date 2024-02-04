import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/movie_genre/movie_genre_view.dart';

class FilterPage extends StatefulWidget {
  @override
  _FilterPageState createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  String? selectedGenre;
  String? selectedCountry;
  int? selectedYear;
  String? titlePage;

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

  List<Map<String, dynamic>> countries = [
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

  List<Map<String, dynamic>> yearsList = [
    {"year": 2010},
    {"year": 2011},
    {"year": 2012},
    {"year": 2013},
    {"year": 2014},
    {"year": 2015},
    {"year": 2016},
    {"year": 2017},
    {"year": 2018},
    {"year": 2019},
    {"year": 2020},
    {"year": 2021},
    {"year": 2022},
    {"year": 2023},
    {"year": 2024},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColor.backgroundColor,
      appBar: AppBar(
        backgroundColor: GlobalColor.backgroundColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
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
                if(selectedGenre==null){
                  Get.snackbar("Thông báo", "Bạn cần chọn thêm thể loại phim trước");
                }
                else{
                  Get.to(MovieGenreview(
                    titlePage: titlePage??"",
                  slug: selectedGenre ?? "",
                  country: selectedCountry??"",
                  year: selectedYear.toString(),
                ));
                }
              },
              child: Text("Duyệt phim", style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text('Thể loại', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Expanded(
            child: buildFilterList(drawerItems, selectedGenre, (genre) {
              setState(() {
                titlePage = genre['title'];
                selectedGenre = genre["slug"];
                
              });
            }),
          ),
          ListTile(
            title: Text('Quốc gia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Expanded(
            child: buildFilterList(countries, selectedCountry, (country) {
              setState(() {
                selectedCountry = country["slug"];
              });
            }),
          ),
          ListTile(
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
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 10 / 19,
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
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isSelected ? Color(0xff252836) : null,
        border: isSelected ? Border.all(color: GlobalColor.primary) : null,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: !isSelected ? Colors.white : GlobalColor.primary,
        ),
      ),
    ),
  );
}



}
