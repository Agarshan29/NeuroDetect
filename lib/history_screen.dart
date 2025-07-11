import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'database_helper.dart';
import 'scan_result.dart';
import 'scan_detail_screen.dart'; // Will create next

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<ScanResult>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = DatabaseHelper().getAllScans();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan History"),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: FutureBuilder<List<ScanResult>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          else if (snapshot.hasError) {
            return Center(child: Text("Error loading history: ${snapshot.error}"));
          }
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 70, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No scan history found.", style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }
          else {
            final history = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final scan = history[index];
                final imageFile = File(scan.imagePath);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    leading: SizedBox(
                      width: 50, height: 50,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: FutureBuilder<bool>(
                          future: imageFile.exists(),
                          builder: (context, fileSnapshot) {
                            if (fileSnapshot.connectionState == ConnectionState.done && fileSnapshot.data == true) {
                              return Image.file(imageFile, fit: BoxFit.cover, errorBuilder: (c,e,s)=> const Icon(Icons.broken_image));
                            }
                            return Container(color: Colors.grey[300], child: const Icon(Icons.image_not_supported, size: 30, color: Colors.white));
                          },
                        ),
                      ),
                    ),
                    title: Text(
                      scan.diagnosis == 'notumor' ? 'No Tumor Detected' : scan.diagnosis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(DateFormat.yMMMd().add_jm().format(scan.timestamp)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ScanDetailScreen(scanResult: scan),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}