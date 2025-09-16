import 'package:flutter/material.dart';
import '/data/models/workout_models.dart';

class WorkoutSessionDetailsScreen extends StatelessWidget {
  final WorkoutSessionModel session;

  const WorkoutSessionDetailsScreen({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(session.planTitle ?? 'Workout Session'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSessionHeader(context),
            const SizedBox(height: 24),
            _buildSessionStats(context),
            const SizedBox(height: 24),
            _buildExercisesList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    session.planTitle ?? 'Quick Session',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.access_time,
              label: 'Duration',
              value: _formatDuration(session.sessionDuration),
            ),
            _buildInfoRow(
              icon: Icons.fitness_center,
              label: 'Exercises',
              value: '${session.exercises.length} exercises',
            ),
            if (session.endedAt != null)
              _buildInfoRow(
                icon: Icons.calendar_today,
                label: 'Completed',
                value: _formatDate(session.endedAt!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionStats(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Sets',
                    value: _getTotalSets().toString(),
                    icon: Icons.repeat,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Reps',
                    value: _getTotalReps().toString(),
                    icon: Icons.repeat_one,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Weight',
                    value: '${_getTotalWeight()} lbs',
                    icon: Icons.fitness_center,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Avg Weight',
                    value: '${_getAverageWeight()} lbs',
                    icon: Icons.trending_up,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exercises',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...session.exercises.asMap().entries.map((entry) {
          final index = entry.key;
          final exercise = entry.value;
          return _buildExerciseCard(exercise, index + 1, context);
        }).toList(),
      ],
    );
  }

  Widget _buildExerciseCard(LoggedExerciseModel exercise, int exerciseNumber, BuildContext context) {
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
                    '$exerciseNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    exercise.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildExerciseDetails(exercise, context),
            if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  exercise.notes!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseDetails(LoggedExerciseModel exercise, BuildContext context) {
    if (exercise.isDurationBased) {
      return Row(
        children: [
          Icon(Icons.timer, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            'Duration: ${exercise.durationMinutes} minutes',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (exercise.weight != null) ...[
            const SizedBox(width: 16),
            Icon(Icons.fitness_center, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'Weight: ${exercise.weight} lbs',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.repeat, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Sets: ${exercise.sets}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 16),
              Icon(Icons.repeat_one, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Reps: ${exercise.reps}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          if (exercise.weight != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.fitness_center, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Weight: ${exercise.weight} lbs',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 16),
                Text(
                  'Total: ${exercise.weight! * exercise.sets! * exercise.reps!} lbs',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(date.year, date.month, date.day);
    
    if (sessionDate == today) {
      return 'Today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (sessionDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.month}/${date.day}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  int _getTotalSets() {
    return session.exercises
        .where((e) => !e.isDurationBased && e.sets != null)
        .fold(0, (sum, e) => sum + (e.sets ?? 0));
  }

  int _getTotalReps() {
    return session.exercises
        .where((e) => !e.isDurationBased && e.reps != null && e.sets != null)
        .fold(0, (sum, e) => sum + ((e.reps ?? 0) * (e.sets ?? 0)));
  }

  int _getTotalWeight() {
    return session.exercises
        .where((e) => e.weight != null)
        .fold(0, (sum, e) {
          if (e.isDurationBased) {
            return sum + (e.weight ?? 0);
          } else {
            return sum + ((e.weight ?? 0) * (e.sets ?? 0) * (e.reps ?? 0));
          }
        });
  }

  int _getAverageWeight() {
    final exercisesWithWeight = session.exercises
        .where((e) => e.weight != null && !e.isDurationBased)
        .toList();
    
    if (exercisesWithWeight.isEmpty) return 0;
    
    final totalWeight = exercisesWithWeight.fold(0, (sum, e) => sum + (e.weight ?? 0));
    return totalWeight ~/ exercisesWithWeight.length;
  }
}