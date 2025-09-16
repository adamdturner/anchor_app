import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/logic/trackers/workout_plans_bloc/workout_plans_bloc.dart';
import '/logic/trackers/workout_plans_bloc/workout_plans_state.dart';
import '/data/models/workout_models.dart';

class QuickSessionDialog extends StatelessWidget {
  final Function(WorkoutPlanModel? plan) onPlanSelected;

  const QuickSessionDialog({
    super.key,
    required this.onPlanSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Start Quick Session'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose how you want to start your workout:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            _buildFromScratchOption(context),
            const SizedBox(height: 12),
            const Text(
              'OR',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            _buildFromPlanOption(context),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildFromScratchOption(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          // Use a small delay to ensure dialog is fully closed before navigation
          Future.delayed(const Duration(milliseconds: 100), () {
            onPlanSelected(null); // null means start from scratch
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start from Scratch',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Log exercises as you go',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFromPlanOption(BuildContext context) {
    return BlocBuilder<WorkoutPlansBloc, WorkoutPlansState>(
      builder: (context, state) {
        if (state is WorkoutPlansLoading || state is WorkoutPlansInitial) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (state is WorkoutPlansError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(height: 8),
                  Text('Error: ${state.message}'),
                ],
              ),
            ),
          );
        }

        final loaded = state as WorkoutPlansLoaded;
        final plans = loaded.plans;

        if (plans.isEmpty) {
          return Card(
            child: InkWell(
              onTap: () {
                // Navigate to create plan
                Navigator.pop(context);
                Navigator.pushNamed(context, '/workout_create_plan');
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No Plans Available',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Create your first workout plan',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Use Existing Plan:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: plans.length,
                    itemBuilder: (context, index) {
                      final plan = plans[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.fitness_center,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            plan.title,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(_getPlanSubtitle(plan)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () {
                            Navigator.pop(context);
                            // Use a small delay to ensure dialog is fully closed before navigation
                            Future.delayed(const Duration(milliseconds: 100), () {
                              onPlanSelected(plan);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getPlanSubtitle(WorkoutPlanModel plan) {
    if (plan.exercises.isEmpty) return 'No exercises yet';
    final parts = plan.exercises.take(2).map((e) {
      if (e.isDurationBased) {
        return '${e.name} (${e.durationMinutes}m)';
      }
      return '${e.name} (${e.sets}x${e.reps})';
    }).toList();
    final more = plan.exercises.length - parts.length;
    return more > 0 ? parts.join(', ') + ' +$more more' : parts.join(', ');
  }
}
