import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'database_helper.dart'; // To clear history

// Define the disclaimer text (or import from a constants file)
const String appDisclaimer =
    "DISCLAIMER: NeuroDetect AI is for informational and educational purposes ONLY. "
    "It is NOT a substitute for professional medical diagnosis, advice, or treatment. "
    "AI model predictions are not guaranteed to be accurate. Always consult a qualified "
    "healthcare provider for any health concerns or before making any decisions related "
    "to your health or treatment. Use this tool responsibly.";


class SettingsScreen extends StatefulWidget {
  final VoidCallback? onHistoryCleared; // Callback when history is cleared

  const SettingsScreen({Key? key, this.onHistoryCleared}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = '${packageInfo.appName} v${packageInfo.version}+${packageInfo.buildNumber}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _appVersion = 'Error loading version'; });
      }
      print("Error loading package info: $e");
    }
  }


  void _showDisclaimerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Disclaimer"),
          content: const SingleChildScrollView(
            child: Text(appDisclaimer),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }


  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Clear History"),
          content: const Text("Are you sure you want to delete all saved scan history? This cannot be undone."),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error), // Use error color
              child: const Text("Clear History"),
              onPressed: () async {
                Navigator.of(context).pop(); // Close confirmation dialog
                await _clearHistory(); // Proceed to clear
              },
            ),
          ],
        );
      },
    );
  }


  Future<void> _clearHistory() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context); // Capture context
    try {
      await DatabaseHelper().deleteAllScans();
      widget.onHistoryCleared?.call(); // Notify listener (optional)
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Scan history has been cleared.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print("Error clearing history: $e");
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error clearing history: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: ListView(
        children: <Widget>[
          // App Version Tile
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            subtitle: Text(_appVersion),
            onTap: null, // Not interactive
          ),
          const Divider(height: 1),

          // Disclaimer Tile
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('View Disclaimer'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showDisclaimerDialog,
          ),
          const Divider(height: 1),

          // Clear History Tile
          ListTile(
            leading: Icon(Icons.delete_sweep_outlined, color: Theme.of(context).colorScheme.error),
            title: Text('Clear Scan History', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _confirmClearHistory,
          ),
          const Divider(height: 1),

        ],
      ),
    );
  }
}