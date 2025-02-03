import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeacherScheduleScreen extends StatefulWidget {
  const TeacherScheduleScreen({super.key});

  @override
  State<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends State<TeacherScheduleScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.blue[800]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Schedule',
          style: GoogleFonts.golosText(
            fontSize: 20.0,
            fontWeight: FontWeight.w600,
            color: Colors.blue[800],
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _firestore
            .collection('classes')
            .where('teacherId', isEqualTo: _auth.currentUser?.uid)
            .get(),
        builder: (context, classSnapshot) {
          if (classSnapshot.hasError) {
            return Center(child: Text('Error: ${classSnapshot.error}'));
          }

          if (classSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!classSnapshot.hasData || classSnapshot.data!.docs.isEmpty) {
            return _buildNoScheduleWidget();
          }

          // Extract class IDs from the classes collection
          List<String> classIds =
              classSnapshot.data!.docs.map((doc) => doc.id).toList();

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('schedule')
                .where('class_id',
                    whereIn: classIds) // Use classIds to filter schedules
                .snapshots(),
            builder: (context, scheduleSnapshot) {
              if (scheduleSnapshot.hasError) {
                return Center(child: Text('Error: ${scheduleSnapshot.error}'));
              }

              if (scheduleSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!scheduleSnapshot.hasData ||
                  scheduleSnapshot.data!.docs.isEmpty) {
                return _buildNoScheduleWidget();
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  itemCount: scheduleSnapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final scheduleData = scheduleSnapshot.data!.docs[index]
                        .data() as Map<String, dynamic>;

                    // Extract classId from the schedule document
                    String classId = scheduleData['class_id'] ?? 'Unknown ID';
                    String day = scheduleData['day_of_week'] ?? 'No Day';
                    String time =
                        "${scheduleData['start_time']} - ${scheduleData['end_time']}";

                    // Fetch the class name using the classId
                    return FutureBuilder<DocumentSnapshot>(
                      future:
                          _firestore.collection('classes').doc(classId).get(),
                      builder: (context, classSnapshot) {
                        if (classSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (classSnapshot.hasError || !classSnapshot.hasData) {
                          return _buildScheduleCard(
                              'Error Loading Class', day, time);
                        }

                        String subject =
                            classSnapshot.data?['subject'] ?? 'Unknown Class';
                        return _buildScheduleCard(subject, day, time);
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNoScheduleWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No schedule found',
            style: GoogleFonts.golosText(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later or update your schedule',
            style: GoogleFonts.golosText(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(String subject, String day, String time) {
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
              subject,
              style: GoogleFonts.golosText(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Day: $day',
              style: GoogleFonts.golosText(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Time: $time',
              style: GoogleFonts.golosText(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
