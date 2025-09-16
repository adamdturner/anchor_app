import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/data/models/book_model.dart';
import '/logic/trackers/book_tracker_bloc/book_tracker_bloc.dart';
import '/logic/trackers/book_tracker_bloc/book_tracker_event.dart';

class StartReadingDialog extends StatefulWidget {
  final BookModel book;

  const StartReadingDialog({super.key, required this.book});

  @override
  State<StartReadingDialog> createState() => _StartReadingDialogState();
}

class _StartReadingDialogState extends State<StartReadingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _totalPagesController = TextEditingController();
  DateTime? _goalEndDate;

  @override
  void dispose() {
    _totalPagesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Prefill total pages if known (e.g., provided when added to wishlist)
    if (_totalPagesController.text.isEmpty && widget.book.totalPages > 0) {
      _totalPagesController.text = widget.book.totalPages.toString();
    }
    return AlertDialog(
      title: Text('Start Reading "${widget.book.title}"'),
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
              const SizedBox(height: 24),
              TextFormField(
                controller: _totalPagesController,
                decoration: const InputDecoration(
                  labelText: 'Total Pages *',
                  hintText: 'Enter total number of pages',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Total pages is required';
                  }
                  final pages = int.tryParse(value.trim());
                  if (pages == null || pages <= 0) {
                    return 'Please enter a valid number of pages';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Goal End Date *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectGoalDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _goalEndDate != null
                        ? '${_goalEndDate!.day}/${_goalEndDate!.month}/${_goalEndDate!.year}'
                        : 'Select goal end date',
                    style: TextStyle(
                      color: _goalEndDate != null ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              if (_goalEndDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Reading goal: ${_calculateDailyPages()} pages per day',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
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
          onPressed: _startReading,
          child: const Text('Start Reading'),
        ),
      ],
    );
  }

  void _selectGoalDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _goalEndDate = date;
      });
    }
  }

  int _calculateDailyPages() {
    if (_goalEndDate == null) return 0;
    
    final totalPages = int.tryParse(_totalPagesController.text.trim()) ?? 0;
    final daysRemaining = _goalEndDate!.difference(DateTime.now()).inDays;
    
    if (daysRemaining <= 0) return totalPages;
    
    return (totalPages / daysRemaining).ceil();
  }

  void _startReading() {
    if (_formKey.currentState!.validate() && _goalEndDate != null) {
      final totalPages = int.parse(_totalPagesController.text.trim());
      
      context.read<BookTrackerBloc>().add(StartReading(
        bookId: widget.book.id,
        totalPages: totalPages,
        goalEndDate: _goalEndDate!,
      ));
      
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Started reading! Happy reading! 📚'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (_goalEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a goal end date'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
