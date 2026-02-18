import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'gemini_service.dart';
import 'firestore_service.dart';
import 'notification_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  Position? _currentPosition;

  String _getSeverityExplanation(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return '🔴 Immediate danger — urgent repair needed';
      case 'MEDIUM':
        return '🟠 Moderate damage — repair within 1 week';
      case 'LOW':
        return '🟡 Minor damage — monitor and repair soon';
      case 'NONE':
        return '🟢 No damage detected — road looks good';
      default:
        return '⚪ Unable to classify damage';
    }
  }

  // Severity colors
  Color get _severityColor {
    if (_analysisResult == null) return Colors.grey;
    switch (_analysisResult!['severity']) {
      case 'CRITICAL':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.yellow[700]!;
      default:
        return Colors.green;
    }
  }

  // Severity icons
  IconData get _severityIcon {
    if (_analysisResult == null) return Icons.help_outline;
    switch (_analysisResult!['severity']) {
      case 'CRITICAL':
        return Icons.dangerous;
      case 'MEDIUM':
        return Icons.warning;
      case 'LOW':
        return Icons.info;
      default:
        return Icons.check_circle;
    }
  }

  // Get current GPS location
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _analysisResult = null;  // Reset previous result
      });

      // Automatically analyze as soon as image is picked
      await _analyzeImage();
    }
  }

  // Send image to Gemini AI for analysis
  Future<void> _analyzeImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    // Get location and analyze image simultaneously
    await Future.wait([
      _getCurrentLocation(),
      GeminiService.analyzePothole(_imageFile!).then((result) {
        setState(() {
          _analysisResult = result;
          _isAnalyzing = false;
        });
      }),
    ]);
  }

  // Save report to Firestore
  Future<void> _submitReport() async {
    if (_imageFile == null || _analysisResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a photo first!')),
      );
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not get location. Please try again.'),
        ),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    final reportId = await FirestoreService.saveReport(
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      severity: _analysisResult!['severity'] ?? 'UNKNOWN',
      description: _analysisResult!['description'] ?? '',
      recommendation: _analysisResult!['recommendation'] ?? '',
      confidence: _analysisResult!['confidence'] ?? 0,
      damageDetected: _analysisResult!['damage_detected'] ?? false,
    );

    setState(() => _isAnalyzing = false);

    if (reportId != null) {
      // Show critical alert if severity is CRITICAL
      final severity = _analysisResult!['severity'] ?? '';
      if (severity.toUpperCase() == 'CRITICAL' && mounted) {
        NotificationService.showCriticalAlert(
          context: context,
          description: _analysisResult!['description'] ?? '',
          coordinates:
          '${_currentPosition!.latitude.toStringAsFixed(4)}, '
              '${_currentPosition!.longitude.toStringAsFixed(4)}',
        );
        // Small delay so user sees the alert before navigating back
        await Future.delayed(const Duration(seconds: 1));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Report submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to submit. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Camera'),
              subtitle: const Text('Take a new photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Gallery'),
              subtitle: const Text('Choose existing photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Report Pothole',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview box
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: _imageFile == null
                    ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'Tap to take/choose photo',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(_imageFile!, fit: BoxFit.cover),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Analyzing indicator
            if (_isAnalyzing)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        '🤖 Gemini AI is analyzing...',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

            // AI Analysis result
            if (_analysisResult != null && !_isAnalyzing)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _severityColor, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Severity badge
                      Row(
                        children: [
                          Icon(_severityIcon, color: _severityColor, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'Severity: ${_analysisResult!['severity']}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _severityColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getSeverityExplanation(_analysisResult!['severity'] ?? ''),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Confidence bar
                      Text(
                        'Confidence: ${_analysisResult!['confidence']}%',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: (_analysisResult!['confidence'] as int) / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation(_severityColor),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      const Text(
                        'Description:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(_analysisResult!['description'] ?? ''),
                      const SizedBox(height: 8),

                      // Recommendation
                      const Text(
                        'Recommendation:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(_analysisResult!['recommendation'] ?? ''),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Take photo button
            ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _showImageSourceDialog,
              icon: const Icon(Icons.camera_alt),
              label: Text(_imageFile == null ? 'Take Photo' : 'Retake Photo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            // Submit button (only shows after AI analysis)
            if (_analysisResult != null && !_isAnalyzing)
              ElevatedButton.icon(
                onPressed: _submitReport,
                icon: const Icon(Icons.send),
                label: const Text('Submit Report'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}