import 'package:ams/dummy/schedule.dart';
import 'package:ams/teacher_notice.dart';
import 'package:ams/teacher_schedule_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'teacher_message.dart';
import 'profile_screen.dart';
import 'teacher_my_classes_screen.dart';
import 'teacher_attendance_req.dart';

class TeacherDashBoard extends StatefulWidget {
  const TeacherDashBoard({super.key});

  @override
  State<TeacherDashBoard> createState() => _TeacherDashBoardState();
}

class _TeacherDashBoardState extends State<TeacherDashBoard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _username = '';
  String _email = '';
  List<Map<String, dynamic>> mySchedule = [];
  getMySchedule() {
    mySchedule = scheduleData;
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<String> _getCurrentDay() {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final now = DateTime.now();
    return Future.value(days[now.weekday - 1]);
  }

  String _formatTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final formatted = '${(hour > 12 ? hour - 12 : hour)}:$minute $period';
      return formatted;
    } catch (e) {
      return timeString;
    }
  }

  Future<String> _getClassName(String classId) async {
    try {
      DocumentSnapshot classDoc =
          await _firestore.collection('classes').doc(classId).get();
      if (classDoc.exists) {
        Map<String, dynamic> data = classDoc.data() as Map<String, dynamic>;
        return data['subject'] ?? 'subject';
      }
      return 'Unknown Class';
    } catch (e) {
      debugPrint('Error fetching class name: $e');
      return 'Unknown Class';
    }
  }

  Future<int> _getNumberOfClassesCreated() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return 0;
      }

      QuerySnapshot classData = await _firestore
          .collection('classes')
          .where('teacherId', isEqualTo: user.uid)
          .get();

      return classData.size;
    } catch (e) {
      debugPrint('Error fetching classes: $e');
      return 0;
    }
  }

  Future<void> _loadUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        _email = user.email ?? '';

        DocumentSnapshot userData =
            await _firestore.collection('users').doc(user.uid).get();

        if (userData.exists) {
          setState(() {
            _username = userData.get('username') ?? 'Teacher';
            if (_email.isEmpty) {
              _email = userData.get('email') ?? '';
            }
          });
        }
      } else {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.golosText(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.white,
        title: Text(
          'AMS',
          style: GoogleFonts.golosText(
            fontSize: 20.0,
            fontWeight: FontWeight.w600,
            color: Colors.blue[800],
          ),
        ),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue[800],
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 50, color: Colors.blue),
              ),
              accountName: Text(
                _username,
                style: GoogleFonts.golosText(
                  fontWeight: FontWeight.w600,
                ),
              ),
              accountEmail: Text(
                _email,
                style: GoogleFonts.golosText(),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.class_),
              title: const Text('My Classes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TeacherMyClass(),
                  ),
                );
              },
            ),
            ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Schedule'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TeacherScheduleScreen(),
                    ),
                  );
                }),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Messages'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeacherMessageScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notice'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TeacherNotice(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, $_username!',
              style: GoogleFonts.golosText(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 20),
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(_auth.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                return FutureBuilder<int>(
                  future: _getNumberOfClassesCreated(),
                  builder: (context, classSnapshot) {
                    if (classSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    if (classSnapshot.hasError) {
                      return const Text('Error loading class data');
                    }

                    final int numberOfClasses = classSnapshot.data ?? 0;

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TeacherMyClass(),
                              ),
                            );
                          },
                          child: _buildDashboardCard(
                            icon: Icons.class_,
                            title: 'My Classes',
                            value: '',
                            color: Colors.blue,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TeacherNotice(),
                              ),
                            );
                          },
                          child: _buildDashboardCard(
                            icon: Icons.notifications,
                            title: 'Notice',
                            value: '',
                            color: Colors.green,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AttendanceclassDetailsScreen(
                                  classId: 'your_class_id',
                                  className: 'your_class_name',
                                ),
                              ),
                            );
                          },
                          child: _buildDashboardCard(
                            icon: Icons.assignment,
                            title: 'Attendance Requests',
                            value: '',
                            color: Colors.orange,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TeacherMessageScreen(),
                              ),
                            );
                          },
                          child: _buildDashboardCard(
                            icon: Icons.message,
                            title: 'Leave Request',
                            value: '',
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Class Schedule',
                          style: GoogleFonts.golosText(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const TeacherScheduleScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'View All',
                            style: GoogleFonts.golosText(
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<QuerySnapshot>(
                      future: _firestore
                          .collection('classes')
                          .where('teacherId', isEqualTo: _auth.currentUser?.uid)
                          .get(),
                      builder: (context, classSnapshot) {
                        if (classSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!classSnapshot.hasData ||
                            classSnapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Text(
                              'No scheduled classes.',
                              style: GoogleFonts.golosText(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        }

                        List<String> classIds = classSnapshot.data!.docs
                            .map((doc) => doc.id)
                            .toList();

                        return StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('schedule')
                              .where('class_id', whereIn: classIds)
                              .snapshots(),
                          builder: (context, scheduleSnapshot) {
                            if (scheduleSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            if (!scheduleSnapshot.hasData ||
                                scheduleSnapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Text(
                                  'No scheduled classes.',
                                  style: GoogleFonts.golosText(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              );
                            }

                            Map<String, List<Map<String, dynamic>>>
                                schedulesByDay = {};
                            final weekDays = [
                              'Monday',
                              'Tuesday',
                              'Wednesday',
                              'Thursday',
                              'Friday',
                              'Saturday',
                              'Sunday'
                            ];

                            // Initialize empty lists for each day
                            for (var day in weekDays) {
                              schedulesByDay[day] = [];
                            }

                            // Group schedule data by days
                            for (var doc in scheduleSnapshot.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              final day = data['day_of_week'] ?? 'Unknown';
                              if (schedulesByDay.containsKey(day)) {
                                schedulesByDay[day]!.add({
                                  ...data,
                                  'id': doc.id,
                                });
                              }
                            }

                            // Sort schedules within each day by start time
                            schedulesByDay.forEach((day, schedules) {
                              schedules.sort((a, b) {
                                String aTime = a['start_time'] ?? '';
                                String bTime = b['start_time'] ?? '';
                                return aTime.compareTo(bTime);
                              });
                            });

                            // Display schedules by day
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: weekDays.length,
                              itemBuilder: (context, dayIndex) {
                                String day = weekDays[dayIndex];
                                List<Map<String, dynamic>> daySchedules =
                                    schedulesByDay[day] ?? [];

                                // Skip days with no schedules
                                if (daySchedules.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[800],
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              day,
                                              style: GoogleFonts.golosText(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Divider(
                                              indent: 8,
                                              color: Colors.grey[300],
                                              thickness: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: daySchedules.length,
                                      itemBuilder: (context, scheduleIndex) {
                                        final scheduleData =
                                            daySchedules[scheduleIndex];
                                        String classId =
                                            scheduleData['class_id'] ??
                                                'Unknown ID';
                                        String startTime =
                                            scheduleData['start_time'] ?? '';
                                        String endTime =
                                            scheduleData['end_time'] ?? '';

                                        return FutureBuilder<DocumentSnapshot>(
                                          future: _firestore
                                              .collection('classes')
                                              .doc(classId)
                                              .get(),
                                          builder: (context, classDoc) {
                                            if (!classDoc.hasData) {
                                              return const SizedBox.shrink();
                                            }

                                            final classData = (classDoc.data)
                                                        ?.data()
                                                    as Map<String, dynamic>? ??
                                                <String, dynamic>{};
                                            String subject =
                                                classData['subject'] ??
                                                    'Unknown Class';
                                            String roomNumber =
                                                classData['roomNumber'] ??
                                                    'No Room';

                                            return Card(
                                              elevation: 1,
                                              margin: const EdgeInsets.only(
                                                  bottom: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: ListTile(
                                                leading: Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Icon(
                                                    Icons.access_time,
                                                    color: Colors.blue[800],
                                                  ),
                                                ),
                                                title: Text(
                                                  subject,
                                                  style: GoogleFonts.golosText(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue[800],
                                                  ),
                                                ),
                                                subtitle: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '${_formatTimeString(startTime)} - ${_formatTimeString(endTime)}',
                                                      style:
                                                          GoogleFonts.golosText(
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    Text(
                                                      'Room: $roomNumber',
                                                      style:
                                                          GoogleFonts.golosText(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
