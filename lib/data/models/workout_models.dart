import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseNameModel {
  final String id;
  final String name;
  final DateTime createdAt;

  const ExerciseNameModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory ExerciseNameModel.fromJson(Map<String, dynamic> json, String id) {
    return ExerciseNameModel(
      id: id,
      name: json['name'] as String,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class PlanExerciseModel {
  final String id;
  final String name;
  final bool isDurationBased;
  final int? sets;
  final int? reps;
  final int? durationMinutes;

  const PlanExerciseModel({
    required this.id,
    required this.name,
    required this.isDurationBased,
    this.sets,
    this.reps,
    this.durationMinutes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isDurationBased': isDurationBased,
        'sets': sets,
        'reps': reps,
        'durationMinutes': durationMinutes,
      };

  factory PlanExerciseModel.fromJson(Map<String, dynamic> json) {
    return PlanExerciseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      isDurationBased: json['isDurationBased'] as bool? ?? false,
      sets: (json['sets'] as num?)?.toInt(),
      reps: (json['reps'] as num?)?.toInt(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
    );
  }

  PlanExerciseModel copyWith({
    String? id,
    String? name,
    bool? isDurationBased,
    int? sets,
    int? reps,
    int? durationMinutes,
  }) {
    return PlanExerciseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isDurationBased: isDurationBased ?? this.isDurationBased,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}

class WorkoutPlanModel {
  final String id;
  final String title;
  final List<PlanExerciseModel> exercises;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const WorkoutPlanModel({
    required this.id,
    required this.title,
    required this.exercises,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  factory WorkoutPlanModel.fromJson(Map<String, dynamic> json, String id) {
    return WorkoutPlanModel(
      id: id,
      title: json['title'] as String,
      exercises: (json['exercises'] as List<dynamic>? ?? [])
          .map((e) => PlanExerciseModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  WorkoutPlanModel copyWith({
    String? id,
    String? title,
    List<PlanExerciseModel>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutPlanModel(
      id: id ?? this.id,
      title: title ?? this.title,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class LoggedExerciseModel {
  final String id;
  final String name;
  final bool isDurationBased;
  final int? sets;
  final int? reps;
  final int? durationMinutes;
  final int? weight; // Optional weight used
  final String? notes; // Optional notes
  final DateTime loggedAt;

  const LoggedExerciseModel({
    required this.id,
    required this.name,
    required this.isDurationBased,
    this.sets,
    this.reps,
    this.durationMinutes,
    this.weight,
    this.notes,
    required this.loggedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isDurationBased': isDurationBased,
        'sets': sets,
        'reps': reps,
        'durationMinutes': durationMinutes,
        'weight': weight,
        'notes': notes,
        'loggedAt': Timestamp.fromDate(loggedAt),
      };

  factory LoggedExerciseModel.fromJson(Map<String, dynamic> json) {
    return LoggedExerciseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      isDurationBased: json['isDurationBased'] as bool? ?? false,
      sets: (json['sets'] as num?)?.toInt(),
      reps: (json['reps'] as num?)?.toInt(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      weight: (json['weight'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      loggedAt: (json['loggedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  LoggedExerciseModel copyWith({
    String? id,
    String? name,
    bool? isDurationBased,
    int? sets,
    int? reps,
    int? durationMinutes,
    int? weight,
    String? notes,
    DateTime? loggedAt,
  }) {
    return LoggedExerciseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isDurationBased: isDurationBased ?? this.isDurationBased,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }
}

class WorkoutSessionModel {
  final String id;
  final String? planId; // Optional - null if created from scratch
  final String? planTitle; // Optional - cached plan title
  final List<LoggedExerciseModel> exercises;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? notes; // Optional session notes
  final Duration? totalDuration; // Calculated duration

  const WorkoutSessionModel({
    required this.id,
    this.planId,
    this.planTitle,
    required this.exercises,
    required this.startedAt,
    this.endedAt,
    this.notes,
    this.totalDuration,
  });

  Map<String, dynamic> toJson() => {
        'planId': planId,
        'planTitle': planTitle,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'startedAt': Timestamp.fromDate(startedAt),
        'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
        'notes': notes,
        'totalDuration': totalDuration?.inMinutes,
      };

  factory WorkoutSessionModel.fromJson(Map<String, dynamic> json, String id) {
    return WorkoutSessionModel(
      id: id,
      planId: json['planId'] as String?,
      planTitle: json['planTitle'] as String?,
      exercises: (json['exercises'] as List<dynamic>? ?? [])
          .map((e) => LoggedExerciseModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      startedAt: (json['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endedAt: (json['endedAt'] as Timestamp?)?.toDate(),
      notes: json['notes'] as String?,
      totalDuration: json['totalDuration'] != null
          ? Duration(minutes: (json['totalDuration'] as num).toInt())
          : null,
    );
  }

  WorkoutSessionModel copyWith({
    String? id,
    String? planId,
    String? planTitle,
    List<LoggedExerciseModel>? exercises,
    DateTime? startedAt,
    DateTime? endedAt,
    String? notes,
    Duration? totalDuration,
  }) {
    return WorkoutSessionModel(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      planTitle: planTitle ?? this.planTitle,
      exercises: exercises ?? this.exercises,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      notes: notes ?? this.notes,
      totalDuration: totalDuration ?? this.totalDuration,
    );
  }

  // Helper getter for session duration
  Duration get sessionDuration {
    if (endedAt != null) {
      return endedAt!.difference(startedAt);
    }
    return DateTime.now().difference(startedAt);
  }

  // Helper getter to check if session is active
  bool get isActive => endedAt == null;
}

class ScheduledWorkoutModel {
  final String id;
  final String planId;
  final String planTitle;
  final int dayOfWeek; // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
  final DateTime createdAt;
  final DateTime? completedAt; // When the workout was actually completed
  final String? notes; // Optional notes for this scheduled workout

  const ScheduledWorkoutModel({
    required this.id,
    required this.planId,
    required this.planTitle,
    required this.dayOfWeek,
    required this.createdAt,
    this.completedAt,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'planId': planId,
        'planTitle': planTitle,
        'dayOfWeek': dayOfWeek,
        'createdAt': Timestamp.fromDate(createdAt),
        'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'notes': notes,
      };

  factory ScheduledWorkoutModel.fromJson(Map<String, dynamic> json, String id) {
    return ScheduledWorkoutModel(
      id: json['id'] as String? ?? id,
      planId: json['planId'] as String,
      planTitle: json['planTitle'] as String,
      dayOfWeek: json['dayOfWeek'] as int,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      completedAt: (json['completedAt'] as Timestamp?)?.toDate(),
      notes: json['notes'] as String?,
    );
  }

  ScheduledWorkoutModel copyWith({
    String? id,
    String? planId,
    String? planTitle,
    int? dayOfWeek,
    DateTime? createdAt,
    DateTime? completedAt,
    String? notes,
  }) {
    return ScheduledWorkoutModel(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      planTitle: planTitle ?? this.planTitle,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }

  String get dayName {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[dayOfWeek];
  }

  String get shortDayName {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[dayOfWeek];
  }

  bool get isCompleted => completedAt != null;
}

class WorkoutScheduleModel {
  final String id;
  final List<ScheduledWorkoutModel> scheduledWorkouts;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkoutScheduleModel({
    required this.id,
    required this.scheduledWorkouts,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'scheduledWorkouts': scheduledWorkouts.map((s) => s.toJson()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory WorkoutScheduleModel.fromJson(Map<String, dynamic> json, String id) {
    return WorkoutScheduleModel(
      id: id,
      scheduledWorkouts: (json['scheduledWorkouts'] as List<dynamic>? ?? [])
          .map((s) => ScheduledWorkoutModel.fromJson(Map<String, dynamic>.from(s as Map), ''))
          .toList(),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  WorkoutScheduleModel copyWith({
    String? id,
    List<ScheduledWorkoutModel>? scheduledWorkouts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutScheduleModel(
      id: id ?? this.id,
      scheduledWorkouts: scheduledWorkouts ?? this.scheduledWorkouts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  List<ScheduledWorkoutModel> getWorkoutsForDay(int dayOfWeek) {
    return scheduledWorkouts.where((s) => s.dayOfWeek == dayOfWeek).toList();
  }

  bool hasWorkoutForDay(int dayOfWeek) {
    return scheduledWorkouts.any((s) => s.dayOfWeek == dayOfWeek);
  }
}


