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

  // Order days of week for consistent sorting
  final List<String> daysOrder = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  Map<String, List<Map<String, dynamic>>> groupSchedulesByDay(
      List<DocumentSnapshot> schedules) {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    // Initialize empty lists for all days
    for (var day in daysOrder) {
      grouped[day] = [];
    }

    // Group schedules by day
    for (var schedule in schedules) {
      final data = schedule.data() as Map<String, dynamic>;
      String day = data['day_of_week'] ?? 'Unknown';
      if (grouped.containsKey(day)) {
        grouped[day]!.add(data);
      }
    }

    // Sort each day's schedules by start time
    for (var day in grouped.keys) {
      grouped[day]!.sort((a, b) {
        return (a['start_time'] ?? '').compareTo(b['start_time'] ?? '');
      });
    }

    return grouped;
  }

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

          List<String> classIds =
              classSnapshot.data!.docs.map((doc) => doc.id).toList();

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('schedule')
                .where('class_id', whereIn: classIds)
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

              final groupedSchedules =
                  groupSchedulesByDay(scheduleSnapshot.data!.docs);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: daysOrder.map((day) {
                    final schedules = groupedSchedules[day] ?? [];
                    if (schedules.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            day,
                            style: GoogleFonts.golosText(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        ...schedules.map((schedule) {
                          final classId = schedule['class_id'] ?? 'Unknown ID';
                          final time =
                              "${schedule['start_time']} - ${schedule['end_time']}";

                          return FutureBuilder<DocumentSnapshot>(
                            future: _firestore
                                .collection('classes')
                                .doc(classId)
                                .get(),
                            builder: (context, classSnapshot) {
                              if (!classSnapshot.hasData) {
                                return const SizedBox.shrink();
                              }

                              final subject = classSnapshot.data?['subject'] ??
                                  'Unknown Class';
                              return _buildScheduleCard(subject, day, time);
                            },
                          );
                        }).toList(),
                        const SizedBox(height: 16),
                      ],
                    );
                  }).toList(),
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.class_,
                color: Colors.blue[800],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject,
                    style: GoogleFonts.golosText(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
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
          ],
        ),
      ),
    );
  }
}
