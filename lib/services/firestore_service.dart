import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';
import '../models/class_group.dart';

import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ─── User ─────────────────────────────────────────────────────────────────

  Future<void> createOrUpdateUser(User user) async {
    await _db.collection('users').doc(user.uid).set({
      'name': user.displayName,
      'email': user.email,
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  /// Adds a classId to the user's classIds array (supports multiple classes).
  Future<void> addUserClassId(String uid, String classId) async {
    await _db.collection('users').doc(uid).update({
      'classIds': FieldValue.arrayUnion([classId]),
    });
  }

  /// Returns all ClassGroups the user belongs to.
  /// Handles backward-compatibility: migrates old single `classId` field → `classIds` array.
  Future<List<ClassGroup>> getUserClasses(String uid) async {
    final userData = await getUser(uid);
    final List<String> ids = [];

    final rawIds = userData?['classIds'];
    if (rawIds != null) {
      ids.addAll(List<String>.from(rawIds as List));
    } else {
      // Migrate legacy single classId → classIds array
      final legacyId = userData?['classId'] as String?;
      if (legacyId != null && legacyId.isNotEmpty) {
        ids.add(legacyId);
        await _db.collection('users').doc(uid).update({
          'classIds': ids,
          'classId': FieldValue.delete(),
        });
      }
    }

    if (ids.isEmpty) return [];
    final futures = ids.map((id) => getClass(id));
    final groups = await Future.wait(futures);
    return groups.whereType<ClassGroup>().toList();
  }

  /// Removes the user from a class group and their classIds list.
  Future<void> leaveClass(String uid, String classId) async {
    await _db.collection('users').doc(uid).update({
      'classIds': FieldValue.arrayRemove([classId]),
    });
    // Remove uid from the class members list
    final classDoc = await _db.collection('classes').doc(classId).get();
    if (classDoc.exists) {
      final members = List<String>.from(classDoc['members'] as List);
      members.remove(uid);
      await classDoc.reference.update({'members': members});
    }
  }

  // ─── Class Group ──────────────────────────────────────────────────────────

  Future<ClassGroup> createClass(String name, String adminUID) async {
    final code = _generateClassCode();
    final docRef = await _db.collection('classes').add({
      'name': name,
      'classCode': code,
      'adminUID': adminUID,
      'members': [adminUID],
    });
    await addUserClassId(adminUID, docRef.id);
    return ClassGroup(
      id: docRef.id,
      name: name,
      classCode: code,
      adminUID: adminUID,
      members: [adminUID],
    );
  }

  Future<ClassGroup?> joinClassByCode(String code, String uid) async {
    final query = await _db
        .collection('classes')
        .where('classCode', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    final members = List<String>.from(doc['members'] as List);
    if (!members.contains(uid)) {
      members.add(uid);
      await doc.reference.update({'members': members});
    }
    await addUserClassId(uid, doc.id);

    return ClassGroup.fromFirestore(doc.data(), doc.id);
  }

  Future<ClassGroup?> getClass(String classId) async {
    final doc = await _db.collection('classes').doc(classId).get();
    if (!doc.exists) return null;
    return ClassGroup.fromFirestore(doc.data()!, doc.id);
  }

  // ─── Class Events ─────────────────────────────────────────────────────────

  Stream<List<Event>> classEventsStream(String classId) {
    return _db
        .collection('classes')
        .doc(classId)
        .collection('events')
        .orderBy('date')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Event.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<void> addClassEvent(String classId, Event event) async {
    await _db
        .collection('classes')
        .doc(classId)
        .collection('events')
        .add(event.toFirestore());
  }

  Future<void> deleteClassEvent(String classId, String eventId) async {
    await _db
        .collection('classes')
        .doc(classId)
        .collection('events')
        .doc(eventId)
        .delete();
  }

  // ─── Personal Events ──────────────────────────────────────────────────────

  Stream<List<Event>> personalEventsStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('personalEvents')
        .orderBy('date')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Event.fromFirestore(doc.data(), doc.id)
                .copyWith(isPersonal: true))
            .toList());
  }

  Future<void> addPersonalEvent(String userId, Event event) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('personalEvents')
        .add({
      'title': event.title,
      'category': event.category,
      'date': event.date,
      'createdAt': event.createdAt,
    });
  }

  Future<void> deletePersonalEvent(String userId, String eventId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('personalEvents')
        .doc(eventId)
        .delete();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _generateClassCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final id = _uuid.v4().replaceAll('-', '').toUpperCase();
    return id.substring(0, 6).split('').map((c) {
      final i = c.codeUnitAt(0) % chars.length;
      return chars[i];
    }).join();
  }
}
