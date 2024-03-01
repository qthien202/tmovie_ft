import 'package:app_ft_movies/app/controller/home/home_controller.dart';
import 'package:app_ft_movies/app/controller/list_movie/list_movie_controller.dart';
import 'package:get/get.dart';

class FilterController extends GetxController{
  List<Map<String, dynamic>> genres = [
    {"title": "Thể loại", "slug": ""},
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

  RxList<Map<String, dynamic>> genreList = RxList<Map<String, dynamic>>.from([]);

  List<Map<String, dynamic>> countries = [
    {"name": "Quốc gia", "slug_country": ""},
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

  RxList<Map<String, dynamic>> countryList = RxList<Map<String, dynamic>>.from([]);


  List<Map<String, dynamic>> years = List.generate(
    DateTime.now().year - 2009,
    (index) => {"year": 2010 + index},
  );

  RxList<Map<String, dynamic>> yearList = RxList<Map<String, dynamic>>.from([]);

  Rxn<String>selectedGenre = Rxn();
  Rxn<String>selectedCountry = Rxn();
  Rxn<String>selectedYear = Rxn();
  Rxn<bool>onFilter = Rxn(false);

  @override
  void onReady() {
    // TODO: implement onReady
    super.onReady();
    genreList.addAll(genres);
    countryList.addAll(countries);
    yearList.addAll(years);
  }

  
  void onStop(){
    
    onFilter.value = false;
    selectedGenre.value = null;
    selectedCountry.value = null;
    selectedYear.value = null;
  }

  Future<void>getFilmFilter({int? page})async{
    onFilter.value = true;
    final listMovie = Get.put(ListMovieController());
    final home = Get.put(HomeController());
    await listMovie.getListMovie(path: home.pathFilm.value,category: selectedGenre.value??"",country: selectedCountry.value??"",year: selectedYear.value??"",page: page);
  }
  
}