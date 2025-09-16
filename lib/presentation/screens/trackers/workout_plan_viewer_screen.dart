import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/logic/trackers/workout_plans_bloc/workout_plans_bloc.dart';
import '/logic/trackers/workout_plans_bloc/workout_plans_state.dart';
import '/logic/trackers/workout_plans_bloc/workout_plans_event.dart';
import '/data/models/workout_models.dart';
import 'dialogs/exercise_selection_dialog.dart';

class WorkoutPlanViewerScreen extends StatefulWidget {
  final String planId;

  const WorkoutPlanViewerScreen({
    super.key,
    required this.planId,
  });

  @override
  State<WorkoutPlanViewerScreen> createState() => _WorkoutPlanViewerScreenState();
}

class _WorkoutPlanViewerScreenState extends State<WorkoutPlanViewerScreen> {
  WorkoutPlanModel? _plan;
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Plan' : 'View Plan'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_plan != null && !_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deletePlan,
              tooltip: 'Delete Plan',
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEdit,
              tooltip: 'Edit Plan',
            ),
          ],
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveChanges,
              tooltip: 'Save Changes',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelEdit,
              tooltip: 'Cancel',
            ),
          ],
        ],
      ),
      body: BlocBuilder<WorkoutPlansBloc, WorkoutPlansState>(
        builder: (context, state) {
          if (state is WorkoutPlansLoading || state is WorkoutPlansInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is WorkoutPlansError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          
          final loaded = state as WorkoutPlansLoaded;
          _plan = loaded.plans.firstWhere(
            (p) => p.id == widget.planId,
            orElse: () => throw Exception('Plan not found'),
          );

          return _buildPlanContent();
        },
      ),
      floatingActionButton: _isEditing
          ? FloatingActionButton(
              onPressed: _addExercise,
              tooltip: 'Add Exercise',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildPlanContent() {
    if (_plan == null) {
      return const Center(child: Text('Plan not found'));
    }

    return Column(
      children: [
        if (_isEditing)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.blue.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.edit, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Editing Mode - Tap exercises to edit, use + to add new ones',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPlanHeader(),
                const SizedBox(height: 24),
                _buildExercisesSection(),
                const SizedBox(height: 24),
                _buildPlanStats(),
                if (_isEditing) const SizedBox(height: 80), // Space for FAB
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isEditing)
                        TextField(
                          controller: TextEditingController(text: _plan!.title),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Plan Title',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            _plan = _plan!.copyWith(title: value);
                          },
                        )
                      else
                        Text(
                          _plan!.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Created ${_formatDate(_plan!.createdAt)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (_plan!.exercises.isNotEmpty)
                        Text(
                          '${_plan!.exercises.length} exercise${_plan!.exercises.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!_isEditing)
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _toggleEdit,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _deletePlan,
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                        label: const Text('Delete', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExercisesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Exercises',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addExercise,
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_plan!.exercises.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _isEditing ? 'Add exercises to this plan' : 'No exercises added yet',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          ..._plan!.exercises.asMap().entries.map((entry) {
            final index = entry.key;
            final exercise = entry.value;
            return _buildExerciseCard(exercise, index);
          }),
      ],
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
        trailing: _isEditing
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _editExercise(index),
                    tooltip: 'Edit Exercise',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () => _removeExercise(index),
                    tooltip: 'Remove Exercise',
                  ),
                ],
              )
            : null,
        onTap: _isEditing ? () => _editExercise(index) : null,
      ),
    );
  }

  Widget _buildPlanStats() {
    if (_plan!.exercises.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalExercises = _plan!.exercises.length;
    final repsBasedExercises = _plan!.exercises.where((e) => !e.isDurationBased).length;
    final durationBasedExercises = _plan!.exercises.where((e) => e.isDurationBased).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Plan Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatRow('Total Exercises', totalExercises.toString()),
            if (repsBasedExercises > 0)
              _buildStatRow('Reps & Sets Exercises', repsBasedExercises.toString()),
            if (durationBasedExercises > 0)
              _buildStatRow('Duration Exercises', durationBasedExercises.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChanges() {
    if (_plan == null) return;
    
    // Update the updatedAt timestamp
    final updatedPlan = _plan!.copyWith(updatedAt: DateTime.now());
    
    // Dispatch the update event to the BLoC
    context.read<WorkoutPlansBloc>().add(UpdateWorkoutPlan(updatedPlan));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Changes saved!')),
    );
    setState(() {
      _isEditing = false;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
    // TODO: Reset plan to original state
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
          
          final updatedExercises = List<PlanExerciseModel>.from(_plan!.exercises);
          updatedExercises.add(newExercise);
          
          setState(() {
            _plan = _plan!.copyWith(exercises: updatedExercises);
          });
        },
      ),
    );
  }

  void _editExercise(int index) {
    final exercise = _plan!.exercises[index];
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
          
          final updatedExercises = List<PlanExerciseModel>.from(_plan!.exercises);
          updatedExercises[index] = updatedExercise;
          
          setState(() {
            _plan = _plan!.copyWith(exercises: updatedExercises);
          });
        },
      ),
    );
  }

  void _removeExercise(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Exercise'),
        content: Text('Are you sure you want to remove ${_plan!.exercises[index].name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final updatedExercises = List<PlanExerciseModel>.from(_plan!.exercises);
              updatedExercises.removeAt(index);
              setState(() {
                _plan = _plan!.copyWith(exercises: updatedExercises);
              });
              Navigator.pop(context);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _deletePlan() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text('Are you sure you want to delete "${_plan!.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<WorkoutPlansBloc>().add(DeleteWorkoutPlan(_plan!.id));
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to plans list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Plan deleted successfully')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
