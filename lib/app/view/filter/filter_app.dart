import 'package:app_ft_movies/app/view/list_movie/list_movie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_ft_movies/app/core/global_color.dart';
import 'package:app_ft_movies/app/view/movie_genre/movie_genre_view.dart';

class FilterApp extends StatefulWidget {
  const FilterApp({
    Key? key,
    this.slug,
  }) : super(key: key);

  final String? slug;

  @override
  _FilterAppState createState() => _FilterAppState();
}

class _FilterAppState extends State<FilterApp> {
  String? selectedGenre;
  String? selectedCountry;
  int? selectedYear;
  bool isFocusButton = false;
  
   List<int?> _currentIndices = [];

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
    {"name": "Tất cả quốc gia", "slug_country": ""},
    {"name": "Trung Quốc", "slug_country": "trung-quoc"},
    {"name": "Hàn Quốc", "slug_country": "han-quoc"},
    {"name": "Nhật Bản", "slug_country": "nhat-ban"},
    {"name": "Thái Lan", "slug_country": "thai-lan"},
    {"name": "Âu Mỹ", "slug_country": "au-my"},
    {"name": "Đài Loan", "slug_country": "dai-loan"},
    {"name": "Hồng Kông", "slug_country": "hong-kong"},
    {"name": "Ấn Độ", "slug_country": "an-do"},
    {"name": "Anh", "slug_country": "anh"},
    {"name": "Pháp", "slug_country": "phap"},
    {"name": "Canada", "slug_country": "canada"},
    {"name": "Quốc Nga", "slug_country": "quoc-nga"},
    {"name": "Mexico", "slug_country": "mexico"},
    {"name": "Ba lan", "slug_country": "ba-lan"},
    {"name": "Úc", "slug_country": "uc"},
    {"name": "Thụy Điển", "slug_country": "thuy-dien"},
    {"name": "Malaysia", "slug_country": "malaysia"},
    {"name": "Brazil", "slug_country": "brazil"},
    {"name": "Philippines", "slug_country": "philippines"},
    {"name": "Bồ Đào Nha", "slug_country": "bo-dao-nha"},
    {"name": "Ý", "slug_country": "y"},
    {"name": "Đan Mạch", "slug_country": "dan-mach"},
    {"name": "UAE", "slug_country": "uae"},
    {"name": "Na Uy", "slug_country": "na-uy"},
    {"name": "Thụy Sĩ", "slug_country": "thuy-si"},
    {"name": "Châu Phi", "slug_country": "chau-phi"},
    {"name": "Nam Phi", "slug_country": "nam-phi"},
    {"name": "Ukraina", "slug_country": "ukraina"},
    {"name": "Ả Rập Xê Út", "slug_country": "arap-xe-ut"},
  ];

  List<Map<String, dynamic>> yearsList = List.generate(
    DateTime.now().year - 2009,
    (index) => {"year": 2010 + index},
  );

  @override
  void initState() {
    super.initState();
    _currentIndices = List.filled(3, null);
  }

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
                side: BorderSide(color: isFocusButton?Colors.white:Colors.transparent,width: 2)
              ),
              onHover: (hasFocus)=>setState(() {
                isFocusButton=hasFocus;
              }),
              onPressed: () {
                if (widget.slug != null) {
                  Get.toNamed("/loai-phim/${widget.slug}?category=${selectedGenre??""}&country=${selectedCountry??""}&year=${selectedYear??""}");
                } else {
                  if (selectedGenre == null) {
                    Get.snackbar("Thông báo", "Vui lòng chọn thể loại phim trước",backgroundColor: Colors.white);
                  } else {
                    Get.toNamed("/the-loai/${selectedGenre??""}?country=${selectedCountry??""}&year=${selectedYear??""}");
                  }
                }
              },
              child:  Transform.scale(
                scale: isFocusButton?1.2:1,
                child: Text("Duyệt phim", style: TextStyle(color: Colors.white))),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          const ListTile(
            title: Text('Thể loại', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Expanded(
            child: buildFilterList(drawerItems, selectedGenre, (genre) {
              setState(() {
                
                selectedGenre = genre["slug"];
                
              });
              
            },
            0
            
            )
          ),
          const ListTile(
            title: Text('Quốc gia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Expanded(
            child: buildFilterList(countries, selectedCountry, (country) {
              setState(() {
                selectedCountry = country["slug_country"];
              });
            },
            1
            ),
          ),
          const ListTile(
            title: Text('Năm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Expanded(
            child: buildFilterList(yearsList, selectedYear, (year) {
              setState(() {
                selectedYear = year["year"];
              });
            },
            2
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTap(Map<String, dynamic> item) {
    setState(() {
      selectedGenre = item["slug"];
      selectedCountry = item["slug_country"];
      selectedYear = item["year"];
    });
  }

  Widget buildFilterList(List<Map<String, dynamic>> items, dynamic selectedItem, Function(Map<String, dynamic>) onTap, int index) {
    return GridView.builder(
      
      scrollDirection: Axis.horizontal,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: 6 / 20,
      ),
      itemCount: items.length,
      itemBuilder: (context, idx) {
        final item = items[idx];
        return InkWell(
          onTap: () {
            onTap(item);
            setState(() {
              _currentIndices[index] = idx;
            });
          },
          child: buildFilterItem(
            text: item["title"] ?? item["name"] ?? item["year"].toString(),
            isSelected: selectedItem != null ? (selectedItem == item["slug"] || selectedItem == item["year"] || selectedItem == item["name"]) : false,
            isFocus: _currentIndices[index] == idx,
          ),
        );
      },
    );
  }

  Widget buildFilterItem({required String text, required bool isSelected, required bool isFocus}) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff252836) : null,
          border: isFocus ? Border.all(color: GlobalColor.primary, width: 1) : null,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          text,
          textAlign: TextAlign.start,
          style: TextStyle(
            fontSize: 14,
            color: !isSelected ? Colors.white : GlobalColor.primary,
          ),
        ),
      ),
    );
  }
}