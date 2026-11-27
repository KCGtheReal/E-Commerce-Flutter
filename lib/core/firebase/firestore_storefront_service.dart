import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Initializes FlutterFire once safely for Web, Android, and iOS.
///
/// Initialization errors never block the primary Laravel REST storefront
/// fallback so offline/local API mode stays resilient.
Future<bool> initializeResetFirebase() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    return true;
  } catch (error) {
    debugPrint('Firebase initialization skipped: $error');
    return false;
  }
}

/// Read-only Cloud Firestore storefront client for `reset-store-ecommerce`.
///
/// Mirrors the public storefront rules in `Website Project/firestore.rules`:
/// - `categories`: public read
/// - `products`: must filter `.where('is_published', isEqualTo: true)`
/// - `settings`: public allowlisted store settings only
/// - `reviews`: must filter `.where('is_approved', isEqualTo: true)`
/// - All client writes, `discounts`, `orders`, and `payments` remain
///   exclusively on Laravel `/api/v1/*` and `/admin`.
class FirestoreStorefrontService {
  FirestoreStorefrontService({FirebaseFirestore? firestore})
      : _overrideFirestore = firestore;

  final FirebaseFirestore? _overrideFirestore;

  bool get isAvailable =>
      _overrideFirestore != null || Firebase.apps.isNotEmpty;

  FirebaseFirestore? get _db {
    if (_overrideFirestore != null) {
      return _overrideFirestore;
    }
    if (Firebase.apps.isEmpty) {
      return null;
    }
    return FirebaseFirestore.instance;
  }

  /// Watches real-time public storefront settings (`exchange_rate`, banners, etc.).
  Stream<Map<String, dynamic>> watchPublicSettings() {
    final db = _db;
    if (db == null) {
      return const Stream<Map<String, dynamic>>.empty();
    }
    return db.collection('settings').snapshots().map((snapshot) {
      final result = <String, dynamic>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        result[doc.id] = data['value'];
      }
      return result;
    });
  }

  /// Watches published products synced by Laravel (`is_published == true`).
  Stream<List<Map<String, dynamic>>> watchPublishedProducts() {
    final db = _db;
    if (db == null) {
      return const Stream<List<Map<String, dynamic>>>.empty();
    }
    return db
        .collection('products')
        .where('is_published', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Watches approved product reviews (`is_approved == true`).
  Stream<List<Map<String, dynamic>>> watchApprovedReviews(int productId) {
    final db = _db;
    if (db == null) {
      return const Stream<List<Map<String, dynamic>>>.empty();
    }
    return db
        .collection('reviews')
        .where('is_approved', isEqualTo: true)
        .where('product_id', isEqualTo: productId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Reads all active categories sorted cleanly in memory to avoid composite index dependencies.
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final db = _db;
    if (db == null) {
      return const <Map<String, dynamic>>[];
    }
    final snapshot = await db.collection('categories').get();
    final rows = snapshot.docs.map((doc) => doc.data()).toList();
    rows.sort(
      (a, b) =>
          ((a['sort_order'] as num?) ?? 0).compareTo((b['sort_order'] as num?) ?? 0),
    );
    return rows;
  }
}
