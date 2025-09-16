import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '/data/models/workout_models.dart';
import '/data/repositories/workout_repository.dart';
import 'workout_plans_event.dart';
import 'workout_plans_state.dart';

class WorkoutPlansBloc extends Bloc<WorkoutPlansEvent, WorkoutPlansState> {
  final WorkoutRepository _repo;
  StreamSubscription<List<WorkoutPlanModel>>? _plansSub;
  StreamSubscription<List<ExerciseNameModel>>? _namesSub;
  StreamSubscription<List<WorkoutSessionModel>>? _sessionsSub;
  StreamSubscription<WorkoutScheduleModel>? _scheduleSub;

  WorkoutPlansBloc(this._repo) : super(WorkoutPlansInitial()) {
    on<LoadWorkoutPlans>(_onLoad);
    on<AddWorkoutPlan>(_onAdd);
    on<UpdateWorkoutPlan>(_onUpdate);
    on<DeleteWorkoutPlan>(_onDelete);
    on<PlansUpdatedFromStream>((e, emit) {
      final current = state;
      if (current is WorkoutPlansLoaded) {
        emit(WorkoutPlansLoaded(e.plans, current.exerciseNames, current.sessions, current.schedule));
      } else {
        emit(WorkoutPlansLoaded(e.plans, const [], const [], WorkoutScheduleModel(
          id: 'current',
          scheduledWorkouts: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )));
      }
    });
    on<ExerciseNamesUpdatedFromStream>((e, emit) {
      final current = state;
      if (current is WorkoutPlansLoaded) {
        emit(WorkoutPlansLoaded(current.plans, e.names, current.sessions, current.schedule));
      } else {
        emit(WorkoutPlansLoaded(const [], e.names, const [], WorkoutScheduleModel(
          id: 'current',
          scheduledWorkouts: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )));
      }
    });
    on<WorkoutPlansStreamError>((e, emit) => emit(WorkoutPlansError(e.message)));
    
    // Workout Sessions
    on<LoadWorkoutSessions>(_onLoadSessions);
    on<AddWorkoutSession>(_onAddSession);
    on<UpdateWorkoutSession>(_onUpdateSession);
    on<DeleteWorkoutSession>(_onDeleteSession);
    on<WorkoutSessionsUpdatedFromStream>((e, emit) {
      final current = state;
      if (current is WorkoutPlansLoaded) {
        emit(WorkoutPlansLoaded(current.plans, current.exerciseNames, e.sessions, current.schedule));
      } else {
        emit(WorkoutPlansLoaded(const [], const [], e.sessions, WorkoutScheduleModel(
          id: 'current',
          scheduledWorkouts: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )));
      }
    });
    on<WorkoutSessionsStreamError>((e, emit) => emit(WorkoutPlansError(e.message)));
    
    // Workout Schedule
    on<LoadWorkoutSchedule>(_onLoadSchedule);
    on<AddScheduledWorkout>(_onAddScheduledWorkout);
    on<RemoveScheduledWorkout>(_onRemoveScheduledWorkout);
    on<UpdateScheduledWorkout>(_onUpdateScheduledWorkout);
    on<WorkoutScheduleUpdatedFromStream>((e, emit) {
      final current = state;
      if (current is WorkoutPlansLoaded) {
        emit(WorkoutPlansLoaded(current.plans, current.exerciseNames, current.sessions, e.schedule));
      } else {
        emit(WorkoutPlansLoaded(const [], const [], const [], e.schedule));
      }
    });
    on<WorkoutScheduleStreamError>((e, emit) => emit(WorkoutPlansError(e.message)));
  }

  Future<void> _onLoad(LoadWorkoutPlans event, Emitter<WorkoutPlansState> emit) async {
    emit(WorkoutPlansLoading());
    await _plansSub?.cancel();
    await _namesSub?.cancel();
    await _sessionsSub?.cancel();
    await _scheduleSub?.cancel();

    _plansSub = _repo.plansStream().listen((plans) {
      if (!isClosed) add(PlansUpdatedFromStream(plans));
    }, onError: (e) {
      if (!isClosed) add(WorkoutPlansStreamError(e.toString()));
    });

    _namesSub = _repo.exerciseNamesStream().listen((names) {
      if (!isClosed) add(ExerciseNamesUpdatedFromStream(names));
    }, onError: (e) {
      if (!isClosed) add(WorkoutPlansStreamError(e.toString()));
    });

    _sessionsSub = _repo.workoutSessionsStream().listen((sessions) {
      if (!isClosed) add(WorkoutSessionsUpdatedFromStream(sessions));
    }, onError: (e) {
      if (!isClosed) add(WorkoutSessionsStreamError(e.toString()));
    });

    _scheduleSub = _repo.workoutScheduleStream().listen((schedule) {
      if (!isClosed) add(WorkoutScheduleUpdatedFromStream(schedule));
    }, onError: (e) {
      if (!isClosed) add(WorkoutScheduleStreamError(e.toString()));
    });
  }

  Future<void> _onAdd(AddWorkoutPlan event, Emitter<WorkoutPlansState> emit) async {
    await _repo.addPlan(event.plan);
  }

  Future<void> _onUpdate(UpdateWorkoutPlan event, Emitter<WorkoutPlansState> emit) async {
    await _repo.updatePlan(event.plan);
  }

  Future<void> _onDelete(DeleteWorkoutPlan event, Emitter<WorkoutPlansState> emit) async {
    await _repo.deletePlan(event.planId);
  }

  // Workout Session methods
  Future<void> _onLoadSessions(LoadWorkoutSessions event, Emitter<WorkoutPlansState> emit) async {
    // Sessions are loaded automatically with plans
  }

  Future<void> _onAddSession(AddWorkoutSession event, Emitter<WorkoutPlansState> emit) async {
    await _repo.addWorkoutSession(event.session);
  }

  Future<void> _onUpdateSession(UpdateWorkoutSession event, Emitter<WorkoutPlansState> emit) async {
    await _repo.updateWorkoutSession(event.session);
  }

  Future<void> _onDeleteSession(DeleteWorkoutSession event, Emitter<WorkoutPlansState> emit) async {
    await _repo.deleteWorkoutSession(event.sessionId);
  }

  Future<void> _onLoadSchedule(LoadWorkoutSchedule event, Emitter<WorkoutPlansState> emit) async {
    // Schedule is already loaded via the stream in _onLoad
  }

  Future<void> _onAddScheduledWorkout(AddScheduledWorkout event, Emitter<WorkoutPlansState> emit) async {
    await _repo.addScheduledWorkout(event.scheduledWorkout);
  }

  Future<void> _onRemoveScheduledWorkout(RemoveScheduledWorkout event, Emitter<WorkoutPlansState> emit) async {
    await _repo.removeScheduledWorkout(event.scheduledWorkoutId);
  }

  Future<void> _onUpdateScheduledWorkout(UpdateScheduledWorkout event, Emitter<WorkoutPlansState> emit) async {
    await _repo.updateScheduledWorkout(event.scheduledWorkout);
  }

  @override
  Future<void> close() {
    _plansSub?.cancel();
    _namesSub?.cancel();
    _sessionsSub?.cancel();
    _scheduleSub?.cancel();
    return super.close();
  }
}


