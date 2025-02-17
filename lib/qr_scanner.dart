import 'dart:convert';
import 'dart:developer';
import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class QRScanner extends StatefulWidget {
  const QRScanner({super.key});

  @override
  State<QRScanner> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> {
  String? action;
  String? id;
  bool isJoined = false;
  String? studentName;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadStudentName();
  }

  Future<void> _loadStudentName() async {
    try {
      var userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          studentName = userDoc.data()?['username'];
        });
      }
    } catch (e) {
      log("Error loading student name: $e");
    }
  }

  Future<void> _checkClassMembership(String classId) async {
    try {
      var classDoc = await _firestore.collection('classes').doc(classId).get();
      if (classDoc.exists) {
        List<String> students =
            List<String>.from(classDoc.data()?['students'] ?? []);
        setState(() {
          isJoined = students.contains(_auth.currentUser!.uid);
        });
      }
    } catch (e) {
      log("Error checking class membership: $e");
    }
  }

  Future<void> _joinClass(String classId) async {
    try {
      var classDoc = await _firestore.collection('classes').doc(classId).get();
      List<String> studentsInClass =
          List<String>.from(classDoc.data()!['students'] ?? []);

      if (!studentsInClass.contains(_auth.currentUser!.uid)) {
        studentsInClass.add(_auth.currentUser!.uid);
        await _firestore
            .collection("classes")
            .doc(classId)
            .update({"students": studentsInClass});

        await _firestore.collection('enrolledStudents').add({
          'classId': classId,
          'studentId': _auth.currentUser!.uid,
          'studentName': studentName,
        });

        _showSnackBar('Successfully joined the class!', Colors.green);
        setState(() {
          isJoined = true;
        });
      }
    } catch (e) {
      log("Error joining class: $e");
      _showSnackBar('Failed to join class. Please try again.', Colors.red);
    }
  }

  Future<void> _markAttendance(String classId) async {
    try {
      String today = DateTime.now().toString().split(' ')[0];

      var existingAttendance = await _firestore
          .collection('attendance')
          .where('classId', isEqualTo: classId)
          .where('studentId', isEqualTo: _auth.currentUser!.uid)
          .where('date', isEqualTo: today)
          .get();

      if (existingAttendance.docs.isEmpty) {
        await _firestore.collection('attendance').add({
          'classId': classId,
          'studentId': _auth.currentUser!.uid,
          'studentName': studentName,
          'date': today,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'P',
        });

        _showSnackBar('Attendance marked successfully!', Colors.green);
      } else {
        _showSnackBar('Attendance already marked for today', Colors.orange);
      }
    } catch (e) {
      log("Error marking attendance: $e");
      _showSnackBar('Failed to mark attendance. Please try again.', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AiBarcodeScanner(
            controller: MobileScannerController(
              detectionSpeed: DetectionSpeed.noDuplicates,
            ),
            onDetect: (BarcodeCapture barcodeCapture) async {
              Map<String, dynamic> data =
                  jsonDecode(barcodeCapture.barcodes.first.rawValue!);
              if (data.keys.contains("join")) {
                action = "join";
                id = data["join"];
                await _checkClassMembership(id!);
              }
              setState(() {});
            },
            hideGalleryButton: true,
            hideSheetDragHandler: true,
            hideGalleryIcon: true,
            hideSheetTitle: true,
          ),
          if (action != null && id != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isJoined)
                        _buildActionButton(
                          text: 'Join Class',
                          onPressed: () => _joinClass(id!),
                          color: Colors.blue,
                          icon: Icons.group_add,
                        ),
                      if (isJoined)
                        _buildActionButton(
                          text: 'Mark Attendance',
                          onPressed: () => _markAttendance(id!),
                          color: Colors.green,
                          icon: Icons.check_circle,
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
