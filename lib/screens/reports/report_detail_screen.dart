import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/api_constants.dart';
import '../../../models/report_model.dart';

class ReportDetailScreen extends StatelessWidget {
  final Report report;

  const ReportDetailScreen({super.key, required this.report});

  Future<void> _downloadReport() async {
    if (report.file != null) {
      final Uri url = Uri.parse('${ApiConstants.baseUrl}${report.file}');
      final canLaunch = await canLaunchUrl(url);
      if (canLaunch) {
        await launchUrl(url);
      } else {
        throw 'Could not launch $url';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(report.title),
        actions: [
          if (report.file != null)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _downloadReport,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          report.getReportTypeDisplay(),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: report.isPublic
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            report.isPublic ? 'Public' : 'Private',
                            style: TextStyle(
                              color: report.isPublic
                                  ? Colors.green
                                  : Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(report.description),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          '${report.generatedBy.firstName} ${report.generatedBy.lastName}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          '${report.generatedAt.day}/${report.generatedAt.month}/${report.generatedAt.year}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Report Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (report.dataSummary.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No summary data available'),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: report.dataSummary.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                '${entry.key}:',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(entry.value.toString()),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'Filters Applied',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (report.filters.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No filters applied'),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: report.filters.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                '${entry.key}:',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(entry.value.toString()),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            if (report.file != null)
              Center(
                child: ElevatedButton.icon(
                  onPressed: _downloadReport,
                  icon: const Icon(Icons.download),
                  label: const Text('Download Report'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}