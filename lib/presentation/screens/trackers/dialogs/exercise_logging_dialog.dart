import 'package:flutter/material.dart';
import '/data/models/workout_models.dart';

class ExerciseLoggingDialog extends StatefulWidget {
  final LoggedExerciseModel? exercise;
  final PlanExerciseModel? planExercise; // Target from plan

  const ExerciseLoggingDialog({
    super.key,
    this.exercise,
    this.planExercise,
  });

  @override
  State<ExerciseLoggingDialog> createState() => _ExerciseLoggingDialogState();
}

class _ExerciseLoggingDialogState extends State<ExerciseLoggingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isDurationBased = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.exercise != null;
    if (_isEditing) {
      _populateFromExercise();
    } else if (widget.planExercise != null) {
      _populateFromPlan();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populateFromExercise() {
    final exercise = widget.exercise!;
    _nameController.text = exercise.name;
    _isDurationBased = exercise.isDurationBased;
    _setsController.text = exercise.sets?.toString() ?? '';
    _repsController.text = exercise.reps?.toString() ?? '';
    _weightController.text = exercise.weight?.toString() ?? '';
    _durationController.text = exercise.durationMinutes?.toString() ?? '';
    _notesController.text = exercise.notes ?? '';
  }

  void _populateFromPlan() {
    final plan = widget.planExercise!;
    _nameController.text = plan.name;
    _isDurationBased = plan.isDurationBased;
    _setsController.text = plan.sets?.toString() ?? '';
    _repsController.text = plan.reps?.toString() ?? '';
    _durationController.text = plan.durationMinutes?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Exercise' : 'Log Exercise'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExerciseNameField(),
              const SizedBox(height: 16),
              _buildExerciseTypeToggle(),
              const SizedBox(height: 16),
              if (_isDurationBased)
                _buildDurationField()
              else
                _buildRepsSetsFields(),
              const SizedBox(height: 16),
              _buildWeightField(),
              const SizedBox(height: 16),
              _buildNotesField(),
              if (widget.planExercise != null) ...[
                const SizedBox(height: 16),
                _buildPlanTargets(),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _canSave() ? _saveExercise : null,
          child: Text(_isEditing ? 'Update' : 'Log'),
        ),
      ],
    );
  }

  Widget _buildExerciseNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Exercise Name',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'Enter exercise name',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            // Update state for UI changes
            setState(() {});
          },
        ),
        const SizedBox(height: 8),
        // Exercise name suggestions (disabled for now to prevent crashes)
        // TODO: Re-enable when BLoC context is properly available
        const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildExerciseTypeToggle() {
    return Row(
      children: [
        const Text(
          'Exercise Type:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: false,
                label: Text('Reps & Sets'),
                icon: Icon(Icons.repeat),
              ),
              ButtonSegment<bool>(
                value: true,
                label: Text('Duration'),
                icon: Icon(Icons.timer),
              ),
            ],
            selected: {_isDurationBased},
            onSelectionChanged: (Set<bool> selection) {
              setState(() {
                _isDurationBased = selection.first;
                if (!_isDurationBased) {
                  _durationController.clear();
                } else {
                  _setsController.clear();
                  _repsController.clear();
                }
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRepsSetsFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _setsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Sets',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter sets';
                  }
                  final sets = int.tryParse(value);
                  if (sets == null || sets <= 0) {
                    return 'Enter valid sets';
                  }
                  return null;
                },
                onChanged: (value) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Reps',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter reps';
                  }
                  final reps = int.tryParse(value);
                  if (reps == null || reps <= 0) {
                    return 'Enter valid reps';
                  }
                  return null;
                },
                onChanged: (value) => setState(() {}),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationField() {
    return TextFormField(
      controller: _durationController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Duration (minutes)',
        border: OutlineInputBorder(),
        suffixText: 'min',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Enter duration';
        }
        final duration = int.tryParse(value);
        if (duration == null || duration <= 0) {
          return 'Enter valid duration';
        }
        return null;
      },
      onChanged: (value) => setState(() {}),
    );
  }

  Widget _buildWeightField() {
    return TextFormField(
      controller: _weightController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Weight (lbs)',
        border: OutlineInputBorder(),
        suffixText: 'lbs',
        hintText: 'Optional',
      ),
      onChanged: (value) => setState(() {}),
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Notes',
        border: OutlineInputBorder(),
        hintText: 'How did it feel? Any observations...',
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildPlanTargets() {
    if (widget.planExercise == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag, size: 16, color: Colors.blue),
              const SizedBox(width: 6),
              const Text(
                'Plan Target:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.planExercise!.isDurationBased
                ? '${widget.planExercise!.durationMinutes} minutes'
                : '${widget.planExercise!.sets} sets × ${widget.planExercise!.reps} reps',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  bool _canSave() {
    final nameEmpty = _nameController.text.trim().isEmpty;
    final durationEmpty = _isDurationBased ? _durationController.text.trim().isEmpty : false;
    final setsEmpty = !_isDurationBased ? _setsController.text.trim().isEmpty : false;
    final repsEmpty = !_isDurationBased ? _repsController.text.trim().isEmpty : false;
    
    final canSave = !nameEmpty && 
        (_isDurationBased ? !durationEmpty : (!setsEmpty && !repsEmpty));
    
    return canSave;
  }

  void _saveExercise() {
    // Manual validation for name field
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an exercise name')),
      );
      return;
    }

    // Validate other form fields
    if (_formKey.currentState?.validate() != true) return;

    final isDurationBased = _isDurationBased;
    
    int? sets, reps, durationMinutes, weight;
    final notes = _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null;
    
    if (isDurationBased) {
      durationMinutes = int.tryParse(_durationController.text.trim());
    } else {
      sets = int.tryParse(_setsController.text.trim());
      reps = int.tryParse(_repsController.text.trim());
    }
    
    weight = _weightController.text.trim().isNotEmpty 
        ? int.tryParse(_weightController.text.trim()) 
        : null;

    final exercise = LoggedExerciseModel(
      id: widget.exercise?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      isDurationBased: isDurationBased,
      sets: sets,
      reps: reps,
      durationMinutes: durationMinutes,
      weight: weight,
      notes: notes,
      loggedAt: widget.exercise?.loggedAt ?? DateTime.now(),
    );

    Navigator.pop(context, exercise);
  }
}
