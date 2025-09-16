import 'dart:async';
import 'package:flutter/material.dart';

import '/data/models/workout_models.dart';
import '/logic/trackers/workout_plans_bloc/workout_plans_bloc.dart';
import '/logic/trackers/workout_plans_bloc/workout_plans_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dialogs/exercise_logging_dialog.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final WorkoutPlanModel? plan;

  const WorkoutSessionScreen({
    super.key,
    this.plan,
  });

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  final List<LoggedExerciseModel> _loggedExercises = [];
  final DateTime _sessionStartTime = DateTime.now();
  Timer? _timer;
  Duration _sessionDuration = Duration.zero;
  bool _isSessionActive = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // If starting from a plan, pre-populate exercises
    if (widget.plan != null) {
      _initializeFromPlan();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isSessionActive) {
        setState(() {
          _sessionDuration = DateTime.now().difference(_sessionStartTime);
        });
      }
    });
  }

  void _initializeFromPlan() {
    if (widget.plan == null) return;

    // Don't pre-populate exercises - let user log them as they go
    // This allows them to input actual results vs targets
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plan?.title ?? 'Quick Session'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _showExitDialog,
        ),
        actions: [
          if (_loggedExercises.isNotEmpty)
            TextButton(
              onPressed: _isSessionActive ? _endSession : _logWorkout,
              child: Text(
                _isSessionActive ? 'End Session' : 'Log Workout',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSessionHeader(),
          Expanded(
            child: _buildExercisesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExercise,
        tooltip: 'Add Exercise',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSessionHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDuration(_sessionDuration),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _isSessionActive ? 'Session Active' : 'Session Ended',
                    style: TextStyle(
                      color: _isSessionActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_loggedExercises.length} exercises',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Started ${_formatTime(_sessionStartTime)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (widget.plan != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.list_alt, size: 16, color: Colors.blue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Based on: ${widget.plan!.title}',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addExerciseFromPlan,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add from Plan'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExercisesList() {
    if (_loggedExercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No exercises logged yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first exercise',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _loggedExercises.length,
      itemBuilder: (context, index) {
        final exercise = _loggedExercises[index];
        return _buildExerciseCard(exercise, index);
      },
    );
  }

  Widget _buildExerciseCard(LoggedExerciseModel exercise, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  radius: 16,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _getExerciseDescription(exercise),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editExercise(exercise, index);
                        break;
                      case 'remove':
                        _removeExercise(index);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Remove', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!exercise.isDurationBased) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${exercise.sets} × ${exercise.reps}',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (exercise.isDurationBased)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${exercise.durationMinutes}m',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (exercise.weight != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fitness_center, size: 12, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          '${exercise.weight} lbs',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (exercise.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        exercise.notes!,
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getExerciseDescription(LoggedExerciseModel exercise) {
    if (exercise.isDurationBased) {
      return '${exercise.durationMinutes} minutes';
    } else {
      return '${exercise.sets} sets × ${exercise.reps} reps';
    }
  }

  void _addExercise() {
    // Always show the full exercise logging dialog for adding new exercises
    showDialog(
      context: context,
      builder: (context) => ExerciseLoggingDialog(),
    ).then((result) {
      if (result is LoggedExerciseModel) {
        setState(() {
          _loggedExercises.add(result);
        });
      }
    });
  }

  void _editExercise(LoggedExerciseModel exercise, int index) {
    showDialog(
      context: context,
      builder: (context) => ExerciseLoggingDialog(
        exercise: exercise,
      ),
    ).then((result) {
      if (result is LoggedExerciseModel) {
        setState(() {
          _loggedExercises[index] = result;
        });
      }
    });
  }

  void _removeExercise(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Exercise'),
        content: Text('Are you sure you want to remove ${_loggedExercises[index].name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _loggedExercises.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _endSession() {
    setState(() {
      _isSessionActive = false;
    });
    _timer?.cancel();
  }

  void _addExerciseFromPlan() {
    if (widget.plan == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Exercise from Plan'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.plan!.exercises.length,
            itemBuilder: (context, index) {
              final planExercise = widget.plan!.exercises[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text('${index + 1}'),
                ),
                title: Text(planExercise.name),
                subtitle: Text(_getPlanExerciseDescription(planExercise)),
                onTap: () {
                  Navigator.pop(context);
                  _logExerciseFromPlan(planExercise);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _logExerciseFromPlan(PlanExerciseModel planExercise) {
    showDialog(
      context: context,
      builder: (context) => ExerciseLoggingDialog(
        planExercise: planExercise,
      ),
    ).then((result) {
      if (result is LoggedExerciseModel) {
        setState(() {
          _loggedExercises.add(result);
        });
      }
    });
  }

  String _getPlanExerciseDescription(PlanExerciseModel exercise) {
    if (exercise.isDurationBased) {
      return 'Target: ${exercise.durationMinutes} minutes';
    } else {
      return 'Target: ${exercise.sets} sets × ${exercise.reps} reps';
    }
  }

  void _logWorkout() {
    if (_loggedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one exercise before logging the workout')),
      );
      return;
    }

    final session = WorkoutSessionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      planId: widget.plan?.id,
      planTitle: widget.plan?.title,
      exercises: _loggedExercises,
      startedAt: _sessionStartTime,
      endedAt: _isSessionActive ? DateTime.now() : null,
      totalDuration: _sessionDuration,
    );

    // Save workout session to database via BLoC
    context.read<WorkoutPlansBloc>().add(AddWorkoutSession(session));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Workout logged successfully! ${_loggedExercises.length} exercises completed.'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Workout'),
        content: const Text('Are you sure you want to exit without logging this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit workout
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
