import '/data/models/book_model.dart';

abstract class BookTrackerEvent {}

class LoadBooks extends BookTrackerEvent {}

class AddBook extends BookTrackerEvent {
  final BookModel book;

  AddBook(this.book);
}

class UpdateBook extends BookTrackerEvent {
  final BookModel book;

  UpdateBook(this.book);
}

class DeleteBook extends BookTrackerEvent {
  final String bookId;

  DeleteBook(this.bookId);
}

class StartReading extends BookTrackerEvent {
  final String bookId;
  final int totalPages;
  final DateTime goalEndDate;

  StartReading({
    required this.bookId,
    required this.totalPages,
    required this.goalEndDate,
  });
}

class UpdateProgress extends BookTrackerEvent {
  final String bookId;
  final int currentPage;
  final ReadingSession? session;

  UpdateProgress({
    required this.bookId,
    required this.currentPage,
    this.session,
  });
}

class CompleteBook extends BookTrackerEvent {
  final String bookId;
  final double? rating;
  final String? notes;

  CompleteBook({
    required this.bookId,
    this.rating,
    this.notes,
  });
}

class BooksLoadedFromStream extends BookTrackerEvent {
  final List<BookModel> books;

  BooksLoadedFromStream(this.books);
}

class BooksLoadError extends BookTrackerEvent {
  final String error;

  BooksLoadError(this.error);
}
