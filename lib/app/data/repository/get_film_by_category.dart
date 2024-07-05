class GetFilmByCategory {
  GetFilmByCategory({
    PageProps? pageProps,
    bool? nssp,
  }) {
    _pageProps = pageProps;
    _nssp = nssp;
  }

  GetFilmByCategory.fromJson(dynamic json) {
    _pageProps = json['pageProps'] != null
        ? PageProps.fromJson(json['pageProps'])
        : null;
    _nssp = json['__N_SSP'];
  }
  PageProps? _pageProps;
  bool? _nssp;
  GetFilmByCategory copyWith({
    PageProps? pageProps,
    bool? nssp,
  }) =>
      GetFilmByCategory(
        pageProps: pageProps ?? _pageProps,
        nssp: nssp ?? _nssp,
      );
  PageProps? get pageProps => _pageProps;
  bool? get nssp => _nssp;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_pageProps != null) {
      map['pageProps'] = _pageProps?.toJson();
    }
    map['__N_SSP'] = _nssp;
    return map;
  }
}

class PageProps {
  PageProps({
    Data? data,
  }) {
    _data = data;
  }

  PageProps.fromJson(dynamic json) {
    _data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }
  Data? _data;
  PageProps copyWith({
    Data? data,
  }) =>
      PageProps(
        data: data ?? _data,
      );
  Data? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    return map;
  }
}

class Data {
  Data({
    SeoOnPage? seoOnPage,
    List<BreadCrumb>? breadCrumb,
    dynamic titlePage,
    List<Items>? items,
    Params? params,
    dynamic typeList,
    dynamic appdomainfrontend,
    dynamic appdomaincdnimage,
  }) {
    _seoOnPage = seoOnPage;
    _breadCrumb = breadCrumb;
    _titlePage = titlePage;
    _items = items;
    _params = params;
    _typeList = typeList;
    _appdomainfrontend = appdomainfrontend;
    _appdomaincdnimage = appdomaincdnimage;
  }

  Data.fromJson(dynamic json) {
    _seoOnPage = json['seoOnPage'] != null
        ? SeoOnPage.fromJson(json['seoOnPage'])
        : null;
    if (json['breadCrumb'] != null) {
      _breadCrumb = [];
      json['breadCrumb'].forEach((v) {
        _breadCrumb?.add(BreadCrumb.fromJson(v));
      });
    }
    _titlePage = json['titlePage'];
    if (json['items'] != null) {
      _items = [];
      json['items'].forEach((v) {
        _items?.add(Items.fromJson(v));
      });
    }
    _params = json['params'] != null ? Params.fromJson(json['params']) : null;
    _typeList = json['type_list'];
    _appdomainfrontend = json['APP_DOMAIN_FRONTEND'];
    _appdomaincdnimage = json['APP_DOMAIN_CDN_IMAGE'];
  }
  SeoOnPage? _seoOnPage;
  List<BreadCrumb>? _breadCrumb;
  dynamic _titlePage;
  List<Items>? _items;
  Params? _params;
  dynamic _typeList;
  dynamic _appdomainfrontend;
  dynamic _appdomaincdnimage;
  Data copyWith({
    SeoOnPage? seoOnPage,
    List<BreadCrumb>? breadCrumb,
    dynamic titlePage,
    List<Items>? items,
    Params? params,
    dynamic typeList,
    dynamic appdomainfrontend,
    dynamic appdomaincdnimage,
  }) =>
      Data(
        seoOnPage: seoOnPage ?? _seoOnPage,
        breadCrumb: breadCrumb ?? _breadCrumb,
        titlePage: titlePage ?? _titlePage,
        items: items ?? _items,
        params: params ?? _params,
        typeList: typeList ?? _typeList,
        appdomainfrontend: appdomainfrontend ?? _appdomainfrontend,
        appdomaincdnimage: appdomaincdnimage ?? _appdomaincdnimage,
      );
  SeoOnPage? get seoOnPage => _seoOnPage;
  List<BreadCrumb>? get breadCrumb => _breadCrumb;
  dynamic get titlePage => _titlePage;
  List<Items>? get items => _items;
  Params? get params => _params;
  dynamic get typeList => _typeList;
  dynamic get appdomainfrontend => _appdomainfrontend;
  dynamic get appdomaincdnimage => _appdomaincdnimage;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_seoOnPage != null) {
      map['seoOnPage'] = _seoOnPage?.toJson();
    }
    if (_breadCrumb != null) {
      map['breadCrumb'] = _breadCrumb?.map((v) => v.toJson()).toList();
    }
    map['titlePage'] = _titlePage;
    if (_items != null) {
      map['items'] = _items?.map((v) => v.toJson()).toList();
    }
    if (_params != null) {
      map['params'] = _params?.toJson();
    }
    map['type_list'] = _typeList;
    map['APP_DOMAIN_FRONTEND'] = _appdomainfrontend;
    map['APP_DOMAIN_CDN_IMAGE'] = _appdomaincdnimage;
    return map;
  }
}

