import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '/data/models/workout_models.dart';

class WorkoutRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  WorkoutRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  String? _cachedBasePath;

  Future<String> get _userBaseCollection async {
    if (_cachedBasePath != null) return _cachedBasePath!;

    final uid = _userId;
    if (uid.isEmpty) {
      throw Exception('Not authenticated');
    }

    Future<String?> readRoleFromIndex() async {
      try {
        final indexDoc = await _firestore
            .collection('users-index')
            .doc(uid)
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(const Duration(seconds: 2));
        final role = indexDoc.data()?['role'] as String?;
        if (role == 'admin') return 'users-admin/$uid';
        if (role == 'consumer') return 'users-consumer/$uid';
        return null;
      } catch (_) {
        return null;
      }
    }

    Future<bool> existsAt(String collection) async {
      try {
        final doc = await _firestore
            .collection(collection)
            .doc(uid)
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(const Duration(seconds: 2));
        return doc.exists;
      } catch (_) {
        return false;
      }
    }

    // Run all probes in parallel and decide
    final results = await Future.wait<FutureOr<dynamic>>([
      readRoleFromIndex(),
      existsAt('users-admin'),
      existsAt('users-consumer'),
    ]);

    final fromIndex = results[0] as String?;
    final adminExists = results[1] as bool;
    final consumerExists = results[2] as bool;

    if (fromIndex != null) return _cachedBasePath = fromIndex;
    if (adminExists) return _cachedBasePath = 'users-admin/$uid';
    if (consumerExists) return _cachedBasePath = 'users-consumer/$uid';

    // Default to consumer if unknown
    return _cachedBasePath = 'users-consumer/$uid';
  }

  Future<CollectionReference<Map<String, dynamic>>> _plansRef() async {
    final base = await _userBaseCollection;
    return _firestore.collection('$base/workout_plans');
  }

  Future<CollectionReference<Map<String, dynamic>>> _exerciseNamesRef() async {
    final base = await _userBaseCollection;
    return _firestore.collection('$base/exercise_names');
  }

  Future<CollectionReference<Map<String, dynamic>>> _workoutSessionsRef() async {
    final base = await _userBaseCollection;
    return _firestore.collection('$base/workout_sessions');
  }

  // Streams use resolved base path and attach directly to Firestore snapshots

  // Exercise names
  Stream<List<ExerciseNameModel>> exerciseNamesStream() {
    return Stream.fromFuture(_userBaseCollection).asyncExpand((base) {
      final ref = _firestore.collection('$base/exercise_names');
      return ref
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => ExerciseNameModel.fromJson(d.data(), d.id))
              .toList());
    });
  }

  Future<void> addExerciseName(String name) async {
    final ref = await _exerciseNamesRef();
    final cleaned = name.trim();
    if (cleaned.isEmpty) return;
    // upsert by name
    final query = await ref.where('name', isEqualTo: cleaned).limit(1).get();
    if (query.docs.isEmpty) {
      await ref.add({'name': cleaned, 'createdAt': FieldValue.serverTimestamp()});
    }
  }

  // Plans
  Stream<List<WorkoutPlanModel>> plansStream() {
    return Stream.fromFuture(_userBaseCollection).asyncExpand((base) {
      final ref = _firestore.collection('$base/workout_plans');
      return ref
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => WorkoutPlanModel.fromJson(d.data(), d.id))
              .toList());
    });
  }

  Future<void> addPlan(WorkoutPlanModel plan) async {
    final ref = await _plansRef();
    await ref.doc(plan.id).set(plan.toJson());
    // Also record exercise names
    for (final ex in plan.exercises) {
      await addExerciseName(ex.name);
    }
  }

  Future<void> updatePlan(WorkoutPlanModel plan) async {
    final ref = await _plansRef();
    await ref.doc(plan.id).update(plan.toJson());
    for (final ex in plan.exercises) {
      await addExerciseName(ex.name);
    }
  }

  Future<void> deletePlan(String planId) async {
    final ref = await _plansRef();
    await ref.doc(planId).delete();
  }

  // Workout Sessions
  Stream<List<WorkoutSessionModel>> workoutSessionsStream() {
    return Stream.fromFuture(_userBaseCollection).asyncExpand((base) {
      final ref = _firestore.collection('$base/workout_sessions');
      return ref
          .orderBy('startedAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => WorkoutSessionModel.fromJson(d.data(), d.id))
              .toList());
    });
  }

  Future<void> addWorkoutSession(WorkoutSessionModel session) async {
    final ref = await _workoutSessionsRef();
    await ref.doc(session.id).set(session.toJson());
  }

  Future<void> updateWorkoutSession(WorkoutSessionModel session) async {
    final ref = await _workoutSessionsRef();
    await ref.doc(session.id).update(session.toJson());
  }

  Future<void> deleteWorkoutSession(String sessionId) async {
    final ref = await _workoutSessionsRef();
    await ref.doc(sessionId).delete();
  }

  // Workout Schedule
  Stream<WorkoutScheduleModel> workoutScheduleStream() {
    return Stream.fromFuture(_userBaseCollection).asyncExpand((base) {
      final ref = _firestore.collection('$base/workout_schedule');
      return ref.doc('current').snapshots().map((snap) {
        if (snap.exists && snap.data() != null) {
          return WorkoutScheduleModel.fromJson(snap.data()!, snap.id);
        } else {
          // Return empty schedule if none exists
          return WorkoutScheduleModel(
            id: 'current',
            scheduledWorkouts: const [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
      });
    });
  }

  Future<void> addScheduledWorkout(ScheduledWorkoutModel scheduledWorkout) async {
    final base = await _userBaseCollection;
    final ref = _firestore.collection('$base/workout_schedule');
    final scheduleDoc = ref.doc('current');
    
    final scheduleSnap = await scheduleDoc.get();
    List<ScheduledWorkoutModel> currentWorkouts = const [];
    
    if (scheduleSnap.exists && scheduleSnap.data() != null) {
      final currentSchedule = WorkoutScheduleModel.fromJson(scheduleSnap.data()!, 'current');
      currentWorkouts = currentSchedule.scheduledWorkouts;
    }
    
    // Add the new scheduled workout
    final updatedWorkouts = [...currentWorkouts, scheduledWorkout];
    
    final updatedSchedule = WorkoutScheduleModel(
      id: 'current',
      scheduledWorkouts: updatedWorkouts,
      createdAt: scheduleSnap.exists ? 
          WorkoutScheduleModel.fromJson(scheduleSnap.data()!, 'current').createdAt : 
          DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await scheduleDoc.set(updatedSchedule.toJson());
  }

  Future<void> removeScheduledWorkout(String scheduledWorkoutId) async {
    final base = await _userBaseCollection;
    final ref = _firestore.collection('$base/workout_schedule');
    final scheduleDoc = ref.doc('current');
    
    final scheduleSnap = await scheduleDoc.get();
    if (!scheduleSnap.exists || scheduleSnap.data() == null) return;
    
    final currentSchedule = WorkoutScheduleModel.fromJson(scheduleSnap.data()!, 'current');
    final updatedWorkouts = currentSchedule.scheduledWorkouts
        .where((w) => w.id != scheduledWorkoutId)
        .toList();
    
    final updatedSchedule = currentSchedule.copyWith(
      scheduledWorkouts: updatedWorkouts,
      updatedAt: DateTime.now(),
    );
    
    await scheduleDoc.set(updatedSchedule.toJson());
  }

  Future<void> updateScheduledWorkout(ScheduledWorkoutModel scheduledWorkout) async {
    final base = await _userBaseCollection;
    final ref = _firestore.collection('$base/workout_schedule');
    final scheduleDoc = ref.doc('current');
    
    final scheduleSnap = await scheduleDoc.get();
    if (!scheduleSnap.exists || scheduleSnap.data() == null) return;
    
    final currentSchedule = WorkoutScheduleModel.fromJson(scheduleSnap.data()!, 'current');
    final updatedWorkouts = currentSchedule.scheduledWorkouts
        .map((w) => w.id == scheduledWorkout.id ? scheduledWorkout : w)
        .toList();
    
    final updatedSchedule = currentSchedule.copyWith(
      scheduledWorkouts: updatedWorkouts,
      updatedAt: DateTime.now(),
    );
    
    await scheduleDoc.set(updatedSchedule.toJson());
  }
}


