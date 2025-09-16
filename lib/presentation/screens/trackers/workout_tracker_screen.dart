import 'package:flutter_bloc/flutter_bloc.dart';

import '/logic/trackers/workout_plans_bloc/workout_plans_bloc.dart';
import '/logic/trackers/workout_plans_bloc/workout_plans_state.dart';
import '/logic/trackers/workout_plans_bloc/workout_plans_event.dart';
import '/data/models/workout_models.dart';
import 'package:flutter/material.dart';
import 'dialogs/quick_session_dialog.dart';
import 'workout_session_screen.dart';

class WorkoutTrackerScreen extends StatefulWidget {
  const WorkoutTrackerScreen({super.key});

  @override
  State<WorkoutTrackerScreen> createState() => _WorkoutTrackerScreenState();
}

class _WorkoutTrackerScreenState extends State<WorkoutTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.today), text: 'Today'),
            Tab(icon: Icon(Icons.list_alt), text: 'Plans'),
            Tab(icon: Icon(Icons.schedule), text: 'Schedule'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(),
          _buildPlansTab(),
          _buildScheduleTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabPressed,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Tab 1: Today
  Widget _buildTodayTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('Today\'s Workout'),
        _placeholderCard(
          title: 'No workout logged yet',
          subtitle: 'Plan a workout or start a quick session.',
          icon: Icons.fitness_center,
          actionText: 'Start Quick Session',
          onAction: _startQuickSession,
        ),
        const SizedBox(height: 16),
        _sectionHeader('Recent Sessions'),
        _buildRecentSessions(),
      ],
    );
  }

  // Tab 2: Plans
  Widget _buildPlansTab() {
    return BlocBuilder<WorkoutPlansBloc, WorkoutPlansState>(
      builder: (context, state) {
        if (state is WorkoutPlansLoading || state is WorkoutPlansInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is WorkoutPlansError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        final loaded = state as WorkoutPlansLoaded;
        final plans = loaded.plans;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionHeader('Workout Plans'),
            if (plans.isEmpty)
              _placeholderCard(
                title: 'Create your first plan',
                subtitle: 'Combine exercises with reps/sets or durations.',
                icon: Icons.list_alt,
                actionText: 'Create Plan',
                onAction: _createPlan,
              )
            else
              ...plans.map(_buildPlanTile),
            const SizedBox(height: 16),
            _sectionHeader('Exercises Library'),
            if (loaded.exerciseNames.isEmpty)
              _placeholderListTile('Add exercises like Squat, Bench Press, Plank...')
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: loaded.exerciseNames
                        .map((e) => Chip(label: Text(e.name)))
                        .toList(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPlanTile(WorkoutPlanModel plan) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.list_alt),
        title: Text(plan.title),
        subtitle: Text(_planSubtitle(plan)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _viewPlan(plan.id),
      ),
    );
  }

  String _planSubtitle(WorkoutPlanModel plan) {
    if (plan.exercises.isEmpty) return 'No exercises yet';
    final parts = plan.exercises.take(3).map((e) {
      if (e.isDurationBased) {
        return '${e.name} (${e.durationMinutes}m)';
      }
      return '${e.name} (${e.sets}x${e.reps})';
    }).toList();
    final more = plan.exercises.length - parts.length;
    return more > 0 ? parts.join(', ') + ' +$more more' : parts.join(', ');
  }

  // Tab 3: Schedule
  Widget _buildScheduleTab() {
    return BlocBuilder<WorkoutPlansBloc, WorkoutPlansState>(
      builder: (context, state) {
        if (state is WorkoutPlansLoaded) {
          return _buildWeeklySchedule(state.schedule, state.plans);
        } else if (state is WorkoutPlansLoading) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return const Center(child: Text('Error loading schedule'));
        }
      },
    );
  }

  Widget _buildWeeklySchedule(WorkoutScheduleModel schedule, List<WorkoutPlanModel> plans) {
    final daysOfWeek = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final today = DateTime.now().weekday % 7; // Convert to 0-6 (Sunday = 0)

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('Weekly Schedule'),
        const SizedBox(height: 16),
        // Week view with day rows (vertical layout)
        ...List.generate(7, (index) {
          final dayWorkouts = schedule.getWorkoutsForDay(index);
          final isToday = index == today;
          
          return _buildDayRow(
            dayName: daysOfWeek[index],
            dayIndex: index,
            workouts: dayWorkouts,
            isToday: isToday,
            availablePlans: plans,
          );
        }),
      ],
    );
  }

  Widget _buildDayRow({
    required String dayName,
    required int dayIndex,
    required List<ScheduledWorkoutModel> workouts,
    required bool isToday,
    required List<WorkoutPlanModel> availablePlans,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isToday ? Theme.of(context).colorScheme.primary.withOpacity(0.05) : null,
        border: Border.all(
          color: isToday ? Theme.of(context).colorScheme.primary : Colors.grey[300]!,
          width: isToday ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isToday ? Theme.of(context).colorScheme.primary : Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    dayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isToday ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Today',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Workouts content
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: _buildWorkoutsContent(workouts, dayIndex, availablePlans),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutsContent(List<ScheduledWorkoutModel> workouts, int dayIndex, List<WorkoutPlanModel> availablePlans) {
    return Row(
      children: [
        // Workouts list
        Expanded(
          child: workouts.isEmpty
              ? Text(
                  'No workouts scheduled',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: workouts.map((workout) => _buildScheduledWorkoutCard(workout)).toList(),
                ),
        ),
        // Add workout button
        const SizedBox(width: 12),
        InkWell(
          onTap: () => _showAddWorkoutDialog(dayIndex, availablePlans),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduledWorkoutCard(ScheduledWorkoutModel workout) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(6),
        color: Colors.white,
      ),
      child: Row(
        children: [
          // Workout icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.fitness_center,
              color: Theme.of(context).colorScheme.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          // Workout details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.planTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (workout.isCompleted)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Completed',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Action menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'remove') {
                _removeScheduledWorkout(workout.id);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16),
                    SizedBox(width: 8),
                    Text('Remove'),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.more_vert,
                size: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helpers
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _placeholderCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 32, color: Colors.grey[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onAction,
                child: Text(actionText),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _placeholderListTile(String text) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info_outline),
        title: Text(text),
      ),
    );
  }

  void _onFabPressed() {
    switch (_tabController.index) {
      case 0:
        _startQuickSession();
        break;
      case 1:
        _createPlan();
        break;
      case 2:
        _setSchedule();
        break;
    }
  }

  void _startQuickSession() {
    showDialog(
      context: context,
      builder: (context) => QuickSessionDialog(
        onPlanSelected: (plan) {
          // Navigate to workout session screen
          _navigateToWorkoutSession(plan);
        },
      ),
    );
  }

  void _navigateToWorkoutSession(WorkoutPlanModel? plan) {
    try {
      Navigator.of(context).pushNamed('/workout_session', arguments: plan);
    } catch (e) {
      // Fallback: navigate directly
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WorkoutSessionScreen(plan: plan),
        ),
      );
    }
  }

  void _createPlan() {
    Navigator.pushNamed(context, '/workout_create_plan');
  }

  void _setSchedule() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Schedule setup coming soon')),
    );
  }

  void _showAddWorkoutDialog(int dayIndex, List<WorkoutPlanModel> availablePlans) {
    if (availablePlans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a workout plan first')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Workout to ${_getDayName(dayIndex)}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availablePlans.length,
            itemBuilder: (context, index) {
              final plan = availablePlans[index];
              return ListTile(
                title: Text(plan.title),
                subtitle: Text('${plan.exercises.length} exercises'),
                onTap: () {
                  Navigator.pop(context);
                  _addScheduledWorkout(dayIndex, plan);
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

  String _getDayName(int dayIndex) {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[dayIndex];
  }

  void _addScheduledWorkout(int dayIndex, WorkoutPlanModel plan) {
    final scheduledWorkout = ScheduledWorkoutModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      planId: plan.id,
      planTitle: plan.title,
      dayOfWeek: dayIndex,
      createdAt: DateTime.now(),
    );

    context.read<WorkoutPlansBloc>().add(AddScheduledWorkout(scheduledWorkout));
  }

  void _removeScheduledWorkout(String scheduledWorkoutId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Workout'),
        content: const Text('Are you sure you want to remove this workout from your schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<WorkoutPlansBloc>().add(RemoveScheduledWorkout(scheduledWorkoutId));
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _viewPlan(String planId) {
    Navigator.pushNamed(context, '/workout_plan_viewer', arguments: planId);
  }

  Widget _buildRecentSessions() {
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
            child: ListTile(
              leading: const Icon(Icons.error, color: Colors.red),
              title: const Text('Error loading sessions'),
              subtitle: Text(state.message),
            ),
          );
        }
        
        final loaded = state as WorkoutPlansLoaded;
        final recentSessions = loaded.sessions.take(3).toList();
        
        if (recentSessions.isEmpty) {
          return _placeholderListTile('No workout sessions yet');
        }
        
        return Column(
          children: recentSessions.map((session) => _buildSessionCard(session)).toList(),
        );
      },
    );
  }

  Widget _buildSessionCard(WorkoutSessionModel session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.fitness_center, color: Colors.blue, size: 20),
        ),
        title: Text(
          session.planTitle ?? 'Quick Session',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${session.exercises.length} exercises • ${_formatDuration(session.sessionDuration)}'),
            if (session.endedAt != null)
              Text(
                'Completed ${_formatDate(session.endedAt!)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => _viewSessionDetails(session),
      ),
    );
  }

  void _viewSessionDetails(WorkoutSessionModel session) {
    Navigator.pushNamed(context, '/workout_session_details', arguments: session);
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
      return 'Today';
    } else if (sessionDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}