/// type_slug : "danh-sach"
/// filterCategory : [""]
/// filterCountry : [""]
/// filterYear : ""
/// filterType : ""
/// sortField : "modified.time"
/// sortType : "desc"
/// pagination : {"totalItems":14698,"totalItemsPerPage":24,"currentPage":1,"pageRanges":5}

class Params {
  Params({
    dynamic typeSlug,
    List<String>? filterCategory,
    List<String>? filterCountry,
    dynamic filterYear,
    dynamic filterType,
    dynamic sortField,
    dynamic sortType,
    Pagination? pagination,
  }) {
    _typeSlug = typeSlug;
    _filterCategory = filterCategory;
    _filterCountry = filterCountry;
    _filterYear = filterYear;
    _filterType = filterType;
    _sortField = sortField;
    _sortType = sortType;
    _pagination = pagination;
  }

  Params.fromJson(dynamic json) {
    _typeSlug = json['type_slug'];
    _filterCategory = json['filterCategory'] != null
        ? json['filterCategory'].cast<String>()
        : [];
    _filterCountry = json['filterCountry'] != null
        ? json['filterCountry'].cast<String>()
        : [];
    _filterYear = json['filterYear'];
    _filterType = json['filterType'];
    _sortField = json['sortField'];
    _sortType = json['sortType'];
    _pagination = json['pagination'] != null
        ? Pagination.fromJson(json['pagination'])
        : null;
  }
  dynamic _typeSlug;
  List<String>? _filterCategory;
  List<String>? _filterCountry;
  dynamic _filterYear;
  dynamic _filterType;
  dynamic _sortField;
  dynamic _sortType;
  Pagination? _pagination;
  Params copyWith({
    dynamic typeSlug,
    List<String>? filterCategory,
    List<String>? filterCountry,
    dynamic filterYear,
    dynamic filterType,
    dynamic sortField,
    dynamic sortType,
    Pagination? pagination,
  }) =>
      Params(
        typeSlug: typeSlug ?? _typeSlug,
        filterCategory: filterCategory ?? _filterCategory,
        filterCountry: filterCountry ?? _filterCountry,
        filterYear: filterYear ?? _filterYear,
        filterType: filterType ?? _filterType,
        sortField: sortField ?? _sortField,
        sortType: sortType ?? _sortType,
        pagination: pagination ?? _pagination,
      );
  dynamic get typeSlug => _typeSlug;
  List<String>? get filterCategory => _filterCategory;
  List<String>? get filterCountry => _filterCountry;
  dynamic get filterYear => _filterYear;
  dynamic get filterType => _filterType;
  dynamic get sortField => _sortField;
  dynamic get sortType => _sortType;
  Pagination? get pagination => _pagination;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['type_slug'] = _typeSlug;
    map['filterCategory'] = _filterCategory;
    map['filterCountry'] = _filterCountry;
    map['filterYear'] = _filterYear;
    map['filterType'] = _filterType;
    map['sortField'] = _sortField;
    map['sortType'] = _sortType;
    if (_pagination != null) {
      map['pagination'] = _pagination?.toJson();
    }
    return map;
  }
}

