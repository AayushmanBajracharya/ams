import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Add this import for date formatting

class TeacherNotice extends StatefulWidget {
  const TeacherNotice({super.key});

  @override
  State<TeacherNotice> createState() => _TeacherNoticeState();
}

class _TeacherNoticeState extends State<TeacherNotice> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notices',
          style: GoogleFonts.golosText(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _firestore
            .collection('classes')
            .where('teacherId', isEqualTo: _auth.currentUser?.uid)
            .get(),
        builder: (context, classSnapshot) {
          if (classSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!classSnapshot.hasData || classSnapshot.data!.docs.isEmpty) {
            return _buildNoNoticesWidget();
          }

          // Extract class IDs
          List<String> classIds =
              classSnapshot.data!.docs.map((doc) => doc.id).toList();

          if (classIds.length > 10) {
            return _buildErrorWidget();
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('notice')
                .where('class_id', whereIn: classIds)
                .snapshots(),
            builder: (context, noticeSnapshot) {
              if (noticeSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
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

                  // Format the date
                  String formattedDate = 'No date';
                  if (noticeData['date'] != null) {
                    if (noticeData['date'] is Timestamp) {
                      // Convert Firestore Timestamp to DateTime
                      final DateTime dateTime =
                          (noticeData['date'] as Timestamp).toDate();
                      // Format the date as desired - showing only date and time
                      formattedDate =
                          DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
                    } else {
                      formattedDate = noticeData['date'].toString();
                    }
                  }

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
                            date: formattedDate,
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

  Widget _buildNoNoticesWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 64, color: Colors.grey[400]),
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

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red),
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

  Widget _buildNoticeCard({
    required String title,
    required String description,
    required String date,
    required String teacherName,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title, // Subject Name
              style: GoogleFonts.golosText(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description, // Notice message
              style: GoogleFonts.golosText(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Published by: $teacherName',
              style: GoogleFonts.golosText(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Date: $date',
              style: GoogleFonts.golosText(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
