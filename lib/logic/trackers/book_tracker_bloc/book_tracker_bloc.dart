import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/data/models/book_model.dart';
import '/data/repositories/book_repository.dart';
import 'book_tracker_event.dart';
import 'book_tracker_state.dart';

class BookTrackerBloc extends Bloc<BookTrackerEvent, BookTrackerState> {
  final BookRepository _bookRepository;
  StreamSubscription<List<BookModel>>? _booksSubscription;

  BookTrackerBloc(this._bookRepository) : super(BookTrackerInitial()) {
    on<LoadBooks>(_onLoadBooks);
    on<AddBook>(_onAddBook);
    on<UpdateBook>(_onUpdateBook);
    on<DeleteBook>(_onDeleteBook);
    on<StartReading>(_onStartReading);
    on<UpdateProgress>(_onUpdateProgress);
    on<CompleteBook>(_onCompleteBook);
    on<BooksLoadedFromStream>(_onBooksLoadedFromStream);
    on<BooksLoadError>(_onBooksLoadError);
  }

  Future<void> _onLoadBooks(LoadBooks event, Emitter<BookTrackerState> emit) async {
    emit(BookTrackerLoading());
    
    try {
      // Cancel existing subscription if any
      await _booksSubscription?.cancel();
      
      _booksSubscription = _bookRepository.getBooksStream().listen(
        (books) {
          if (!isClosed) {
            add(BooksLoadedFromStream(books));
          }
        },
        onError: (error) {
          if (!isClosed) {
            add(BooksLoadError(error.toString()));
          }
        },
      );
    } catch (e) {
      emit(BookTrackerError('Failed to load books: $e'));
    }
  }

  Future<void> _onAddBook(AddBook event, Emitter<BookTrackerState> emit) async {
    try {
      await _bookRepository.addBook(event.book);
      // State will be updated through the stream
    } catch (e) {
      emit(BookTrackerError('Failed to add book: $e'));
    }
  }

  Future<void> _onUpdateBook(UpdateBook event, Emitter<BookTrackerState> emit) async {
    try {
      await _bookRepository.updateBook(event.book);
      // State will be updated through the stream
    } catch (e) {
      emit(BookTrackerError('Failed to update book: $e'));
    }
  }

  Future<void> _onDeleteBook(DeleteBook event, Emitter<BookTrackerState> emit) async {
    try {
      await _bookRepository.deleteBook(event.bookId);
      // State will be updated through the stream
    } catch (e) {
      emit(BookTrackerError('Failed to delete book: $e'));
    }
  }

  Future<void> _onStartReading(StartReading event, Emitter<BookTrackerState> emit) async {
    try {
      await _bookRepository.startReading(
        event.bookId,
        event.totalPages,
        event.goalEndDate,
      );
      // State will be updated through the stream
    } catch (e) {
      emit(BookTrackerError('Failed to start reading: $e'));
    }
  }

  Future<void> _onUpdateProgress(UpdateProgress event, Emitter<BookTrackerState> emit) async {
    try {
      await _bookRepository.updateProgress(
        event.bookId,
        event.currentPage,
        event.session,
      );
      // State will be updated through the stream
    } catch (e) {
      emit(BookTrackerError('Failed to update progress: $e'));
    }
  }

  Future<void> _onCompleteBook(CompleteBook event, Emitter<BookTrackerState> emit) async {
    try {
      await _bookRepository.completeBook(
        event.bookId,
        event.rating,
        event.notes,
      );
      // State will be updated through the stream
    } catch (e) {
      emit(BookTrackerError('Failed to complete book: $e'));
    }
  }

  void _onBooksLoadedFromStream(BooksLoadedFromStream event, Emitter<BookTrackerState> emit) {
    emit(BookTrackerLoaded(event.books));
  }

  void _onBooksLoadError(BooksLoadError event, Emitter<BookTrackerState> emit) {
    emit(BookTrackerError('Failed to load books: ${event.error}'));
  }

  @override
  Future<void> close() {
    _booksSubscription?.cancel();
    return super.close();
  }
}