/// totalItems : 14698
/// totalItemsPerPage : 24
/// currentPage : 1
/// pageRanges : 5

class Pagination {
  Pagination({
    num? totalItems,
    num? totalItemsPerPage,
    num? currentPage,
    num? pageRanges,
  }) {
    _totalItems = totalItems;
    _totalItemsPerPage = totalItemsPerPage;
    _currentPage = currentPage;
    _pageRanges = pageRanges;
  }

  Pagination.fromJson(dynamic json) {
    _totalItems = json['totalItems'];
    _totalItemsPerPage = json['totalItemsPerPage'];
    _currentPage = json['currentPage'];
    _pageRanges = json['pageRanges'];
  }
  num? _totalItems;
  num? _totalItemsPerPage;
  num? _currentPage;
  num? _pageRanges;
  Pagination copyWith({
    num? totalItems,
    num? totalItemsPerPage,
    num? currentPage,
    num? pageRanges,
  }) =>
      Pagination(
        totalItems: totalItems ?? _totalItems,
        totalItemsPerPage: totalItemsPerPage ?? _totalItemsPerPage,
        currentPage: currentPage ?? _currentPage,
        pageRanges: pageRanges ?? _pageRanges,
      );
  num? get totalItems => _totalItems;
  num? get totalItemsPerPage => _totalItemsPerPage;
  num? get currentPage => _currentPage;
  num? get pageRanges => _pageRanges;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['totalItems'] = _totalItems;
    map['totalItemsPerPage'] = _totalItemsPerPage;
    map['currentPage'] = _currentPage;
    map['pageRanges'] = _pageRanges;
    return map;
  }
}

/// modified : {"time":"2024-02-02T20:50:36.000Z"}
/// _id : "65bcf32a5540d59e3fdd8d8e"
/// name : "Traffickers: Inside The Golden Triangle"
/// slug : "traffickers-inside-the-golden-triangle"
/// origin_name : "Traffickers: Inside The Golden Triangle"
/// type : "single"
/// thumb_url : "traffickers-inside-the-golden-triangle-thumb.jpg"
/// poster_url : "traffickers-inside-the-golden-triangle-poster.jpg"
/// sub_docquyen : false
/// chieurap : false
/// time : "45 phút/tập"
/// episode_current : "Full"
/// quality : "HD"
/// lang : "Vietsub"
/// year : 2021
/// category : [{"id":"620e0e64d9648f114cde7728","name":"Tài Liệu","slug":"tai-lieu"}]
/// country : [{"id":"620a2318e0fc277084dfd77a","name":"Thái Lan","slug":"thai-lan"}]

class Items {
  Items({
    Modified? modified,
    dynamic id,
    dynamic name,
    dynamic slug,
    dynamic originName,
    dynamic type,
    dynamic thumbUrl,
    dynamic posterUrl,
    bool? subDocquyen,
    bool? chieurap,
    dynamic time,
    dynamic episodeCurrent,
    dynamic quality,
    dynamic lang,
    num? year,
    List<Category>? category,
    List<Country>? country,
  }) {
    _modified = modified;
    _id = id;
    _name = name;
    _slug = slug;
    _originName = originName;
    _type = type;
    _thumbUrl = thumbUrl;
    _posterUrl = posterUrl;
    _subDocquyen = subDocquyen;
    _chieurap = chieurap;
    _time = time;
    _episodeCurrent = episodeCurrent;
    _quality = quality;
    _lang = lang;
    _year = year;
    _category = category;
    _country = country;
  }

