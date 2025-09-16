import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '/routes/app_router.dart';
import 'package:anchor_app/presentation/screens/dashboard/dashboard_screen.dart';
import '/data/repositories/book_repository.dart';
import '/logic/trackers/book_tracker_bloc/book_tracker_bloc.dart';
import '/data/repositories/workout_repository.dart';
import '/logic/trackers/workout_plans_bloc/workout_plans_bloc.dart';
import '/logic/trackers/workout_plans_bloc/workout_plans_event.dart';

class AuthenticatedApp extends StatelessWidget {
  final String uid;
  const AuthenticatedApp({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    // print('[AuthenticatedApp] Entered with UID: $uid');         // debugging
    
    // Create the main app widget
    final mainApp = MaterialApp(
      title: 'Anchor App',
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRouter.authenticatedRoutes,
      home: const DashboardScreen(),
    );

    // Only wrap with providers if there are actual providers to add
    final repositories = <ChangeNotifierProvider>[
      // list any repositories that are used by more than one bloc
      // it's best to just have one instance of each repository
    ];

    final blocs = <BlocProvider>[
      // Book tracker bloc for managing book reading data
      BlocProvider<BookTrackerBloc>(
        create: (_) => BookTrackerBloc(BookRepository()),
      ),
      BlocProvider<WorkoutPlansBloc>(
        create: (_) => WorkoutPlansBloc(WorkoutRepository())..add(LoadWorkoutPlans()),
      ),
    ];

    // If no providers, return the app directly
    if (repositories.isEmpty && blocs.isEmpty) {
      return mainApp;
    }

    // If we have providers, wrap the app
    Widget appWithProviders = mainApp;
    
    // Add BLoC providers if any
    if (blocs.isNotEmpty) {
      appWithProviders = MultiBlocProvider(
        providers: blocs,
        child: appWithProviders,
      );
    }
    
    // Add repository providers if any
    if (repositories.isNotEmpty) {
      appWithProviders = MultiProvider(
        providers: repositories,
        child: appWithProviders,
      );
    }
    
    return appWithProviders;
  }
}
