import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:my_ledger/services/export_service.dart';


/// Screen for exporting transaction data
class ExportDataScreen extends ConsumerStatefulWidget {
  const ExportDataScreen({super.key});

  @override
  ConsumerState<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends ConsumerState<ExportDataScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isExporting = false;

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _setQuickDateRange(String range) {
    final now = DateTime.now();
    DateTime? start;
    DateTime? end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (range) {
      case 'month':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        start = DateTime(now.year, 1, 1);
        break;
      case 'all':
        start = null;
        end = null;
        break;
    }

    setState(() {
      _startDate = start;
      _endDate = end;
    });
  }

  String _getDateRangeText() {
    if (_startDate == null && _endDate == null) {
      return 'All Time';
    }
    final format = DateFormat('MMM d, yyyy');
    if (_startDate != null && _endDate != null) {
      return '${format.format(_startDate!)} - ${format.format(_endDate!)}';
    }
    if (_startDate != null) {
      return 'From ${format.format(_startDate!)}';
    }
    return 'Until ${format.format(_endDate!)}';
  }

  Future<void> _exportAndSave() async {
    setState(() => _isExporting = true);

    try {
      final csvContent = await ExportService.exportTransactionsWithDetails(
        startDate: _startDate,
        endDate: _endDate,
      );

      final filePath = await ExportService.saveCSVToDevice(csvContent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to: $filePath'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () => _exportAndShare(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportAndShare() async {
    setState(() => _isExporting = true);

    try {
      final csvContent = await ExportService.exportTransactionsWithDetails(
        startDate: _startDate,
        endDate: _endDate,
      );

      await ExportService.shareCSV(csvContent);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Transactions',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Export your transaction data to CSV format for backup or analysis.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),

            // Date Range Section
            Text(
              'Date Range',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Quick date range buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('This Month'),
                  selected: false,
                  onSelected: (_) => _setQuickDateRange('month'),
                ),
                FilterChip(
                  label: const Text('This Year'),
                  selected: false,
                  onSelected: (_) => _setQuickDateRange('year'),
                ),
                FilterChip(
                  label: const Text('All Time'),
                  selected: _startDate == null && _endDate == null,
                  onSelected: (_) => _setQuickDateRange('all'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Custom date range
            OutlinedButton.icon(
              onPressed: _selectDateRange,
              icon: const Icon(Icons.calendar_today),
              label: Text(_getDateRangeText()),
            ),

            const SizedBox(height: 32),

            // Export format info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Export Format',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'CSV file will include:\n'
                      '• Date\n'
                      '• Transaction type\n'
                      '• Amount\n'
                      '• Account name\n'
                      '• Category name\n'
                      '• Notes\n'
                      '• Reconciliation status',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Export buttons
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportAndSave,
                icon: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: Text(_isExporting ? 'Exporting...' : 'Save to Device'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _isExporting ? null : _exportAndShare,
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
