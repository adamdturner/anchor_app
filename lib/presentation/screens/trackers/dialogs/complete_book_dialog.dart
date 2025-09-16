import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/data/models/book_model.dart';
import '/logic/trackers/book_tracker_bloc/book_tracker_bloc.dart';
import '/logic/trackers/book_tracker_bloc/book_tracker_event.dart';

class CompleteBookDialog extends StatefulWidget {
  final BookModel book;

  const CompleteBookDialog({super.key, required this.book});

  @override
  State<CompleteBookDialog> createState() => _CompleteBookDialogState();
}

class _CompleteBookDialogState extends State<CompleteBookDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  double _rating = 0.0;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Complete "${widget.book.title}"'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Author: ${widget.book.author}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              
              // Reading stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reading Statistics',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Pages Read: ${widget.book.totalPages}'),
                    Text('Progress: ${widget.book.progressPercentage.toStringAsFixed(1)}%'),
                    if (widget.book.readingDuration != null)
                      Text('Reading Time: ${_formatDuration(widget.book.readingDuration!)}'),
                    Text('Reading Sessions: ${widget.book.readingSessions.length}'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Rating
              const Text(
                'Rate this book (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        _rating = (index + 1).toDouble();
                      });
                    },
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
              if (_rating > 0)
                Text(
                  'Rating: ${_rating.toStringAsFixed(1)}/5.0',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              const SizedBox(height: 16),
              
              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Final Notes (Optional)',
                  hintText: 'Share your thoughts about this book',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _completeBook,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Complete Book'),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    
    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  void _completeBook() {
    context.read<BookTrackerBloc>().add(CompleteBook(
      bookId: widget.book.id,
      rating: _rating > 0 ? _rating : null,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    ));
    
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Congratulations! You completed "${widget.book.title}"! 🎉'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
