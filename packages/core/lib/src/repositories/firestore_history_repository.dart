import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/watch_history_entry.dart';
import 'history_repository.dart';

class FirestoreHistoryRepository implements HistoryRepository {
  final String uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirestoreHistoryRepository(this.uid);

  CollectionReference<Map<String, dynamic>> get _historyRef =>
      _firestore.collection('users').doc(uid).collection('history');

  @override
  Future<List<WatchHistoryEntry>> getHistory() async {
    final snapshot = await _historyRef
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();
    return snapshot.docs
        .map((doc) => WatchHistoryEntry.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<void> addHistory(WatchHistoryEntry entry) async {
    await _historyRef.doc(entry.slug).set(entry.toJson());
  }

  @override
  Future<void> savePlaybackPosition(
    String filmSlug,
    String episodeSlug,
    int positionSeconds,
  ) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('playback')
        .doc('${filmSlug}_$episodeSlug')
        .set({'position': positionSeconds});
  }

  @override
  Future<int?> getPlaybackPosition(String filmSlug, String episodeSlug) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('playback')
        .doc('${filmSlug}_$episodeSlug')
        .get();
    return doc.data()?['position'] as int?;
  }

  @override
  Future<void> clearHistory() async {
    final snapshot = await _historyRef.get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
