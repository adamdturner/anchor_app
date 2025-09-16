import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/book_model.dart';

class BookRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  BookRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  Future<String> get _booksCollection async {
    if (_userId.isEmpty) return '';
    
    try {
      // Get user role from users-index collection
      final userDoc = await _firestore.collection('users-index').doc(_userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found in index');
      }
      
      final userData = userDoc.data()!;
      final role = userData['role'] as String?;
      
      if (role == 'admin') {
        return 'users-admin/$_userId/books';
      } else if (role == 'consumer') {
        return 'users-consumer/$_userId/books';
      } else {
        throw Exception('Unknown user role: $role');
      }
    } catch (e) {
      throw Exception('Failed to determine user collection: $e');
    }
  }

  // Get books stream
  Stream<List<BookModel>> getBooksStream() {
    return Stream.fromFuture(_booksCollection).asyncExpand((collectionPath) {
      return _firestore
          .collection(collectionPath)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => BookModel.fromJson(doc.data(), doc.id))
            .toList();
      });
    });
  }

  // Add a new book
  Future<void> addBook(BookModel book) async {
    try {
      final collectionPath = await _booksCollection;
      await _firestore
          .collection(collectionPath)
          .doc(book.id)
          .set(book.toJson());
    } catch (e) {
      throw Exception('Failed to add book: $e');
    }
  }

  // Update a book
  Future<void> updateBook(BookModel book) async {
    try {
      final collectionPath = await _booksCollection;
      final updatedBook = book.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection(collectionPath)
          .doc(book.id)
          .update(updatedBook.toJson());
    } catch (e) {
      throw Exception('Failed to update book: $e');
    }
  }

  // Delete a book
  Future<void> deleteBook(String bookId) async {
    try {
      final collectionPath = await _booksCollection;
      await _firestore
          .collection(collectionPath)
          .doc(bookId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete book: $e');
    }
  }

  // Start reading a book
  Future<void> startReading(
    String bookId,
    int totalPages,
    DateTime goalEndDate,
  ) async {
    try {
      final collectionPath = await _booksCollection;
      final now = DateTime.now();
      await _firestore
          .collection(collectionPath)
          .doc(bookId)
          .update({
        'status': BookStatus.inProgress.name,
        'totalPages': totalPages,
        'startDate': Timestamp.fromDate(now),
        'goalEndDate': Timestamp.fromDate(goalEndDate),
        'currentPage': 0,
        'updatedAt': Timestamp.fromDate(now),
      });
    } catch (e) {
      throw Exception('Failed to start reading: $e');
    }
  }

  // Update reading progress
  Future<void> updateProgress(
    String bookId,
    int currentPage,
    ReadingSession? session,
  ) async {
    try {
      final collectionPath = await _booksCollection;
      final now = DateTime.now();
      final docRef = _firestore.collection(collectionPath).doc(bookId);
      
      // Get current book data
      final doc = await docRef.get();
      if (!doc.exists) {
        throw Exception('Book not found');
      }

      final bookData = doc.data()!;
      final List<dynamic> sessions = bookData['readingSessions'] ?? [];
      
      // Add new session if provided
      if (session != null) {
        sessions.add(session.toJson());
      }

      // Update book
      await docRef.update({
        'currentPage': currentPage,
        'readingSessions': sessions,
        'updatedAt': Timestamp.fromDate(now),
      });
    } catch (e) {
      throw Exception('Failed to update progress: $e');
    }
  }

  // Complete a book
  Future<void> completeBook(
    String bookId,
    double? rating,
    String? notes,
  ) async {
    try {
      final collectionPath = await _booksCollection;
      final now = DateTime.now();
      await _firestore
          .collection(collectionPath)
          .doc(bookId)
          .update({
        'status': BookStatus.completed.name,
        'endDate': Timestamp.fromDate(now),
        'rating': rating,
        'notes': notes,
        'updatedAt': Timestamp.fromDate(now),
      });
    } catch (e) {
      throw Exception('Failed to complete book: $e');
    }
  }

  // Get books by status
  Future<List<BookModel>> getBooksByStatus(BookStatus status) async {
    try {
      final collectionPath = await _booksCollection;
      final snapshot = await _firestore
          .collection(collectionPath)
          .where('status', isEqualTo: status.name)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BookModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get books by status: $e');
    }
  }

  // Get reading statistics
  Future<Map<String, dynamic>> getReadingStats() async {
    try {
      final collectionPath = await _booksCollection;
      final snapshot = await _firestore
          .collection(collectionPath)
          .get();

      final books = snapshot.docs
          .map((doc) => BookModel.fromJson(doc.data(), doc.id))
          .toList();

      final completedBooks = books.where((book) => book.isCompleted).toList();
      final inProgressBooks = books.where((book) => book.isInProgress).toList();
      final wishlistBooks = books.where((book) => book.isInWishlist).toList();

      final totalPagesRead = completedBooks.fold<int>(
        0,
        (sum, book) => sum + book.totalPages,
      );

      final totalReadingTime = completedBooks.fold<Duration>(
        Duration.zero,
        (sum, book) => sum + (book.readingDuration ?? Duration.zero),
      );

      return {
        'totalBooks': books.length,
        'completedBooks': completedBooks.length,
        'inProgressBooks': inProgressBooks.length,
        'wishlistBooks': wishlistBooks.length,
        'totalPagesRead': totalPagesRead,
        'totalReadingTime': totalReadingTime,
        'averageRating': completedBooks
            .where((book) => book.rating != null)
            .map((book) => book.rating!)
            .fold<double>(0.0, (sum, rating) => sum + rating) /
            completedBooks.where((book) => book.rating != null).length,
      };
    } catch (e) {
      throw Exception('Failed to get reading stats: $e');
    }
  }
}
