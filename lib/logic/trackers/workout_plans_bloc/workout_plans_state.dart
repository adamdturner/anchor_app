import '/data/models/workout_models.dart';

abstract class WorkoutPlansState {}

class WorkoutPlansInitial extends WorkoutPlansState {}

class WorkoutPlansLoading extends WorkoutPlansState {}

class WorkoutPlansLoaded extends WorkoutPlansState {
  final List<WorkoutPlanModel> plans;
  final List<ExerciseNameModel> exerciseNames;
  final List<WorkoutSessionModel> sessions;
  final WorkoutScheduleModel schedule;
  
  WorkoutPlansLoaded(this.plans, this.exerciseNames, this.sessions, this.schedule);
}

class WorkoutPlansError extends WorkoutPlansState {
  final String message;
  WorkoutPlansError(this.message);
}


