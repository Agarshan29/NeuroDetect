import 'package:flutter/material.dart';

class ReportDisplayWidget extends StatelessWidget {
  final Map<String, dynamic> diagnosisDetails;
  final String title;

  const ReportDisplayWidget({
    Key? key,
    required this.diagnosisDetails,
    this.title = "Clinical Report:", // Default title
  }) : super(key: key);

  String _formatTitle(String key) {
    if (key.isEmpty) return '';
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }


  Widget _buildReportItem(BuildContext context, String title, dynamic value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,

            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.primaryColorDark,
            ) ?? const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            value is List ? value.join(", ") : value.toString(),
            style: theme.textTheme.bodyLarge ?? const TextStyle(fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: theme.cardTheme.elevation ?? 3,
      shape: theme.cardTheme.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: theme.cardTheme.margin ?? const EdgeInsets.symmetric(vertical: 8.0),
      clipBehavior: theme.cardTheme.clipBehavior ?? Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.primaryColor, // Example: Use primary color
              ) ?? const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            if (diagnosisDetails.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: Text("No specific details available.", style: TextStyle(color: Colors.grey[600]))),
              )
            else
              ...diagnosisDetails.entries.map(
                    (entry) => _buildReportItem(
                  context,
                  _formatTitle(entry.key),
                  entry.value,
                ),
              ),
          ],
        ),
      ),
    );
  }
}