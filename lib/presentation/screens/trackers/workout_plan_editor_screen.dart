import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'data/recent_exercises.dart';
import '/data/models/workout_models.dart';
import '/logic/trackers/workout_plans_bloc/workout_plans_bloc.dart';
import '/logic/trackers/workout_plans_bloc/workout_plans_event.dart';
import 'dialogs/exercise_selection_dialog.dart';

class WorkoutPlanEditorScreen extends StatefulWidget {
  const WorkoutPlanEditorScreen({super.key});

  @override
  State<WorkoutPlanEditorScreen> createState() => _WorkoutPlanEditorScreenState();
}

class _WorkoutPlanEditorScreenState extends State<WorkoutPlanEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final List<PlanExerciseModel> _exercises = [];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Workout Plan'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: _savePlan,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Plan Title *',
                hintText: 'e.g., Leg Day',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            const Text(
              'Exercises',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (_exercises.isEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('No exercises added yet'),
                  subtitle: const Text('Tap "Add Exercise" to include one.'),
                ),
              ),
            ..._exercises.asMap().entries.map((entry) {
              final index = entry.key;
              final exercise = entry.value;
              return _buildExerciseCard(exercise, index);
            }),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _addExercise,
                icon: const Icon(Icons.add),
                label: const Text('Add Exercise'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addExercise() {
    showDialog(
      context: context,
      builder: (context) => ExerciseSelectionDialog(
        onExerciseSelected: (name, isDurationBased, sets, reps, durationMinutes) {
          final exerciseId = DateTime.now().millisecondsSinceEpoch.toString();
          final newExercise = PlanExerciseModel(
            id: exerciseId,
            name: name,
            isDurationBased: isDurationBased,
            sets: sets,
            reps: reps,
            durationMinutes: durationMinutes,
          );
          
          setState(() {
            _exercises.add(newExercise);
          });
        },
      ),
    );
  }

  Widget _buildExerciseCard(PlanExerciseModel exercise, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text('${index + 1}'),
        ),
        title: Text(
          exercise.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(_getExerciseDescription(exercise)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editExercise(exercise, index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () => _removeExercise(index),
            ),
          ],
        ),
      ),
    );
  }

  String _getExerciseDescription(PlanExerciseModel exercise) {
    if (exercise.isDurationBased) {
      return '${exercise.durationMinutes} minutes';
    } else {
      return '${exercise.sets} sets × ${exercise.reps} reps';
    }
  }

  void _editExercise(PlanExerciseModel exercise, int index) {
    showDialog(
      context: context,
      builder: (context) => ExerciseSelectionDialog(
        selectedExerciseName: exercise.name,
        onExerciseSelected: (name, isDurationBased, sets, reps, durationMinutes) {
          final updatedExercise = exercise.copyWith(
            name: name,
            isDurationBased: isDurationBased,
            sets: sets,
            reps: reps,
            durationMinutes: durationMinutes,
          );
          
          setState(() {
            _exercises[index] = updatedExercise;
          });
        },
      ),
    );
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  void _savePlan() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a plan title')),
      );
      return;
    }

    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one exercise')),
      );
      return;
    }

    final plan = WorkoutPlanModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      exercises: _exercises,
      createdAt: DateTime.now(),
    );

    context.read<WorkoutPlansBloc>().add(AddWorkoutPlan(plan));

    // Persist names locally too for autocomplete fallback within this session
    for (final e in _exercises) {
      RecentExercises.add(e.name);
    }

    Navigator.pop(context);
  }
}


