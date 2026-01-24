import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A compact date picker chip that shows relative dates and opens a date picker
class DatePickerChip extends StatelessWidget {
  const DatePickerChip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.width = 120,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final double width;

  String _getDateLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final selected =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    if (selected == today) {
      return 'Today';
    } else if (selected == yesterday) {
      return 'Yesterday';
    } else {
      // Short format: "Jan 24"
      return DateFormat('MMM d').format(selectedDate);
    }
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select transaction date',
    );

    if (picked != null && picked != selectedDate) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    return Semantics(
      label: 'Transaction date',
      hint: 'Tap to change date',
      value: DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
      button: true,
      child: SizedBox(
        width: width,
        height: 56,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showDatePicker(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      isToday ? theme.colorScheme.primary : theme.dividerColor,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: isToday
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _getDateLabel(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isToday
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
