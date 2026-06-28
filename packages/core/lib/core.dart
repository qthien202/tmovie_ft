// TMovie foundation: constants, models, network, repositories, auth + base providers.
// UI lives in package:design_system; feature logic in package:catalog/detail/media_library/app_update.

// Constants
export 'src/constants/api_constants.dart';
export 'src/constants/app_constants.dart';

// Models
export 'src/models/pagination.dart';
export 'src/models/category.dart';
export 'src/models/country.dart';
export 'src/models/server_data.dart';
export 'src/models/episode.dart';
export 'src/models/film_item.dart';
export 'src/models/film_detail.dart';
export 'src/models/film_list_response.dart';
export 'src/models/film_detail_response.dart';
export 'src/models/film_people_response.dart';
export 'src/models/film_images_response.dart';
export 'src/models/watch_history_entry.dart';
export 'src/models/tmdb_season_response.dart';

// Network
export 'src/network/dio_provider.dart';
export 'src/network/api_service.dart';
export 'src/network/tmdb_service.dart';
export 'src/network/trakt_service.dart';

// Services
export 'src/services/auth_service.dart';
export 'src/services/shared_cache_service.dart';
export 'package:firebase_auth/firebase_auth.dart' show User;

// Repositories
export 'src/repositories/film_repository.dart';
export 'src/repositories/film_repository_impl.dart';
export 'src/repositories/history_repository.dart';
export 'src/repositories/history_repository_impl.dart';
export 'src/repositories/favorites_repository.dart';
export 'src/repositories/local_favorites_repository.dart';
export 'src/repositories/firestore_history_repository.dart';
export 'src/repositories/firestore_favorites_repository.dart';
export 'src/repositories/hero_repository.dart';

// Foundation providers
export 'src/providers/foundation_providers.dart';
