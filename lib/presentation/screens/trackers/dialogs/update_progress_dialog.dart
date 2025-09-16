import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/data/models/book_model.dart';
import '/logic/trackers/book_tracker_bloc/book_tracker_bloc.dart';
import '/logic/trackers/book_tracker_bloc/book_tracker_event.dart';

class UpdateProgressDialog extends StatefulWidget {
  final BookModel book;

  const UpdateProgressDialog({super.key, required this.book});

  @override
  State<UpdateProgressDialog> createState() => _UpdateProgressDialogState();
}

class _UpdateProgressDialogState extends State<UpdateProgressDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPageController = TextEditingController();
  final _pagesReadController = TextEditingController();
  final _notesController = TextEditingController();
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentPageController.text = widget.book.currentPage.toString();
  }

  @override
  void dispose() {
    _currentPageController.dispose();
    _pagesReadController.dispose();
    _notesController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update Progress - "${widget.book.title}"'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              Text(
                'Current Progress: ${widget.book.progressPercentage.toStringAsFixed(1)}%',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: widget.book.progressPercentage / 100,
                backgroundColor: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              
              // Current page
              TextFormField(
                controller: _currentPageController,
                decoration: const InputDecoration(
                  labelText: 'Current Page *',
                  hintText: 'Enter current page number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Current page is required';
                  }
                  final page = int.tryParse(value.trim());
                  if (page == null || page < 0 || page > widget.book.totalPages) {
                    return 'Please enter a valid page number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Pages read in this session
              TextFormField(
                controller: _pagesReadController,
                decoration: const InputDecoration(
                  labelText: 'Pages Read Today (Optional)',
                  hintText: 'Enter pages read in this session',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final pages = int.tryParse(value.trim());
                    if (pages == null || pages < 0) {
                      return 'Please enter a valid number of pages';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Reading duration
              const Text(
                'Reading Duration (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hoursController,
                      decoration: const InputDecoration(
                        labelText: 'Hours',
                        hintText: '0',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        final hours = int.tryParse(value.trim());
                        if (hours == null || hours < 0) {
                          return 'Invalid hours';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _minutesController,
                      decoration: const InputDecoration(
                        labelText: 'Minutes',
                        hintText: '0-59',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        final minutes = int.tryParse(value.trim());
                        if (minutes == null || minutes < 0 || minutes > 59) {
                          return '0-59 only';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add notes about this reading session',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
          onPressed: _updateProgress,
          child: const Text('Update Progress'),
        ),
      ],
    );
  }

  Duration? _buildDurationFromInputs() {
    final hours = int.tryParse(_hoursController.text.trim());
    final minutes = int.tryParse(_minutesController.text.trim());
    final h = (hours != null && hours > 0) ? hours : 0;
    final m = (minutes != null && minutes > 0) ? minutes : 0;
    if (h == 0 && m == 0) return null;
    return Duration(hours: h, minutes: m);
  }

  void _updateProgress() {
    if (_formKey.currentState!.validate()) {
      final currentPage = int.parse(_currentPageController.text.trim());
      final pagesRead = int.tryParse(_pagesReadController.text.trim()) ?? 0;
      
      final duration = _buildDurationFromInputs();
      ReadingSession? session;
      if (pagesRead > 0 || duration != null || _notesController.text.trim().isNotEmpty) {
        session = ReadingSession(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: DateTime.now(),
          pagesRead: pagesRead,
          duration: duration,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      }
      
      context.read<BookTrackerBloc>().add(UpdateProgress(
        bookId: widget.book.id,
        currentPage: currentPage,
        session: session,
      ));
      
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Progress updated! Keep reading! 📖'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
