import 'dart:convert';

class ScanResult {
  final int? id;
  final DateTime timestamp;
  final String imagePath;
  final String diagnosis;
  final List<double>? probabilities;
  final Map<String, dynamic> reportDetails;

  ScanResult({
    this.id,
    required this.timestamp,
    required this.imagePath,
    required this.diagnosis,
    this.probabilities,
    required this.reportDetails,
  });


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'imagePath': imagePath,
      'diagnosis': diagnosis,
      'probabilities': probabilities != null ? jsonEncode(probabilities) : null,
      'reportJson': jsonEncode(reportDetails), // Store report as JSON string
    };
  }


  factory ScanResult.fromMap(Map<String, dynamic> map) {
    List<double>? decodedProbs;
    if (map['probabilities'] != null) {
      try {
        final List<dynamic> probList = jsonDecode(map['probabilities']);
        decodedProbs = probList.map((e) => (e as num).toDouble()).toList();
      } catch (e) {
        print("Error decoding probabilities from DB: $e");
        decodedProbs = null;
      }
    }

    Map<String, dynamic> decodedReport = {};
    try {
      decodedReport = jsonDecode(map['reportJson']);
    } catch (e) {
      print("Error decoding reportJson from DB: $e");
    }


    return ScanResult(
      id: map['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      imagePath: map['imagePath'],
      diagnosis: map['diagnosis'],
      probabilities: decodedProbs,
      reportDetails: decodedReport,
    );
  }
}