  Items.fromJson(dynamic json) {
    _modified =
        json['modified'] != null ? Modified.fromJson(json['modified']) : null;
    _id = json['_id'];
    _name = json['name'];
    _slug = json['slug'];
    _originName = json['origin_name'];
    _type = json['type'];
    _thumbUrl = json['thumb_url'];
    _posterUrl = json['poster_url'];
    _subDocquyen = json['sub_docquyen'];
    _chieurap = json['chieurap'];
    _time = json['time'];
    _episodeCurrent = json['episode_current'];
    _quality = json['quality'];
    _lang = json['lang'];
    _year = json['year'];
    if (json['category'] != null) {
      _category = [];
      json['category'].forEach((v) {
        _category?.add(Category.fromJson(v));
      });
    }
    if (json['country'] != null) {
      _country = [];
      json['country'].forEach((v) {
        _country?.add(Country.fromJson(v));
      });
    }
  }
  Modified? _modified;
  dynamic _id;
  dynamic _name;
  dynamic _slug;
  dynamic _originName;
  dynamic _type;
  dynamic _thumbUrl;
  dynamic _posterUrl;
  bool? _subDocquyen;
  bool? _chieurap;
  dynamic _time;
  dynamic _episodeCurrent;
  dynamic _quality;
  dynamic _lang;
  num? _year;
  List<Category>? _category;
  List<Country>? _country;
  Items copyWith({
    Modified? modified,
    dynamic id,
    dynamic name,
    dynamic slug,
    dynamic originName,
    dynamic type,
    dynamic thumbUrl,
    dynamic posterUrl,
    bool? subDocquyen,
    bool? chieurap,
    dynamic time,
    dynamic episodeCurrent,
    dynamic quality,
    dynamic lang,
    num? year,
    List<Category>? category,
    List<Country>? country,
  }) =>
      Items(
        modified: modified ?? _modified,
        id: id ?? _id,
        name: name ?? _name,
        slug: slug ?? _slug,
        originName: originName ?? _originName,
        type: type ?? _type,
        thumbUrl: thumbUrl ?? _thumbUrl,
        posterUrl: posterUrl ?? _posterUrl,
        subDocquyen: subDocquyen ?? _subDocquyen,
        chieurap: chieurap ?? _chieurap,
        time: time ?? _time,
        episodeCurrent: episodeCurrent ?? _episodeCurrent,
        quality: quality ?? _quality,
        lang: lang ?? _lang,
        year: year ?? _year,
        category: category ?? _category,
        country: country ?? _country,
      );
  Modified? get modified => _modified;
  dynamic get id => _id;
  dynamic get name => _name;
  dynamic get slug => _slug;
  dynamic get originName => _originName;
  dynamic get type => _type;
  dynamic get thumbUrl => _thumbUrl;
  dynamic get posterUrl => _posterUrl;
  bool? get subDocquyen => _subDocquyen;
  bool? get chieurap => _chieurap;
  dynamic get time => _time;
  dynamic get episodeCurrent => _episodeCurrent;
  dynamic get quality => _quality;
  dynamic get lang => _lang;
  num? get year => _year;
  List<Category>? get category => _category;
  List<Country>? get country => _country;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_modified != null) {
      map['modified'] = _modified?.toJson();
    }
    map['_id'] = _id;
    map['name'] = _name;
    map['slug'] = _slug;
    map['origin_name'] = _originName;
    map['type'] = _type;
    map['thumb_url'] = _thumbUrl;
    map['poster_url'] = _posterUrl;
    map['sub_docquyen'] = _subDocquyen;
    map['chieurap'] = _chieurap;
    map['time'] = _time;
    map['episode_current'] = _episodeCurrent;
    map['quality'] = _quality;
    map['lang'] = _lang;
    map['year'] = _year;
    if (_category != null) {
      map['category'] = _category?.map((v) => v.toJson()).toList();
    }
    if (_country != null) {
      map['country'] = _country?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

/// id : "620a2318e0fc277084dfd77a"
/// name : "Thái Lan"
/// slug : "thai-lan"

class Country {
  Country({
    dynamic id,
    dynamic name,
    dynamic slug,
  }) {
    _id = id;
    _name = name;
    _slug = slug;
  }

  Country.fromJson(dynamic json) {
    _id = json['id'];
    _name = json['name'];
    _slug = json['slug'];
  }
  dynamic _id;
  dynamic _name;
  dynamic _slug;
  Country copyWith({
    dynamic id,
    dynamic name,
    dynamic slug,
  }) =>
      Country(
        id: id ?? _id,
        name: name ?? _name,
        slug: slug ?? _slug,
      );
  dynamic get id => _id;
  dynamic get name => _name;
  dynamic get slug => _slug;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['name'] = _name;
    map['slug'] = _slug;
    return map;
  }
}

