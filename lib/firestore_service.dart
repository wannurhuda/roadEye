import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FirestoreService {
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
        'status': 'pending',
      });
      print('✅ Report saved: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error saving report: $e');
      return null;
    }
  }

  // Get all reports as real-time stream
  static Stream<QuerySnapshot> getReports() {
    return _reports
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get marker color based on severity
  static BitmapDescriptor getSeverityMarker(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        );
      case 'MEDIUM':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueOrange,
        );
      case 'LOW':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueYellow,
        );
      default:
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueBlue,
        );
    }
  }

  // Get color integer for UI elements
  static int getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return 0xFFE53935;
      case 'MEDIUM':
        return 0xFFFB8C00;
      case 'LOW':
        return 0xFFFDD835;
      default:
        return 0xFF9E9E9E;
    }
  }
}