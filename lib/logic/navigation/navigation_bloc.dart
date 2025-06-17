import 'package:flutter_bloc/flutter_bloc.dart';
import 'navigation_event.dart';
import 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(NavigationState(currentPageIndex: 0)) {
    on<SelectPageEvent>((event, emit) {
      emit(
        state.copyWith(
          currentPageIndex: event.index,
        ),
      );
    });
  }
}