/// id : "620e0e64d9648f114cde7728"
/// name : "Tài Liệu"
/// slug : "tai-lieu"

class Category {
  Category({
    dynamic id,
    dynamic name,
    dynamic slug,
  }) {
    _id = id;
    _name = name;
    _slug = slug;
  }

  Category.fromJson(dynamic json) {
    _id = json['id'];
    _name = json['name'];
    _slug = json['slug'];
  }
  dynamic _id;
  dynamic _name;
  dynamic _slug;
  Category copyWith({
    dynamic id,
    dynamic name,
    dynamic slug,
  }) =>
      Category(
        id: id ?? _id,
        name: name ?? _name,
        slug: slug ?? _slug,
      );
  dynamic get id => _id;
  dynamic get name => _name;
  dynamic get slug => _slug;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['name'] = _name;
    map['slug'] = _slug;
    return map;
  }
}

/// time : "2024-02-02T20:50:36.000Z"

class Modified {
  Modified({
    dynamic time,
  }) {
    _time = time;
  }

  Modified.fromJson(dynamic json) {
    _time = json['time'];
  }
  dynamic _time;
  Modified copyWith({
    dynamic time,
  }) =>
      Modified(
        time: time ?? _time,
      );
  dynamic get time => _time;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['time'] = _time;
    return map;
  }
}

/// name : "Phim Lẻ"
/// slug : "/danh-sach/phim-le"
/// isCurrent : false
/// position : 2

class BreadCrumb {
  BreadCrumb({
    dynamic name,
    dynamic slug,
    bool? isCurrent,
    num? position,
  }) {
    _name = name;
    _slug = slug;
    _isCurrent = isCurrent;
    _position = position;
  }

  BreadCrumb.fromJson(dynamic json) {
    _name = json['name'];
    _slug = json['slug'];
    _isCurrent = json['isCurrent'];
    _position = json['position'];
  }
  dynamic _name;
  dynamic _slug;
  bool? _isCurrent;
  num? _position;
  BreadCrumb copyWith({
    dynamic name,
    dynamic slug,
    bool? isCurrent,
    num? position,
  }) =>
      BreadCrumb(
        name: name ?? _name,
        slug: slug ?? _slug,
        isCurrent: isCurrent ?? _isCurrent,
        position: position ?? _position,
      );
  dynamic get name => _name;
  dynamic get slug => _slug;
  bool? get isCurrent => _isCurrent;
  num? get position => _position;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = _name;
    map['slug'] = _slug;
    map['isCurrent'] = _isCurrent;
    map['position'] = _position;
    return map;
  }
}

