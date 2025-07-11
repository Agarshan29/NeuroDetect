import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:neuro_detect_v2/report_expoter.dart';
import 'scan_result.dart';
import 'report_display.dart';

class ScanDetailScreen extends StatefulWidget {
  final ScanResult scanResult;

  const ScanDetailScreen({Key? key, required this.scanResult}) : super(key: key);

  @override
  _ScanDetailScreenState createState() => _ScanDetailScreenState();
}

class _ScanDetailScreenState extends State<ScanDetailScreen> {
  bool _isExporting = false;


  Future<void> _exportAndShare() async {
    setState(() => _isExporting = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final pdfFile = await ReportExporter.generatePdf(widget.scanResult);
      if (pdfFile != null && mounted) {
        await ReportExporter.sharePdf(pdfFile, context);
      } else if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Failed to generate PDF report.')),
        );
      }
    } catch (e) {
      print("Export Error: $e");
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Could not export report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final imageFile = File(widget.scanResult.imagePath);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Details"),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Icon(Icons.share),
            tooltip: "Export & Share Report",
            onPressed: _isExporting ? null : _exportAndShare,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Preview
            Card(
              clipBehavior: Clip.antiAlias,
              child: FutureBuilder<bool>(
                future: imageFile.exists(),
                builder: (context, fileSnapshot) {
                  if (fileSnapshot.connectionState == ConnectionState.done && fileSnapshot.data == true) {
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.35),
                      child: Image.file(imageFile, fit: BoxFit.contain),
                    );
                  }
                  return Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(child: Text("Image not found or loading...", style: TextStyle(color: Colors.grey)))
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Basic Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Diagnosis:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey)),
                    Text(
                      widget.scanResult.diagnosis == 'notumor' ? 'No Tumor Detected' : widget.scanResult.diagnosis,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text("Analyzed On:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey)),
                    Text(DateFormat.yMMMd().add_jms().format(widget.scanResult.timestamp)),

                    if (widget.scanResult.probabilities != null && widget.scanResult.probabilities!.isNotEmpty && widget.scanResult.probabilities!.length == kClassLabels.length) ...[
                      const SizedBox(height: 12),
                      const Text("Model Confidence:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey)),
                      const SizedBox(height: 4),
                      for(int i=0; i < widget.scanResult.probabilities!.length; ++i)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                          child: Text("${kClassLabels[i]}: ${(widget.scanResult.probabilities![i] * 100).toStringAsFixed(1)}%"),
                        ),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            ReportDisplayWidget(diagnosisDetails: widget.scanResult.reportDetails),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                ReportExporter.disclaimer, // Use the static disclaimer
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}