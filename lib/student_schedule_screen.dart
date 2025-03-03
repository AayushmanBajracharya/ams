import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentScheduleScreen extends StatefulWidget {
  const StudentScheduleScreen({super.key});

  @override
  State<StudentScheduleScreen> createState() => _StudentScheduleScreenState();
}

class _StudentScheduleScreenState extends State<StudentScheduleScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> daysOrder = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  /// Group schedules by day and sort by start time
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

  /// Get stream of schedules for enrolled classes
  Stream<List<DocumentSnapshot>> _getSchedulesStream() async* {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        yield [];
        return;
      }

      // Get user's enrolled classes
      final enrollmentSnapshot = await _firestore
          .collection('classes')
          .where('students', arrayContains: currentUser.uid)
          .get();

      if (enrollmentSnapshot.docs.isEmpty) {
        yield [];

        return;
      }

      // Get list of enrolled class IDs
      List<String> enrolledClassIds = enrollmentSnapshot.docs
          .map((doc) => doc.id) // Use the document ID as the class ID
          .toList();

      //ugPrint(enrolledClassIds as String?);

      // Fetch schedules for the enrolled class IDs
      final scheduleSnapshot = await _firestore
          .collection('schedule')
          .where('class_id', whereIn: enrolledClassIds)
          .get();

      yield scheduleSnapshot.docs;
    } catch (e) {
      debugPrint('Error fetching schedules: $e');
      yield [];
    }
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
          'My Class Schedule',
          style: GoogleFonts.golosText(
            fontSize: 20.0,
            fontWeight: FontWeight.w600,
            color: Colors.blue[800],
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: _getSchedulesStream(),
        builder: (context, scheduleSnapshot) {
          if (scheduleSnapshot.hasError) {
            return Center(child: Text('Error: ${scheduleSnapshot.error}'));
          }

          if (scheduleSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!scheduleSnapshot.hasData || scheduleSnapshot.data!.isEmpty) {
            return _buildNoScheduleWidget();
          }

          final groupedSchedules = groupSchedulesByDay(scheduleSnapshot.data!);

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
                        future:
                            _firestore.collection('classes').doc(classId).get(),
                        builder: (context, classSnapshot) {
                          if (!classSnapshot.hasData) {
                            return const SizedBox.shrink();
                          }

                          final classData = classSnapshot.data!.data()
                              as Map<String, dynamic>;
                          final subject =
                              classData['subject'] ?? 'Unknown Class';
                          final teacherId = classData['teacherId'];

                          return FutureBuilder<DocumentSnapshot>(
                            future: _firestore
                                .collection('users')
                                .doc(teacherId)
                                .get(),
                            builder: (context, teacherSnapshot) {
                              final teacherName =
                                  teacherSnapshot.data?.get('username') ??
                                      'Unknown Teacher';
                              return _buildScheduleCard(
                                  subject, teacherName, time);
                            },
                          );
                        },
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                );
              }).toList(),
            ),
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
            'No classes found',
            style: GoogleFonts.golosText(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enroll in classes to view your schedule',
            style: GoogleFonts.golosText(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(String subject, String teacherName, String time) {
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
                  Text(subject,
                      style: GoogleFonts.golosText(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      )),
                  const SizedBox(height: 4),
                  Text(teacherName),
                  Text('Time: $time'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
