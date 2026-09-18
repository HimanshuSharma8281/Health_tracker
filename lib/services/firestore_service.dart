import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../models/health_reading.dart';
import '../models/daily_score.dart';

/// All Firestore read/write operations for Aurora Wellness.
///
/// Collections:
///   users/{uid}                      ← user profile
///   users/{uid}/healthReadings       ← individual metric readings
///   users/{uid}/dailyScores          ← daily deterministic health scores
///   challenges/{cid}                 ← unchanged (managed by SocialService)
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── Collection helpers ────────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _readings(String uid) =>
      _userDoc(uid).collection('healthReadings');

  CollectionReference<Map<String, dynamic>> _scores(String uid) =>
      _userDoc(uid).collection('dailyScores');

  // ════════════════════════════════════════════════════════════════════════
  // USER PROFILE
  // ════════════════════════════════════════════════════════════════════════

  /// Load the user's Firestore profile. Returns null if not yet created.
  Future<UserProfile?> loadProfile(String uid) async {
    try {
      final snap = await _userDoc(uid).get();
      if (!snap.exists || snap.data() == null) return null;
      return UserProfile.fromFirestore(snap.data()!);
    } on FirebaseException catch (e) {
      debugPrint('🔴 [Firestore] loadProfile ERROR: code=${e.code} msg=${e.message}');
      return null;
    }
  }

  /// Create or merge the user's profile. Uses merge=true so existing fields
  /// (e.g. demographics) are not overwritten by a partial update.
  Future<void> saveProfile(UserProfile profile) async {
    try {
      await _userDoc(profile.uid).set(
        {
          ...profile.toFirestore(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      debugPrint('✅ [Firestore] saveProfile: uid=${profile.uid}');
    } on FirebaseException catch (e) {
      debugPrint('🔴 [Firestore] saveProfile ERROR: code=${e.code} msg=${e.message}');
    }
  }

  /// Create a profile document only if it does not already exist.
  /// Used on first sign-in to avoid overwriting existing demographics.
  Future<UserProfile> createProfileIfAbsent({
    required String uid,
    required String name,
    required String email,
    String avatarUrl = '',
  }) async {
    final existing = await loadProfile(uid);
    if (existing != null) {
      debugPrint('✅ [Firestore] createProfileIfAbsent: profile exists for uid=$uid');
      return existing;
    }

    final profile = UserProfile.fromFirebaseAuth(
      uid: uid,
      name: name,
      email: email,
      avatarUrl: avatarUrl,
    );
    await saveProfile(profile);
    debugPrint('✅ [Firestore] createProfileIfAbsent: created new profile for uid=$uid');
    return profile;
  }

  /// Update only the demographic / goal fields of an existing profile.
  Future<void> updateProfileFields(String uid, Map<String, dynamic> fields) async {
    try {
      await _userDoc(uid).update({
        ...fields,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ [Firestore] updateProfileFields: uid=$uid fields=${fields.keys.join(",")}');
    } on FirebaseException catch (e) {
      debugPrint('🔴 [Firestore] updateProfileFields ERROR: code=${e.code}');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // HEALTH READINGS
  // ════════════════════════════════════════════════════════════════════════

  /// Generate a unique Firestore document ID client-side.
  String newReadingId(String uid) {
    try {
      return _readings(uid).doc().id;
    } catch (_) {
      return '${DateTime.now().millisecondsSinceEpoch}_${uid.hashCode.abs()}';
    }
  }

  /// Write a new health reading. Returns the Firestore document ID.
  Future<String?> addReading(HealthReading reading) async {
    try {
      final docId = reading.id.isNotEmpty ? reading.id : _readings(reading.userId).doc().id;
      final docRef = _readings(reading.userId).doc(docId);
      await docRef.set(reading.toFirestore());
      debugPrint('✅ [Firestore] addReading: id=$docId metric=${reading.metric} value=${reading.value} date=${reading.date}');
      return docId;
    } on FirebaseException catch (e) {
      debugPrint('🔴 [Firestore] addReading ERROR: code=${e.code} metric=${reading.metric}');
      return null;
    }
  }

  /// Update an existing health reading's value (e.g., accumulate same-day water).
  Future<void> updateReading(String uid, String readingId, Map<String, dynamic> fields) async {
    try {
      await _readings(uid).doc(readingId).update(fields);
    } on FirebaseException catch (e) {
      debugPrint('🔴 [Firestore] updateReading ERROR: code=${e.code}');
    }
  }

  /// Set or merge a reading with a specific document ID.
  Future<void> setReading(HealthReading reading, {String? docId}) async {
    try {
      final id = docId ?? (reading.id.isNotEmpty ? reading.id : null);
      if (id != null) {
        await _readings(reading.userId)
            .doc(id)
            .set(reading.toFirestore(), SetOptions(merge: true));
      } else {
        await _readings(reading.userId).add(reading.toFirestore());
      }
      debugPrint('✅ [Firestore] setReading: metric=${reading.metric} value=${reading.value}');
    } on FirebaseException catch (e) {
      debugPrint('🔴 [Firestore] setReading ERROR: code=${e.code}');
    }
  }

  /// Delete a reading by document ID.
  Future<void> deleteReading(String uid, String readingId) async {
    if (readingId.isEmpty) return;
    try {
      await _readings(uid).doc(readingId).delete();
      debugPrint('✅ [Firestore] deleteReading: uid=$uid id=$readingId');
    } on FirebaseException catch (e) {
      debugPrint('🔴 [Firestore] deleteReading ERROR: code=${e.code} id=$readingId');
    }
  }

  /// Fallback: delete reading matching metric and timestamp/value if docId was not stored
  Future<void> deleteMatchingReading({
    required String uid,
    required String metric,
    required DateTime timestamp,
    required double value,
  }) async {
    try {
      final snap = await _readings(uid)
          .where('metric', isEqualTo: metric)
          .where('value', isEqualTo: value)
          .get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final ts = (data['timestamp'] as Timestamp?)?.toDate();
        if (ts != null && ts.difference(timestamp).inSeconds.abs() <= 120) {
          await doc.reference.delete();
          debugPrint('✅ [Firestore] deleteMatchingReading: deleted docId=${doc.id} metric=$metric');
          break;
        }
      }
    } on FirebaseException catch (e) {
      debugPrint('🔴 [Firestore] deleteMatchingReading ERROR: code=${e.code}');
    }
  }

  /// Load ALL health readings for a user across all metrics.
  /// Does not require composite index; sorts by timestamp in-memory.
  Future<List<HealthReading>> getAllReadings(String uid) async {
    try {
      final snap = await _readings(uid).get();
      final list = snap.docs
          .map((d) => HealthReading.fromFirestore(d.id, d.data()))
          .toList();
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      debugPrint('✅ [Firestore] getAllReadings: loaded ${list.length} readings for uid=$uid');
      return list;
    } on FirebaseException catch (e) {
      debugPrint('🔴 [Firestore] getAllReadings ERROR: code=${e.code} msg=${e.message}');
      return [];
    }
  }

  /// Load all readings for a given metric on a specific date (YYYY-MM-DD).
  Future<List<HealthReading>> getReadingsForDate({
    required String uid,
    required String metric,
    required String date,
  }) async {
    try {
      final snap = await _readings(uid)
          .where('metric', isEqualTo: metric)
          .where('date', isEqualTo: date)
          .get();
      final list = snap.docs
          .map((d) => HealthReading.fromFirestore(d.id, d.data()))
          .toList();
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return list;
    } on FirebaseException catch (e) {
      debugPrint('🔴 [Firestore] getReadingsForDate ERROR: code=${e.code}');
      return [];
    }
  }

  /// Load the last N days of readings for a given metric.
  Future<List<HealthReading>> getRecentReadings({
    required String uid,
    required String metric,
    int days = 30,
  }) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: days));
      final snap = await _readings(uid)
          .where('metric', isEqualTo: metric)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
          .get();
      final list = snap.docs
          .map((d) => HealthReading.fromFirestore(d.id, d.data()))
          .toList();
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return list;
    } on FirebaseException catch (e) {
      debugPrint('🔴 [Firestore] getRecentReadings ERROR: code=${e.code}');
      return [];
    }
  }

  /// Load ALL readings within an inclusive date range across all metrics.
  Future<List<HealthReading>> getReadingsForDateRange({
    required String uid,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startOfDay = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);
    try {
      final snap = await _readings(uid)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();
      final list = snap.docs
          .map((d) => HealthReading.fromFirestore(d.id, d.data()))
          .toList();
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      debugPrint('✅ [Firestore] getReadingsForDateRange: loaded ${list.length} readings for uid=$uid between ${HealthReading.formatDate(startOfDay)} and ${HealthReading.formatDate(endOfDay)}');
      return list;
    } on FirebaseException catch (e) {
      debugPrint('⚠️ [Firestore] getReadingsForDateRange fallback to in-memory filter: code=${e.code}');
      final all = await getAllReadings(uid);
      return all
          .where((r) => !r.timestamp.isBefore(startOfDay) && !r.timestamp.isAfter(endOfDay))
          .toList();
    }
  }

  /// Load ALL readings for today across all metrics (for scoring and display).
  Future<Map<String, List<HealthReading>>> getTodayReadings(String uid) async {
    try {
      final today = HealthReading.todayDate();
      final snap = await _readings(uid)
          .where('date', isEqualTo: today)
          .get();
      final list = snap.docs
          .map((d) => HealthReading.fromFirestore(d.id, d.data()))
          .toList();
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final result = <String, List<HealthReading>>{};
      for (final r in list) {
        result.putIfAbsent(r.metric, () => []).add(r);
      }
      return result;
    } on FirebaseException catch (e) {
      debugPrint('🔴 [Firestore] getTodayReadings ERROR: code=${e.code}');
      return {};
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // DAILY SCORES
  // ════════════════════════════════════════════════════════════════════════

  /// Save or overwrite today's daily score.
  Future<void> saveDailyScore(String uid, DailyScore score) async {
    try {
      await _scores(uid).doc(score.date).set(score.toFirestore());
      debugPrint('✅ [Firestore] saveDailyScore: date=${score.date} overall=${score.overall}');
    } on FirebaseException catch (e) {
      debugPrint('🔴 [Firestore] saveDailyScore ERROR: code=${e.code}');
    }
  }

  /// Load daily score for a specific date (defaults to today). Returns null if not found.
  Future<DailyScore?> getScoreForDate(String uid, [String? date]) async {
    try {
      final targetDate = date ?? HealthReading.todayDate();
      final snap = await _scores(uid).doc(targetDate).get();
      if (!snap.exists || snap.data() == null) return null;
      return DailyScore.fromFirestore(snap.data()!);
    } on FirebaseException catch (e) {
      debugPrint('🔴 [Firestore] getScoreForDate ERROR: code=${e.code}');
      return null;
    }
  }

  /// Convenience alias for today's score.
  Future<DailyScore?> getTodayScore(String uid) => getScoreForDate(uid);

  /// Load daily scores for the last N days (for trend analysis).
  Future<List<DailyScore>> getRecentScores(String uid, {int days = 7}) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: days));
      final cutoffDate =
          '${cutoff.year}-${cutoff.month.toString().padLeft(2, '0')}-${cutoff.day.toString().padLeft(2, '0')}';
      final snap = await _scores(uid)
          .where('date', isGreaterThanOrEqualTo: cutoffDate)
          .orderBy('date', descending: false)
          .get();
      return snap.docs
          .map((d) => DailyScore.fromFirestore(d.data()))
          .toList();
    } on FirebaseException catch (e) {
      debugPrint('🔴 [Firestore] getRecentScores ERROR: code=${e.code}');
      return [];
    }
  }

  /// Load daily scores within an inclusive date range (startDate to endDate).
  Future<List<DailyScore>> getScoresForDateRange({
    required String uid,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startStr = HealthReading.formatDate(startDate);
    final endStr = HealthReading.formatDate(endDate);
    try {
      final snap = await _scores(uid)
          .where('date', isGreaterThanOrEqualTo: startStr)
          .where('date', isLessThanOrEqualTo: endStr)
          .orderBy('date', descending: false)
          .get();
      return snap.docs
          .map((d) => DailyScore.fromFirestore(d.data()))
          .toList();
    } on FirebaseException catch (e) {
      debugPrint('🔴 [Firestore] getScoresForDateRange ERROR: code=${e.code}');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // MIGRATION HELPERS
  // ════════════════════════════════════════════════════════════════════════

  /// Batch-write a list of readings at once (used during SharedPreferences migration).
  Future<void> batchWriteReadings(List<HealthReading> readings) async {
    if (readings.isEmpty) return;
    try {
      // Firestore batch limit is 500 operations.
      const batchSize = 400;
      for (int i = 0; i < readings.length; i += batchSize) {
        final batch = _db.batch();
        final slice = readings.sublist(
            i, (i + batchSize).clamp(0, readings.length));
        for (final r in slice) {
          final ref = _readings(r.userId).doc();
          batch.set(ref, r.toFirestore());
        }
        await batch.commit();
      }
      debugPrint('✅ [Firestore] batchWriteReadings: wrote ${readings.length} readings');
    } on FirebaseException catch (e) {
      debugPrint('🔴 [Firestore] batchWriteReadings ERROR: code=${e.code}');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // ACCOUNT PERMANENT DELETION
  // ════════════════════════════════════════════════════════════════════════

  /// Permanently deletes all user records from Firestore forever:
  /// 1. All documents in users/{uid}/healthReadings
  /// 2. All documents in users/{uid}/dailyScores
  /// 3. The user profile document itself users/{uid}
  /// 4. Removes user from active challenge participant lists
  Future<void> deleteUserDataPermanently(String uid) async {
    if (uid.isEmpty) return;
    try {
      debugPrint('🗑️ [Firestore] Initiating permanent deletion of all data for uid=$uid');

      // 1. Delete all health readings
      final readingsSnap = await _readings(uid).get();
      if (readingsSnap.docs.isNotEmpty) {
        const batchLimit = 400;
        for (int i = 0; i < readingsSnap.docs.length; i += batchLimit) {
          final batch = _db.batch();
          final chunk = readingsSnap.docs.sublist(
            i,
            (i + batchLimit).clamp(0, readingsSnap.docs.length),
          );
          for (final doc in chunk) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
        debugPrint('🗑️ [Firestore] Deleted ${readingsSnap.docs.length} health readings for uid=$uid');
      }

      // 2. Delete all daily scores
      final scoresSnap = await _scores(uid).get();
      if (scoresSnap.docs.isNotEmpty) {
        final batch = _db.batch();
        for (final doc in scoresSnap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        debugPrint('🗑️ [Firestore] Deleted ${scoresSnap.docs.length} daily scores for uid=$uid');
      }

      // 3. Delete user's profile document
      await _userDoc(uid).delete();
      debugPrint('🗑️ [Firestore] Deleted user profile document for uid=$uid');

      // 4. Clean up any challenge participations
      try {
        final challengeSnap = await _db
            .collection('challenges')
            .where('participants', arrayContains: uid)
            .get();
        if (challengeSnap.docs.isNotEmpty) {
          final batch = _db.batch();
          for (final doc in challengeSnap.docs) {
            batch.update(doc.reference, {
              'participants': FieldValue.arrayRemove([uid]),
              'participantNames.$uid': FieldValue.delete(),
              'progress.$uid': FieldValue.delete(),
              'dailyProgress.$uid': FieldValue.delete(),
              'joinedAt.$uid': FieldValue.delete(),
              'lastUpdated.$uid': FieldValue.delete(),
            });
          }
          await batch.commit();
          debugPrint('🗑️ [Firestore] Removed uid=$uid from ${challengeSnap.docs.length} challenges');
        }
      } catch (e) {
        debugPrint('⚠️ [Firestore] Challenge cleanup note for uid=$uid: $e');
      }

      debugPrint('✅ [Firestore] All Firestore data permanently erased for uid=$uid');
    } on FirebaseException catch (e) {
      debugPrint('🔴 [Firestore] deleteUserDataPermanently ERROR: code=${e.code} msg=${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('🔴 [Firestore] deleteUserDataPermanently unexpected ERROR: $e');
      rethrow;
    }
  }
}
