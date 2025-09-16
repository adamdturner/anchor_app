import 'package:flutter/material.dart';

class TrackersScreen extends StatelessWidget {
  const TrackersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trackers'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            const Text(
              'Personal Goal Trackers',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Track your progress on various personal goals and habits.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            
            // Active trackers section
            const Text(
              'Active Trackers',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Active trackers list
            Expanded(
              child: ListView(
                children: [
                  _buildTrackerCard(
                    context,
                    'Book Reading Tracker',
                    'Track your reading progress, pages per day, and books completed',
                    Icons.menu_book,
                    Colors.blue,
                    () => Navigator.pushNamed(context, '/book_tracker'),
                  ),
                  const SizedBox(height: 16),
                  _buildTrackerCard(
                    context,
                    'Workout Tracker',
                    'Log your exercises, reps, sets, and workout progress',
                    Icons.fitness_center,
                    Colors.green,
                    () => Navigator.pushNamed(context, '/workout_tracker'),
                  ),
                  const SizedBox(height: 16),
                  _buildTrackerCard(
                    context,
                    'Habit Tracker',
                    'Track daily habits and build consistency',
                    Icons.check_circle,
                    Colors.orange,
                    () => _showComingSoon(context, 'Habit Tracker'),
                  ),
                  const SizedBox(height: 16),
                  _buildTrackerCard(
                    context,
                    'Learning Tracker',
                    'Track courses, skills, and learning progress',
                    Icons.school,
                    Colors.purple,
                    () => _showComingSoon(context, 'Learning Tracker'),
                  ),
                  const SizedBox(height: 16),
                  _buildTrackerCard(
                    context,
                    'Finance Tracker',
                    'Monitor expenses, savings, and financial goals',
                    Icons.account_balance_wallet,
                    Colors.teal,
                    () => _showComingSoon(context, 'Finance Tracker'),
                  ),
                  const SizedBox(height: 16),
                  _buildTrackerCard(
                    context,
                    'Health Tracker',
                    'Track sleep, water intake, and health metrics',
                    Icons.health_and_safety,
                    Colors.red,
                    () => _showComingSoon(context, 'Health Tracker'),
                  ),
                ],
              ),
            ),
            
            // Add new tracker button
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAddTrackerDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add New Tracker'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackerCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTrackerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Tracker'),
          content: const Text(
            'Choose the type of tracker you\'d like to create:',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showComingSoon(context, 'Custom Tracker Creation');
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
