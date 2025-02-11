import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting

class StudentNoticesScreen extends StatefulWidget {
  const StudentNoticesScreen({super.key});

  @override
  State<StudentNoticesScreen> createState() => _StudentNoticesScreenState();
}

class _StudentNoticesScreenState extends State<StudentNoticesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Format date for display
  String _formatDate(dynamic date) {
    if (date == null) return 'Date not available';

    try {
      if (date is Timestamp) {
        DateTime dateTime = date.toDate();
        return DateFormat('MMMM d, y')
            .format(dateTime); // Format: January 1, 2024
      } else if (date is String) {
        DateTime dateTime = DateTime.parse(date);
        return DateFormat('MMMM d, y').format(dateTime);
      }
    } catch (e) {
      print('Error formatting date: $e');
    }
    return 'Invalid date format';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notices',
          style: GoogleFonts.golosText(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _firestore
            .collection('classes')
            .where('students', arrayContains: _auth.currentUser?.uid)
            .get(),
        builder: (context, classSnapshot) {
          if (classSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.blueAccent,
              ),
            );
          }

          if (!classSnapshot.hasData || classSnapshot.data!.docs.isEmpty) {
            return _buildNoNoticesWidget();
          }

          List<String> classIds =
              classSnapshot.data!.docs.map((doc) => doc.id).toList();

          if (classIds.length > 10) {
            return _buildErrorWidget();
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('notice')
                .where('class_id', whereIn: classIds)
                .orderBy('date',
                    descending: true) // Order by date (newest first)
                .snapshots(),
            builder: (context, noticeSnapshot) {
              if (noticeSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.blueAccent,
                  ),
                );
              }

              if (!noticeSnapshot.hasData ||
                  noticeSnapshot.data!.docs.isEmpty) {
                return _buildNoNoticesWidget();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: noticeSnapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final noticeData = noticeSnapshot.data!.docs[index].data()
                      as Map<String, dynamic>;
                  String teacherId = noticeData['publishedBy'];
                  String classId = noticeData['class_id'];

                  return FutureBuilder<DocumentSnapshot>(
                    future: _firestore.collection('users').doc(teacherId).get(),
                    builder: (context, teacherSnapshot) {
                      String teacherName = 'Unknown Teacher';
                      if (teacherSnapshot.hasData &&
                          teacherSnapshot.data!.exists) {
                        teacherName = teacherSnapshot.data!.get('username') ??
                            'Unknown Teacher';
                      }

                      return FutureBuilder<DocumentSnapshot>(
                        future:
                            _firestore.collection('classes').doc(classId).get(),
                        builder: (context, classSnapshot) {
                          String subject = 'Unknown Subject';
                          if (classSnapshot.hasData &&
                              classSnapshot.data!.exists) {
                            subject = classSnapshot.data!.get('subject') ??
                                'Unknown Subject';
                          }

                          return _buildNoticeCard(
                            title: subject,
                            description:
                                noticeData['message'] ?? 'No Description',
                            date: _formatDate(noticeData['date']),
                            teacherName: teacherName,
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Widget to display when no notices are found
  Widget _buildNoNoticesWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notices found',
            style: GoogleFonts.golosText(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Widget to display when there are too many classes
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Too many classes!',
            style: GoogleFonts.golosText(
              fontSize: 18,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  // Widget to build a notice card
  Widget _buildNoticeCard({
    required String title,
    required String description,
    required String date,
    required String teacherName,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.golosText(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.golosText(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Published by: $teacherName',
                  style: GoogleFonts.golosText(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  date,
                  style: GoogleFonts.golosText(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
