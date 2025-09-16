import '/data/models/book_model.dart';

abstract class BookTrackerState {}

class BookTrackerInitial extends BookTrackerState {}

class BookTrackerLoading extends BookTrackerState {}

class BookTrackerLoaded extends BookTrackerState {
  final List<BookModel> books;

  BookTrackerLoaded(this.books);
}

class BookTrackerError extends BookTrackerState {
  final String message;

  BookTrackerError(this.message);
}

class BookTrackerSuccess extends BookTrackerState {
  final String message;

  BookTrackerSuccess(this.message);
}
