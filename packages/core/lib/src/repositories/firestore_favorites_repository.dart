import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/watch_history_entry.dart';
import 'favorites_repository.dart';

class FirestoreFavoritesRepository implements FavoritesRepository {
  final String uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirestoreFavoritesRepository(this.uid);

  CollectionReference<Map<String, dynamic>> get _favoritesRef =>
      _firestore.collection('users').doc(uid).collection('favorites');

  @override
  Future<List<WatchHistoryEntry>> getFavorites() async {
    final snapshot = await _favoritesRef
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => WatchHistoryEntry.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<void> addFavorite(WatchHistoryEntry entry) async {
    await _favoritesRef.doc(entry.slug).set(entry.toJson());
  }

  @override
  Future<void> removeFavorite(String slug) async {
    await _favoritesRef.doc(slug).delete();
  }

  @override
  Future<bool> isFavorite(String slug) async {
    final doc = await _favoritesRef.doc(slug).get();
    return doc.exists;
  }

  @override
  Future<void> clearFavorites() async {
    final snapshot = await _favoritesRef.get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
