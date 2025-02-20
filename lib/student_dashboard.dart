import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ams/main.dart';
import 'package:ams/qr_scanner.dart';
import 'package:ams/student_schedule_screen.dart';
import 'package:ams/profile_screen.dart';
import 'package:ams/student_my_class_screen.dart';
import 'package:ams/record_screen.dart';
import 'package:ams/messages.dart';
import 'package:ams/student_notice.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  // State variables
  String _username = '';
  String _email = '';
  List<String> _enrolledClassIds = [];
  List<Map<String, dynamic>> _enrolledClasses = [];
  List<Map<String, dynamic>> _schedule = [];
  bool _isLoading = true;

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Data Loading Methods
  Future<void> _loadUserData() async {
    try {
      User? user = auth.currentUser;
      if (user != null) {
        DocumentSnapshot userData =
            await firestore.collection('users').doc(user.uid).get();

        if (userData.exists) {
          setState(() {
            _username = userData.get('username') ?? 'Student';
            _email = userData.get('email') ?? user.email ?? '';
          });
          await _loadEnrolledClasses(user.uid);
          await _loadSchedule();
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadEnrolledClasses(String userId) async {
    try {
      // Query the enrolledStudents collection to find classes where the user is enrolled
      QuerySnapshot enrolledSnapshot = await firestore
          .collection('enrolledStudents')
          .where('students', arrayContains: userId)
          .get();

      _enrolledClassIds = enrolledSnapshot.docs.map((doc) => doc.id).toList();

      // Get detailed class information
      List<Map<String, dynamic>> classes = [];
      for (String classId in _enrolledClassIds) {
        DocumentSnapshot classDoc =
            await firestore.collection('classes').doc(classId).get();

        if (classDoc.exists) {
          Map<String, dynamic> classData =
              classDoc.data() as Map<String, dynamic>;
          classes.add({
            'id': classId,
            'classCode': classData['classCode'] ?? '',
            'subject': classData['subject'] ?? '',
            'program': classData['program'] ?? '',
            'teacherId': classData['teacherId'] ?? '',
          });
        }
      }

      setState(() => _enrolledClasses = classes);
    } catch (e) {
      debugPrint('Error loading enrolled classes: $e');
    }
  }

  Future<void> _loadSchedule() async {
    try {
      if (_enrolledClassIds.isEmpty) {
        setState(() => _schedule = []);
        return;
      }

      // Get current day of week
      String today = _getCurrentDayOfWeek();

      // Query schedules for enrolled classes and current day
      QuerySnapshot scheduleSnapshot = await firestore
          .collection('schedule')
          .where('class_id', whereIn: _enrolledClassIds)
          .where('day_of_week', isEqualTo: today)
          .get();

      List<Map<String, dynamic>> todaySchedules = [];

      for (var doc in scheduleSnapshot.docs) {
        Map<String, dynamic> scheduleData = doc.data() as Map<String, dynamic>;
        String classId = scheduleData['class_id'] ?? '';

        // Get class details
        DocumentSnapshot classDoc =
            await firestore.collection('classes').doc(classId).get();

        if (classDoc.exists) {
          Map<String, dynamic> classData =
              classDoc.data() as Map<String, dynamic>;
          String teacherId = classData['teacherId'] ?? '';

          // Get teacher details
          DocumentSnapshot teacherDoc =
              await firestore.collection('users').doc(teacherId).get();

          todaySchedules.add({
            'id': doc.id,
            'classId': classId,
            'className': classData['classCode'] ?? 'No Class Name',
            'subject': classData['subject'] ?? '',
            'teacherName': teacherDoc.exists
                ? teacherDoc.get('username') ?? 'Unknown Teacher'
                : 'Unknown Teacher',
            'startTime': scheduleData['start_time'] ?? '',
            'endTime': scheduleData['end_time'] ?? '',
            'dayOfWeek': scheduleData['day_of_week'] ?? '',
          });
        }
      }

      // Sort by start time
      todaySchedules.sort(
          (a, b) => (a['startTime'] ?? '').compareTo(b['startTime'] ?? ''));

      setState(() => _schedule = todaySchedules);
    } catch (e) {
      debugPrint('Error loading schedule: $e');
    }
  }

  String _getCurrentDayOfWeek() {
    switch (DateTime.now().weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  // Navigation method
  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  // UI Building Methods
  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
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
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.schedule, color: Colors.blue[800]),
        ),
        title: Text(
          schedule['className'] ?? 'No Class Name',
          style: GoogleFonts.golosText(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Teacher: ${schedule['teacherName']}',
              style: GoogleFonts.golosText(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${schedule['startTime']} - ${schedule['endTime']}',
                  style: GoogleFonts.golosText(),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.book, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  schedule['subject'] ?? 'No Subject',
                  style: GoogleFonts.golosText(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Card(
      elevation: 2,
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
                  onPressed: () => _navigateTo(StudentScheduleScreen()),
                  child: Text(
                    'View All',
                    style: GoogleFonts.golosText(color: Colors.blue[800]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('schedule')
                  .where('class_id')
                  .snapshots(),
              builder: (context, scheduleSnapshot) {
                if (scheduleSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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

                // Group schedules by day
                Map<String, List<Map<String, dynamic>>> schedulesByDay = {};
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
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue[800],
                                  borderRadius: BorderRadius.circular(20),
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
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: daySchedules.length,
                          itemBuilder: (context, scheduleIndex) {
                            final scheduleData = daySchedules[scheduleIndex];
                            String classId =
                                scheduleData['class_id'] ?? 'Unknown ID';
                            String startTime = scheduleData['start_time'] ?? '';
                            String endTime = scheduleData['end_time'] ?? '';

                            return FutureBuilder<DocumentSnapshot>(
                              future: firestore
                                  .collection('classes')
                                  .doc(classId)
                                  .get(),
                              builder: (context, classDoc) {
                                if (!classDoc.hasData) {
                                  return const SizedBox.shrink();
                                }

                                final classData = classDoc.data?.data()
                                        as Map<String, dynamic>? ??
                                    <String, dynamic>{};
                                String subject =
                                    classData['subject'] ?? 'Unknown Class';
                                String roomNumber =
                                    classData['roomNumber'] ?? 'No Room';
                                String teacherId = classData['teacherId'] ?? '';

                                return FutureBuilder<DocumentSnapshot>(
                                  future: firestore
                                      .collection('users')
                                      .doc(teacherId)
                                      .get(),
                                  builder: (context, teacherDoc) {
                                    String teacherName = 'Unknown Teacher';
                                    if (teacherDoc.hasData &&
                                        teacherDoc.data != null) {
                                      teacherName = teacherDoc.data!
                                              .get('username')
                                              ?.toString() ??
                                          'Unknown Teacher';
                                    }

                                    return Card(
                                      elevation: 1,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
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
                                              style: GoogleFonts.golosText(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              'Teacher: $teacherName',
                                              style: GoogleFonts.golosText(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              'Room: $roomNumber',
                                              style: GoogleFonts.golosText(
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
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_username),
            accountEmail: Text(_email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.blue[800],
              child: Text(
                _username.isNotEmpty ? _username[0] : 'S',
                style: const TextStyle(fontSize: 40, color: Colors.white),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () => _navigateTo(ProfilePage()),
          ),
          ListTile(
            leading: const Icon(Icons.class_),
            title: const Text('My Classes'),
            onTap: () => _navigateTo(StudentMyClassesScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Schedule'),
            onTap: () => _navigateTo(StudentScheduleScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notices'),
            onTap: () => _navigateTo(StudentNoticesScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Messages'),
            onTap: () => _navigateTo(MessageScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MyApp()),
              );
            },
          ),
        ],
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
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildDashboardCard(
                        icon: Icons.book,
                        title: 'Enrolled Classes',
                        value: '',
                        color: Colors.blue,
                        onTap: () => _navigateTo(StudentMyClassesScreen()),
                      ),
                      _buildDashboardCard(
                        icon: Icons.message,
                        title: 'Leave Request',
                        value: '',
                        color: Colors.purple,
                        onTap: () => _navigateTo(MessageScreen()),
                      ),
                      _buildDashboardCard(
                        icon: Icons.class_,
                        title: 'My Attendance',
                        value: '',
                        color: Colors.orange,
                        onTap: () => _navigateTo(const RecordsScreen()),
                      ),
                      _buildDashboardCard(
                        icon: Icons.notifications,
                        title: 'Notice',
                        value: '',
                        color: Colors.green,
                        onTap: () => _navigateTo(StudentNoticesScreen()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildScheduleSection(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateTo(QRScanner()),
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}
