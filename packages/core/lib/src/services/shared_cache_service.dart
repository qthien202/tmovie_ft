import 'package:cloud_firestore/cloud_firestore.dart';

/// A small shared (global, not per-user) cache backed by a single Firestore
/// collection `app_cache`. Used as a middle tier between the device's local
/// Drift cache and the OPhim API so the app rarely has to call OPhim directly.
///
/// All operations are best-effort: any failure returns null / no-ops so the
/// caller can fall back to the API.
class SharedCacheService {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _fs.collection('app_cache');

  Future<Map<String, dynamic>?> read(String docId) async {
    try {
      final doc = await _col.doc(docId).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String docId, Map<String, dynamic> data) async {
    try {
      await _col.doc(docId).set(data);
    } catch (_) {
      // Best-effort; the local cache already has the data.
    }
  }
}
