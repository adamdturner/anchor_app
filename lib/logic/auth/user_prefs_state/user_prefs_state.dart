
import 'package:hydrated_bloc/hydrated_bloc.dart';

class UserPrefsState {
  final String role;
  final String firstName;
  final String lastName;

  UserPrefsState({
    required this.role,
    required this.firstName,
    required this.lastName,
  });

  Map<String, dynamic> toMap() => {
        'role': role,
        'firstName': firstName,
        'lastName': lastName,
      };

  static UserPrefsState fromMap(Map<String, dynamic> map) => UserPrefsState(
        role: map['role'] ?? '',
        firstName: map['firstName'] ?? '',
        lastName: map['lastName'] ?? '',
      );
}


class UserPrefsCubit extends HydratedCubit<UserPrefsState> {
  UserPrefsCubit()
      : super(UserPrefsState(role: '', firstName: '', lastName: ''));

  void updatePrefs({
    required String role,
    required String firstName,
    required String lastName,
  }) {
    emit(UserPrefsState(
      role: role,
      firstName: firstName,
      lastName: lastName,
    ));
  }

  @override
  Map<String, dynamic>? toJson(UserPrefsState state) => state.toMap();

  @override
  UserPrefsState? fromJson(Map<String, dynamic> json) =>
      UserPrefsState.fromMap(json);
}
