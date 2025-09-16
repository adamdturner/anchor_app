import 'package:flutter/material.dart';

class ExerciseSelectionDialog extends StatefulWidget {
  final String? selectedExerciseName;
  final Function(String name, bool isDurationBased, int? sets, int? reps, int? durationMinutes) onExerciseSelected;

  const ExerciseSelectionDialog({
    super.key,
    this.selectedExerciseName,
    required this.onExerciseSelected,
  });

  @override
  State<ExerciseSelectionDialog> createState() => _ExerciseSelectionDialogState();
}

class _ExerciseSelectionDialogState extends State<ExerciseSelectionDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _setsController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  
  bool _isDurationBased = false;
  String? _selectedExerciseName;

  @override
  void initState() {
    super.initState();
    _selectedExerciseName = widget.selectedExerciseName;
    if (_selectedExerciseName != null) {
      _nameController.text = _selectedExerciseName!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Exercise'),
      content: SingleChildScrollView(
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _canSave() ? _saveExercise : null,
          child: const Text('Add'),
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
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'Enter exercise name',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _selectedExerciseName = null;
            });
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
                _setsController.clear();
                _repsController.clear();
                _durationController.clear();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRepsSetsFields() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _setsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Sets',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: _repsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Reps',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationField() {
    return TextField(
      controller: _durationController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Duration (minutes)',
        border: OutlineInputBorder(),
        suffixText: 'min',
      ),
    );
  }

  bool _canSave() {
    if (_nameController.text.trim().isEmpty) return false;
    
    if (_isDurationBased) {
      final duration = int.tryParse(_durationController.text);
      return duration != null && duration > 0;
    } else {
      final sets = int.tryParse(_setsController.text);
      final reps = int.tryParse(_repsController.text);
      return sets != null && sets > 0 && reps != null && reps > 0;
    }
  }

  void _saveExercise() {
    final name = _nameController.text.trim();
    final isDurationBased = _isDurationBased;
    
    int? sets, reps, durationMinutes;
    
    if (isDurationBased) {
      durationMinutes = int.tryParse(_durationController.text);
    } else {
      sets = int.tryParse(_setsController.text);
      reps = int.tryParse(_repsController.text);
    }

    widget.onExerciseSelected(name, isDurationBased, sets, reps, durationMinutes);
    Navigator.pop(context);
  }
}
