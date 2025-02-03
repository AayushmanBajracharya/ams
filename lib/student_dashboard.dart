import 'dart:developer';
import 'package:ams/main.dart';
import 'package:ams/qr_scanner.dart';
import 'package:ams/services/schedule.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart';
import 'student_my_class_screen.dart';
import 'records_screen.dart';
import 'messages.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  String _username = '';
  String _email = '';
  List<String> _enrolledClasses = [];
  List<Map<String, dynamic>> _schedule = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSchedule();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = auth.currentUser;
      if (user != null) {
        _email = user.email ?? '';

        DocumentSnapshot userData =
            await firestore.collection('users').doc(user.uid).get();

        if (userData.exists) {
          debugPrint("User data retrieved: ${userData.data()}");
          _enrolledClasses = await getEnrolledClasses();
          setState(() {
            _username = userData.get('username') ?? 'Student';
            _email = userData.get('email') ?? user.email;
          });

          debugPrint("Username set to: $_username");
        } else {
          debugPrint("User document not found in Firestore.");
        }
      } else {
        log("user is null");
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _loadSchedule() async {
    try {
      QuerySnapshot scheduleSnapshot =
          await firestore.collection('schedules').get();
      List<Map<String, dynamic>> schedules = scheduleSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      setState(() {
        _schedule = schedules.where((schedule) {
          return _enrolledClasses.contains(schedule['classId']);
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading schedule: $e');
    }
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
                    builder: (context) => const StudentMyClassesScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.class_),
              title: const Text('Records'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RecordsScreen(),
                  ),
                );
              },
            ),
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
              leading: const Icon(Icons.person_2),
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
            StreamBuilder<QuerySnapshot>(
              stream: firestore.collection('classes').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

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
                                const StudentMyClassesScreen(),
                          ),
                        );
                      },
                      child: _buildDashboardCard(
                        icon: Icons.book,
                        title: 'Enrolled Classes',
                        value: _enrolledClasses.length.toString(),
                        color: Colors.blue,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RecordsScreen(),
                          ),
                        );
                      },
                      child: _buildDashboardCard(
                        icon: Icons.class_,
                        title: 'Records',
                        value: '',
                        color: Colors.orange,
                      ),
                    ),
                    _buildDashboardCard(
                      icon: Icons.notifications_none,
                      title: 'Notice',
                      value: '0',
                      color: Colors.green,
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MessageScreen(),
                          ),
                        );
                      },
                      child: _buildDashboardCard(
                        icon: Icons.message,
                        title: 'New Messages',
                        value: '0',
                        color: Colors.purple,
                      ),
                    ),
                  ],
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
                    Text(
                      'Schedule',
                      style: GoogleFonts.golosText(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _schedule.isEmpty
                        ? const Text('No classes scheduled for today')
                        : Column(
                            children: _schedule.map((schedule) {
                              return ListTile(
                                title: Text(
                                    schedule['className'] ?? 'No Class Name'),
                                subtitle: Text(
                                    '${schedule['time'] ?? 'No Time'} - ${schedule['location'] ?? 'No Location'}'),
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => QRScanner()));
        },
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
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
}
