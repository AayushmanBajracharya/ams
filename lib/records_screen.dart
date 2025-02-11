import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String userName = '';
  List<Map<String, dynamic>> enrolledClasses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => isLoading = true);

      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Fetch user profile data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }

      final userData = userDoc.data();
      if (userData == null) {
        throw Exception('User data is null');
      }

      // Fetch enrolled classes
      final classesQuery = await _firestore
          .collection('enrollments')
          .where('studentId', isEqualTo: user.uid)
          .get();

      List<Map<String, dynamic>> classes = [];

      for (var doc in classesQuery.docs) {
        final classData = doc.data();
        final classDoc = await _firestore
            .collection('classes')
            .doc(classData['classId'])
            .get();

        if (classDoc.exists && classDoc.data() != null) {
          final classDetails = classDoc.data()!;

          // Calculate attendance percentage
          final attendanceQuery = await _firestore
              .collection('attendance')
              .where('classId', isEqualTo: classData['classId'])
              .where('studentId', isEqualTo: user.uid)
              .get();

          final totalClasses = classDetails['totalClasses'] ?? 0;
          final attendedClasses = attendanceQuery.docs.length;
          final attendancePercentage = totalClasses > 0
              ? (attendedClasses / totalClasses * 100).toStringAsFixed(1)
              : '0.0';

          classes.add({
            'id': classData['classId'],
            ...classDetails,
            'attendancePercentage': attendancePercentage,
            'attendedClasses': attendedClasses,
            'totalClasses': totalClasses,
          });
        }
      }

      setState(() {
        userName = userData['username'] ?? 'N/A';
        enrolledClasses = classes;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorDialog('Error loading data: $e');
    }
  }

  Future<void> _showAttendanceDetails(Map<String, dynamic> classData) async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
      final attendanceQuery = await _firestore
          .collection('attendance')
          .where('classId', isEqualTo: classData['id'])
          .where('studentId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .get();

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classData['subject'] ?? 'Class',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Attendance Records',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: attendanceQuery.docs.length,
                  itemBuilder: (context, index) {
                    final attendance = attendanceQuery.docs[index].data();
                    final date = (attendance['date'] as Timestamp).toDate();
                    return ListTile(
                      leading:
                          const Icon(Icons.check_circle, color: Colors.green),
                      title: Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(date),
                        style: GoogleFonts.poppins(),
                      ),
                      subtitle: Text(
                        DateFormat('h:mm a').format(date),
                        style: GoogleFonts.poppins(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      _showErrorDialog('Error loading attendance details: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Error', style: GoogleFonts.poppins()),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Student Records',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.blue[800]),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Info Card (Profile image and Student ID removed)
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Enrolled Classes
                    Text(
                      "Enrolled Classes",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: enrolledClasses.length,
                      itemBuilder: (context, index) {
                        final classData = enrolledClasses[index];
                        return GestureDetector(
                          onTap: () => _showAttendanceDetails(classData),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            elevation: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    classData['program'] ?? 'N/A',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    classData['subject'] ?? 'N/A',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  LinearProgressIndicator(
                                    value: double.parse(
                                            classData['attendancePercentage']) /
                                        100,
                                    backgroundColor: Colors.grey[300],
                                    color: Colors.green,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${classData['attendancePercentage']}% Attendance",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        "${classData['attendedClasses']}/${classData['totalClasses']} Classes",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
