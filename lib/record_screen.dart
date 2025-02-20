import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'messages.dart';
import 'student_schedule_screen.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: Text(
          'My Attendance',
          style: GoogleFonts.golosText(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser?.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
          final username = userData?['username'] ?? 'User';

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('attendance')
                .where('studentId', isEqualTo: currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Calculate overall attendance statistics
              final records = snapshot.data?.docs ?? [];
              final totalClasses = records.length;
              int attendedClasses = 0;

              for (var record in records) {
                final data = record.data() as Map<String, dynamic>;
                if (data['status'] == 'P') {
                  attendedClasses++;
                }
              }

              final absentClasses = totalClasses - attendedClasses;

              // Calculate percentages
              final presentPercentage = totalClasses > 0
                  ? '${(attendedClasses / totalClasses * 100).toStringAsFixed(1)}%'
                  : '0%';
              final absentPercentage = totalClasses > 0
                  ? '${(absentClasses / totalClasses * 100).toStringAsFixed(1)}%'
                  : '0%';
              // Add StreamBuilder for leave requests
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('leave_requests')
                    .where('studentId', isEqualTo: currentUser?.uid)
                    .where('status', isEqualTo: 'approved')
                    .snapshots(),
                builder: (context, leaveSnapshot) {
                  if (leaveSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Count approved leave requests
                  final approvedLeaves = leaveSnapshot.data?.docs.length ?? 0;
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Profile and Summary Card
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue[800]!, Colors.blue[600]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.person_outline,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          username,
                                          style: GoogleFonts.golosText(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildAttendanceIndicator('Present',
                                        presentPercentage, Colors.green[300]!),
                                    _buildVerticalDivider(),
                                    _buildAttendanceIndicator('Absent',
                                        absentPercentage, Colors.red[300]!),
                                    _buildVerticalDivider(),
                                    _buildAttendanceIndicator(
                                        'Leave',
                                        approvedLeaves.toString(),
                                        Colors.orange[300]!),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Quick Actions Grid
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quick Actions',
                                style: GoogleFonts.golosText(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                              const SizedBox(height: 12),
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1.5,
                                children: [
                                  _buildQuickActionCard(
                                    title: 'Request Leave',
                                    subtitle: 'Submit application',
                                    icon: Icons.event_busy_outlined,
                                    color: Colors.orange[700]!,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MessageScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildQuickActionCard(
                                    title: 'View Schedule',
                                    subtitle: 'Today\'s classes',
                                    icon: Icons.schedule_outlined,
                                    color: Colors.purple[700]!,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              StudentScheduleScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // My Classes Section
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Classes',
                                style: GoogleFonts.golosText(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                              const SizedBox(height: 12),
                              FutureBuilder<QuerySnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('attendance')
                                    .where('studentId',
                                        isEqualTo: currentUser?.uid)
                                    .get(),
                                builder: (context, attendanceSnapshot) {
                                  if (attendanceSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  final attendanceRecords =
                                      attendanceSnapshot.data?.docs ?? [];

                                  if (attendanceRecords.isEmpty) {
                                    return _buildEmptyClassesCard();
                                  }

                                  // Extract unique class IDs and organize session data
                                  Map<String, Map<String, dynamic>>
                                      classesData = {};
                                  Map<String, Set<String>> sessionDates = {};

                                  // First pass - collect all unique classes and their basic info
                                  for (var record in attendanceRecords) {
                                    final data =
                                        record.data() as Map<String, dynamic>;
                                    final classId = data['classId'] as String?;

                                    if (classId != null) {
                                      if (!classesData.containsKey(classId)) {
                                        classesData[classId] = {
                                          'classId': classId,
                                          'title': data['subject'] ??
                                              'Unknown Subject',
                                          'teacherId': data['teacherId'] ??
                                              'Unknown Instructor',
                                          'schedule':
                                              'Class Sessions: ${data['date'] ?? 'Schedule not available'}',
                                          'presentCount': 0,
                                          'totalDates': <String>{},
                                        };
                                        sessionDates[classId] = <String>{};
                                      }

                                      // Add this session date to the set of sessions for this class
                                      final sessionDate =
                                          data['date'] as String?;
                                      if (sessionDate != null) {
                                        sessionDates[classId]!.add(sessionDate);
                                      }

                                      // Count present sessions
                                      if (data['status'] == 'P') {
                                        classesData[classId]!['presentCount'] =
                                            (classesData[classId]![
                                                    'presentCount'] as int) +
                                                1;
                                      }
                                    }
                                  }

                                  // Update each class with the total unique session dates
                                  for (var classId in classesData.keys) {
                                    classesData[classId]!['totalDates'] =
                                        sessionDates[classId]!;
                                  }

                                  if (classesData.isEmpty) {
                                    return _buildEmptyClassesCard();
                                  }

                                  // Fetch additional class details from Firestore
                                  return FutureBuilder<List<Widget>>(
                                    future: Future.wait(
                                      classesData.values.map((classData) async {
                                        final classId =
                                            classData['classId'] as String;
                                        final presentCount =
                                            classData['presentCount'] as int;
                                        final totalDates =
                                            (classData['totalDates']
                                                    as Set<String>)
                                                .length;

                                        final attendancePercentage =
                                            totalDates > 0
                                                ? (presentCount /
                                                        totalDates *
                                                        100)
                                                    .toInt()
                                                : 0;

                                        // Extract initial data
                                        String teacherId =
                                            classData['teacherId'] as String;
                                        String teacherName =
                                            teacherId; // Default to ID if name can't be found
                                        String subjectName =
                                            classData['title'] as String;

                                        try {
                                          // 1. First try to fetch class details from classes collection
                                          final classDoc =
                                              await FirebaseFirestore.instance
                                                  .collection('classes')
                                                  .doc(classId)
                                                  .get();

                                          if (classDoc.exists) {
                                            final classDetails =
                                                classDoc.data();
                                            if (classDetails != null) {
                                              // Extract subject information from class document
                                              if (classDetails
                                                  .containsKey('subjectName')) {
                                                subjectName =
                                                    classDetails['subjectName']
                                                        as String;
                                              } else if (classDetails
                                                  .containsKey('subject')) {
                                                subjectName =
                                                    classDetails['subject']
                                                        as String;
                                              }

                                              // Ensure we have teacher ID
                                              if (classDetails
                                                  .containsKey('teacherId')) {
                                                teacherId =
                                                    classDetails['teacherId']
                                                        as String;
                                              }
                                            }
                                          }

                                          // 2. Get teacher name using the teacherId
                                          final teacherDoc =
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(teacherId)
                                                  .get();

                                          if (teacherDoc.exists) {
                                            final teacherData =
                                                teacherDoc.data();
                                            if (teacherData != null &&
                                                teacherData
                                                    .containsKey('username')) {
                                              teacherName =
                                                  teacherData['username']
                                                      as String;
                                            }
                                          }
                                        } catch (e) {
                                          print(
                                              'Error fetching details for class $classId: $e');
                                        }

                                        return _buildClassCard(
                                          subjectName,
                                          classData['schedule'] as String,
                                          attendancePercentage,
                                          presentCount,
                                          totalDates,
                                          teacherName,
                                        );
                                      }).toList(),
                                    ),
                                    builder: (context, cardsSnapshot) {
                                      if (cardsSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                            child: CircularProgressIndicator());
                                      }

                                      return Column(
                                        children: cardsSnapshot.data ?? [],
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAttendanceIndicator(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.golosText(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.golosText(
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.2),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.golosText(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.golosText(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassCard(
    String className,
    String schedule,
    int attendancePercentage,
    int attendedSessions,
    int totalSessions,
    String instructor,
  ) {
    Color progressColor;
    if (attendancePercentage >= 85) {
      progressColor = Colors.green;
    } else if (attendancePercentage >= 75) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  className,
                  style: GoogleFonts.golosText(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: progressColor.withOpacity(0.5)),
                ),
                child: Text(
                  '$attendancePercentage%',
                  style: GoogleFonts.golosText(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            schedule,
            style: GoogleFonts.golosText(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Instructor: $instructor',
            style: GoogleFonts.golosText(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: totalSessions > 0 ? attendedSessions / totalSessions : 0,
              backgroundColor: Colors.grey[200],
              color: progressColor,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Attended $attendedSessions out of $totalSessions sessions',
            style: GoogleFonts.golosText(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyClassesCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 48,
            color: Colors.blue[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Classes Found',
            style: GoogleFonts.golosText(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You are not enrolled in any classes yet',
            textAlign: TextAlign.center,
            style: GoogleFonts.golosText(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
