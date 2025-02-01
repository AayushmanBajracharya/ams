import 'package:ams/teacher_schedule_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'messages.dart';
import 'profile_screen.dart';
import 'teacher_my_classes_screen.dart';

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
        return data['className'] ?? 'Unknown Class';
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
        iconTheme: IconThemeData(color: Colors.blue[800]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Add notification handling
            },
          ),
        ],
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
                    builder: (context) => MessageScreen(),
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
                                builder: (context) =>
                                    const TeacherMyClass(), // Navigate to the new screen
                              ),
                            );
                          },
                          child: _buildDashboardCard(
                            icon: Icons.class_,
                            title: 'My Classes',
                            value:
                                '$numberOfClasses', // Show the number of classes created
                            color: Colors.blue,
                          ),
                        ),
                        _buildDashboardCard(
                          icon: Icons.people,
                          title: 'Total Students',
                          value: '0',
                          color: Colors.green,
                        ),
                        _buildDashboardCard(
                          icon: Icons.assignment,
                          title: 'Attendance Requests',
                          value: '0',
                          color: Colors.orange,
                        ),
                        _buildDashboardCard(
                          icon: Icons.message,
                          title: 'New Messages',
                          value: '0',
                          color: Colors.purple,
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
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('schedule')
                          .where('teacherId', isEqualTo: _auth.currentUser?.uid)
                          .orderBy('startTime')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Error loading schedule'),
                            ),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No classes scheduled',
                                    style: GoogleFonts.golosText(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final scheduleData = snapshot.data!.docs[index]
                                .data() as Map<String, dynamic>;
                            final classId = scheduleData['classId'] as String;

                            return FutureBuilder<String>(
                              future: _getClassName(classId),
                              builder: (context, classNameSnapshot) {
                                if (classNameSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Card(
                                    child: ListTile(
                                      title: Text('Loading class details...'),
                                    ),
                                  );
                                }

                                final className =
                                    classNameSnapshot.data ?? 'Unknown Class';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8.0),
                                  child: ListTile(
                                    leading: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.blue[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.class_,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                    title: Text(
                                      className,
                                      style: GoogleFonts.golosText(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          scheduleData['subject'] ??
                                              'No Subject',
                                          style: GoogleFonts.golosText(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          scheduleData['day'] ?? 'No Day Set',
                                          style: GoogleFonts.golosText(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          '${_formatTimeString(scheduleData['startTime'])} - ${_formatTimeString(scheduleData['endTime'])}',
                                          style: GoogleFonts.golosText(
                                            color: Colors.blue[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey[400],
                                    ),
                                    onTap: () {
                                      // Navigate to class details or take attendance
                                      // You can use classId here for navigation
                                    },
                                  ),
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