/// og_type : "website"
/// titleHead : "Phim lẻ | Phim lẻ hay tuyển chọn | Phim lẻ mới nhất 2022"
/// descriptionHead : "Phim lẻ mới nhất tuyển chọn chất lượng cao, phim lẻ mới nhất 2022 vietsub cập nhật nhanh nhất. Phim lẻ vietsub nhanh nhất"
/// og_image : ["/uploads/movies/traffickers-inside-the-golden-triangle-thumb.jpg","/uploads/movies/phong-than-loi-chan-tu-thumb.jpg","/uploads/movies/hoa-giang-ho-bat-luong-soai-thumb.jpg","/uploads/movies/ke-nhat-cung-dien-cuong-thumb.jpg","/uploads/movies/ta-tam-muoi-anh-thumb.jpg","/uploads/movies/ket-thuc-co-dao-thumb.jpg","/uploads/movies/khe-uoc-thoi-gian-thumb.jpg","/uploads/movies/thanh-pho-thai-nguyen-khong-noi-buon-thumb.jpg","/uploads/movies/khi-minh-thanh-cau-thumb.jpg","/uploads/movies/khi-yeu-chua-du-thumb.jpg","/uploads/movies/khoa-khoi-ma-phuc-chi-cong-chua-dieu-ngoa-thumb.jpg","/uploads/movies/thanh-xuan-khong-dien-tap-thumb.jpg","/uploads/movies/khong-bao-gio-quen-tai-sao-ban-bat-dau-thumb.jpg","/uploads/movies/khong-gian-cat-giu-linh-hon-thumb.jpg","/uploads/movies/than-nam-than-nu-thumb.jpg","/uploads/movies/khong-lam-nguoi-co-tien-thumb.jpg","/uploads/movies/khong-the-cham-thumb.jpg","/uploads/movies/thien-co-mat-lenh-thumb.jpg","/uploads/movies/kien-tap-ai-than-thumb.jpg","/uploads/movies/thien-duong-da-thumb.jpg","/uploads/movies/kinh-di-thieu-nu-tam-thumb.jpg","/uploads/movies/lang-hoa-kieu-oa-chi-no-hai-than-quyen-thumb.jpg","/uploads/movies/thoi-dai-theo-duoi-uoc-mo-cua-chung-ta-thumb.jpg","/uploads/movies/mat-vu-ong-thumb.jpg"]
/// og_url : "danh-sach/phim-le"

class SeoOnPage {
  SeoOnPage({
    dynamic ogType,
    dynamic titleHead,
    dynamic descriptionHead,
    List<String>? ogImage,
    dynamic ogUrl,
  }) {
    _ogType = ogType;
    _titleHead = titleHead;
    _descriptionHead = descriptionHead;
    _ogImage = ogImage;
    _ogUrl = ogUrl;
  }

  SeoOnPage.fromJson(dynamic json) {
    _ogType = json['og_type'];
    _titleHead = json['titleHead'];
    _descriptionHead = json['descriptionHead'];
    _ogImage = json['og_image'] != null ? json['og_image'].cast<String>() : [];
    _ogUrl = json['og_url'];
  }
  dynamic _ogType;
  dynamic _titleHead;
  dynamic _descriptionHead;
  List<String>? _ogImage;
  dynamic _ogUrl;
  SeoOnPage copyWith({
    dynamic ogType,
    dynamic titleHead,
    dynamic descriptionHead,
    List<String>? ogImage,
    dynamic ogUrl,
  }) =>
      SeoOnPage(
        ogType: ogType ?? _ogType,
        titleHead: titleHead ?? _titleHead,
        descriptionHead: descriptionHead ?? _descriptionHead,
        ogImage: ogImage ?? _ogImage,
        ogUrl: ogUrl ?? _ogUrl,
      );
  dynamic get ogType => _ogType;
  dynamic get titleHead => _titleHead;
  dynamic get descriptionHead => _descriptionHead;
  List<String>? get ogImage => _ogImage;
  dynamic get ogUrl => _ogUrl;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['og_type'] = _ogType;
    map['titleHead'] = _titleHead;
    map['descriptionHead'] = _descriptionHead;
    map['og_image'] = _ogImage;
    map['og_url'] = _ogUrl;
    return map;
  }
}
