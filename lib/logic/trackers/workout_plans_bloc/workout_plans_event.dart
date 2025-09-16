import '/data/models/workout_models.dart';

abstract class WorkoutPlansEvent {}

class LoadWorkoutPlans extends WorkoutPlansEvent {}

class AddWorkoutPlan extends WorkoutPlansEvent {
  final WorkoutPlanModel plan;
  AddWorkoutPlan(this.plan);
}

class UpdateWorkoutPlan extends WorkoutPlansEvent {
  final WorkoutPlanModel plan;
  UpdateWorkoutPlan(this.plan);
}

class DeleteWorkoutPlan extends WorkoutPlansEvent {
  final String planId;
  DeleteWorkoutPlan(this.planId);
}

class PlansUpdatedFromStream extends WorkoutPlansEvent {
  final List<WorkoutPlanModel> plans;
  PlansUpdatedFromStream(this.plans);
}

class ExerciseNamesUpdatedFromStream extends WorkoutPlansEvent {
  final List<ExerciseNameModel> names;
  ExerciseNamesUpdatedFromStream(this.names);
}

class WorkoutPlansStreamError extends WorkoutPlansEvent {
  final String message;
  WorkoutPlansStreamError(this.message);
}

class LoadWorkoutSessions extends WorkoutPlansEvent {}

class AddWorkoutSession extends WorkoutPlansEvent {
  final WorkoutSessionModel session;
  AddWorkoutSession(this.session);
}

class UpdateWorkoutSession extends WorkoutPlansEvent {
  final WorkoutSessionModel session;
  UpdateWorkoutSession(this.session);
}

class DeleteWorkoutSession extends WorkoutPlansEvent {
  final String sessionId;
  DeleteWorkoutSession(this.sessionId);
}

class WorkoutSessionsUpdatedFromStream extends WorkoutPlansEvent {
  final List<WorkoutSessionModel> sessions;
  WorkoutSessionsUpdatedFromStream(this.sessions);
}

class WorkoutSessionsStreamError extends WorkoutPlansEvent {
  final String message;
  WorkoutSessionsStreamError(this.message);
}

class LoadWorkoutSchedule extends WorkoutPlansEvent {}

class AddScheduledWorkout extends WorkoutPlansEvent {
  final ScheduledWorkoutModel scheduledWorkout;
  AddScheduledWorkout(this.scheduledWorkout);
}

class RemoveScheduledWorkout extends WorkoutPlansEvent {
  final String scheduledWorkoutId;
  RemoveScheduledWorkout(this.scheduledWorkoutId);
}

class UpdateScheduledWorkout extends WorkoutPlansEvent {
  final ScheduledWorkoutModel scheduledWorkout;
  UpdateScheduledWorkout(this.scheduledWorkout);
}

class WorkoutScheduleUpdatedFromStream extends WorkoutPlansEvent {
  final WorkoutScheduleModel schedule;
  WorkoutScheduleUpdatedFromStream(this.schedule);
}

class WorkoutScheduleStreamError extends WorkoutPlansEvent {
  final String message;
  WorkoutScheduleStreamError(this.message);
}


