import 'package:cloud_firestore/cloud_firestore.dart';

enum BookStatus {
  wishlist,
  inProgress,
  completed,
}

class BookModel {
  final String id;
  final String title;
  final String author;
  final String? isbn;
  final String? description;
  final String? coverImageUrl;
  final int totalPages;
  final BookStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? goalEndDate;
  final int currentPage;
  final List<ReadingSession> readingSessions;
  final double? rating;
  final String? notes;

  const BookModel({
    required this.id,
    required this.title,
    required this.author,
    this.isbn,
    this.description,
    this.coverImageUrl,
    required this.totalPages,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.startDate,
    this.endDate,
    this.goalEndDate,
    this.currentPage = 0,
    this.readingSessions = const [],
    this.rating,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'isbn': isbn,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'totalPages': totalPages,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'goalEndDate': goalEndDate != null ? Timestamp.fromDate(goalEndDate!) : null,
      'currentPage': currentPage,
      'readingSessions': readingSessions.map((session) => session.toJson()).toList(),
      'rating': rating,
      'notes': notes,
    };
  }

  factory BookModel.fromJson(Map<String, dynamic> json, String id) {
    return BookModel(
      id: id,
      title: json['title'] as String,
      author: json['author'] as String,
      isbn: json['isbn'] as String?,
      description: json['description'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      totalPages: json['totalPages'] as int,
      status: BookStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookStatus.wishlist,
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null ? (json['updatedAt'] as Timestamp).toDate() : null,
      startDate: json['startDate'] != null ? (json['startDate'] as Timestamp).toDate() : null,
      endDate: json['endDate'] != null ? (json['endDate'] as Timestamp).toDate() : null,
      goalEndDate: json['goalEndDate'] != null ? (json['goalEndDate'] as Timestamp).toDate() : null,
      currentPage: json['currentPage'] as int? ?? 0,
      readingSessions: (json['readingSessions'] as List<dynamic>?)
          ?.map((session) => ReadingSession.fromJson(session))
          .toList() ?? [],
      rating: (json['rating'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }

  BookModel copyWith({
    String? id,
    String? title,
    String? author,
    String? isbn,
    String? description,
    String? coverImageUrl,
    int? totalPages,
    BookStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? goalEndDate,
    int? currentPage,
    List<ReadingSession>? readingSessions,
    double? rating,
    String? notes,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      isbn: isbn ?? this.isbn,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      totalPages: totalPages ?? this.totalPages,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      goalEndDate: goalEndDate ?? this.goalEndDate,
      currentPage: currentPage ?? this.currentPage,
      readingSessions: readingSessions ?? this.readingSessions,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
    );
  }

  // Helper methods
  double get progressPercentage {
    if (totalPages == 0) return 0.0;
    return (currentPage / totalPages * 100).clamp(0.0, 100.0);
  }

  int get pagesRemaining {
    return (totalPages - currentPage).clamp(0, totalPages);
  }

  bool get isCompleted {
    return status == BookStatus.completed;
  }

  bool get isInProgress {
    return status == BookStatus.inProgress;
  }

  bool get isInWishlist {
    return status == BookStatus.wishlist;
  }

  int get totalPagesRead {
    return readingSessions.fold(0, (sum, session) => sum + session.pagesRead);
  }

  Duration? get readingDuration {
    if (startDate == null) return null;
    final end = endDate ?? DateTime.now();
    return end.difference(startDate!);
  }
}

class ReadingSession {
  final String id;
  final DateTime date;
  final int pagesRead;
  final Duration? duration;
  final String? notes;

  const ReadingSession({
    required this.id,
    required this.date,
    required this.pagesRead,
    this.duration,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'pagesRead': pagesRead,
      'duration': duration?.inMinutes,
      'notes': notes,
    };
  }

  factory ReadingSession.fromJson(Map<String, dynamic> json) {
    return ReadingSession(
      id: json['id'] as String,
      date: (json['date'] as Timestamp).toDate(),
      pagesRead: json['pagesRead'] as int,
      duration: json['duration'] != null 
          ? Duration(minutes: json['duration'] as int)
          : null,
      notes: json['notes'] as String?,
    );
  }
}
