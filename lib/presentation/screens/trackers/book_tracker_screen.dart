import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/data/models/book_model.dart';
import '/logic/trackers/book_tracker_bloc/book_tracker_bloc.dart';
import '/logic/trackers/book_tracker_bloc/book_tracker_event.dart';
import '/logic/trackers/book_tracker_bloc/book_tracker_state.dart';
import 'dialogs/add_book_dialog.dart';
import 'dialogs/start_reading_dialog.dart';
import 'dialogs/update_progress_dialog.dart';
import 'dialogs/complete_book_dialog.dart';
import 'dialogs/edit_book_dialog.dart';
import 'dialogs/delete_book_dialog.dart';
import 'dialogs/add_and_start_dialog.dart';

class BookTrackerScreen extends StatefulWidget {
  const BookTrackerScreen({super.key});

  @override
  State<BookTrackerScreen> createState() => _BookTrackerScreenState();
}

class _BookTrackerScreenState extends State<BookTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load books when screen initializes
    context.read<BookTrackerBloc>().add(LoadBooks());
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
        title: const Text('Book Reading Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.book),
              text: 'In Progress',
            ),
            Tab(
              icon: Icon(Icons.check_circle),
              text: 'Completed',
            ),
            Tab(
              icon: Icon(Icons.bookmark),
              text: 'Wishlist',
            ),
          ],
        ),
      ),
      body: BlocBuilder<BookTrackerBloc, BookTrackerState>(
        builder: (context, state) {
          if (state is BookTrackerLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BookTrackerLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildInProgressTab(context, state.books),
                _buildCompletedTab(context, state.books),
                _buildWishlistTab(context, state.books),
              ],
            );
          }

          if (state is BookTrackerError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<BookTrackerBloc>().add(LoadBooks());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('No data available'));
        },
      ),
      floatingActionButton: BlocBuilder<BookTrackerBloc, BookTrackerState>(
        builder: (context, state) {
          return FloatingActionButton(
            onPressed: () {
              if (state is BookTrackerLoaded && _tabController.index == 0) {
                final wishlistBooks = state.books.where((b) => b.isInWishlist).toList();
                _showStartFromPicker(context, wishlistBooks);
              } else {
                _showAddBookDialog(context);
              }
            },
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildInProgressTab(BuildContext context, List<BookModel> books) {
    final inProgressBooks = books.where((book) => book.isInProgress).toList();

    if (inProgressBooks.isEmpty) {
      return _buildEmptyState(
        context,
        'No books in progress',
        'Start reading a book from your wishlist or add a new one!',
        Icons.book,
        () {
          final wishlistBooks = books.where((b) => b.isInWishlist).toList();
          _showStartFromPicker(context, wishlistBooks);
        },
        'Start Reading',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: inProgressBooks.length,
      itemBuilder: (context, index) {
        final book = inProgressBooks[index];
        return _buildBookCard(context, book, true);
      },
    );
  }

  Widget _buildCompletedTab(BuildContext context, List<BookModel> books) {
    final completedBooks = books.where((book) => book.isCompleted).toList();

    if (completedBooks.isEmpty) {
      return _buildEmptyState(
        context,
        'No completed books',
        'Finish reading some books to see them here!',
        Icons.check_circle,
        null,
        null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completedBooks.length,
      itemBuilder: (context, index) {
        final book = completedBooks[index];
        return _buildBookCard(context, book, false);
      },
    );
  }

  Widget _buildWishlistTab(BuildContext context, List<BookModel> books) {
    final wishlistBooks = books.where((book) => book.isInWishlist).toList();

    if (wishlistBooks.isEmpty) {
      return _buildEmptyState(
        context,
        'No books in wishlist',
        'Add books you want to read in the future!',
        Icons.bookmark,
        () => _showAddBookDialog(context),
        'Add Book',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: wishlistBooks.length,
      itemBuilder: (context, index) {
        final book = wishlistBooks[index];
        return _buildWishlistBookCard(context, book);
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onPressed,
    String? buttonText,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (onPressed != null && buttonText != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.add),
                label: Text(buttonText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookCard(BuildContext context, BookModel book, bool isInProgress) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Book cover placeholder
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.book, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.author,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (isInProgress) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Page ${book.currentPage} of ${book.totalPages}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: book.progressPercentage / 100,
                          backgroundColor: Colors.grey[300],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${book.progressPercentage.toStringAsFixed(1)}% complete',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleBookAction(context, book, value),
                  itemBuilder: (context) => [
                    if (isInProgress) ...[
                      const PopupMenuItem(
                        value: 'update_progress',
                        child: Text('Update Progress'),
                      ),
                      const PopupMenuItem(
                        value: 'complete',
                        child: Text('Mark as Complete'),
                      ),
                    ],
                    if (book.isInWishlist) ...[
                      const PopupMenuItem(
                        value: 'start_reading',
                        child: Text('Start Reading'),
                      ),
                    ],
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistBookCard(BuildContext context, BookModel book) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.book, size: 24),
        ),
        title: Text(
          book.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(book.author),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleBookAction(context, book, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'start_reading',
              child: Text('Start Reading'),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBookAction(BuildContext context, BookModel book, String action) {
    switch (action) {
      case 'start_reading':
        _showStartReadingDialog(context, book);
        break;
      case 'update_progress':
        _showUpdateProgressDialog(context, book);
        break;
      case 'complete':
        _showCompleteBookDialog(context, book);
        break;
      case 'edit':
        _showEditBookDialog(context, book);
        break;
      case 'delete':
        _showDeleteBookDialog(context, book);
        break;
    }
  }

  void _showAddBookDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddBookDialog(),
    );
  }

  void _showAddAndStartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddAndStartDialog(),
    );
  }

  void _showStartReadingDialog(BuildContext context, BookModel book) {
    showDialog(
      context: context,
      builder: (context) => StartReadingDialog(book: book),
    );
  }

  void _showUpdateProgressDialog(BuildContext context, BookModel book) {
    showDialog(
      context: context,
      builder: (context) => UpdateProgressDialog(book: book),
    );
  }

  void _showCompleteBookDialog(BuildContext context, BookModel book) {
    showDialog(
      context: context,
      builder: (context) => CompleteBookDialog(book: book),
    );
  }

  void _showEditBookDialog(BuildContext context, BookModel book) {
    showDialog(
      context: context,
      builder: (context) => EditBookDialog(book: book),
    );
  }

  void _showDeleteBookDialog(BuildContext context, BookModel book) {
    showDialog(
      context: context,
      builder: (context) => DeleteBookDialog(book: book),
    );
  }

  void _showStartFromPicker(BuildContext context, List<BookModel> wishlistBooks) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Center(
                  child: SizedBox(
                    width: 40,
                    child: Divider(thickness: 4),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Start Reading',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (wishlistBooks.isNotEmpty) ...[
                  const Text(
                    'Pick from wishlist',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: wishlistBooks.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final book = wishlistBooks[index];
                        return ListTile(
                          leading: const Icon(Icons.bookmark),
                          title: Text(book.title),
                          subtitle: Text(book.author),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).pop();
                            _showStartReadingDialog(context, book);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No wishlist books yet. You can add and start a new book.',
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showAddAndStartDialog(context);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add and Start New Book'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
