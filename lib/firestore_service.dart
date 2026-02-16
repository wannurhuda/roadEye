import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // Reference to our pothole reports collection
  static final CollectionReference _reports =
  FirebaseFirestore.instance.collection('pothole_reports');

  // Save a new pothole report
  static Future<String?> saveReport({
    required double latitude,
    required double longitude,
    required String severity,
    required String description,
    required String recommendation,
    required int confidence,
    required bool damageDetected,
  }) async {
    try {
      final docRef = await _reports.add({
        'latitude': latitude,
        'longitude': longitude,
        'severity': severity,
        'description': description,
        'recommendation': recommendation,
        'confidence': confidence,
        'damage_detected': damageDetected,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',  // pending, acknowledged, fixed
      });
      return docRef.id;  // Return the document ID
    } catch (e) {
      print('Error saving report: $e');
      return null;
    }
  }

  // Get all pothole reports (for the map)
  static Stream<QuerySnapshot> getReports() {
    return _reports
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get severity color for map markers
  static String getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return 'red';
      case 'MEDIUM':
        return 'orange';
      case 'LOW':
        return 'yellow';
      default:
        return 'grey';
    }
  }
}