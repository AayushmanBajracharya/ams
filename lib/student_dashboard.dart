import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart';
import 'student_my_class_screen.dart';
import 'student_active_class.dart';
import 'messages.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _username = '';
  String _email = '';
  List<Map<String, dynamic>> _enrolledClasses = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        _email = user.email ?? '';

        DocumentSnapshot userData =
            await _firestore.collection('users').doc(user.uid).get();

        if (userData.exists) {
          // Debugging: Print the entire document data
          debugPrint("User data retrieved: ${userData.data()}");

          setState(() {
            _username = userData.get('username') ?? 'Student';
            _email = userData.get('email') ?? user.email;
            _enrolledClasses = List<Map<String, dynamic>>.from(
                userData.get('enrolledClasses') ?? []);
          });

          debugPrint("Username set to: $_username"); // Debugging
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

  Future<void> _handleLogout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error signing out. Please try again.')),
      );
    }
  }

  void _showJoinClassDialog() {
    TextEditingController subjectController = TextEditingController();
    TextEditingController classCodeController = TextEditingController();
    TextEditingController programController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Join a Class',
            style: GoogleFonts.golosText(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: programController,
                decoration: InputDecoration(
                  labelText: 'Program',
                  labelStyle: GoogleFonts.golosText(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  labelStyle: GoogleFonts.golosText(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: classCodeController,
                decoration: InputDecoration(
                  labelText: 'Class Code',
                  labelStyle: GoogleFonts.golosText(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.golosText(
                  color: Colors.red,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                String subject = subjectController.text.trim();
                String classCode = classCodeController.text.trim();
                String program = programController.text.trim();

                if (subject.isNotEmpty &&
                    classCode.isNotEmpty &&
                    program.isNotEmpty) {
                  try {
                    // Check if the class exists in the database
                    QuerySnapshot classSnapshot = await _firestore
                        .collection('classes')
                        .where('subject', isEqualTo: subject)
                        .where('classCode', isEqualTo: classCode)
                        .where('program', isEqualTo: program)
                        .get();

                    if (classSnapshot.docs.isNotEmpty) {
                      // Class exists, add it to the user's enrolled classes
                      User? user = _auth.currentUser;
                      if (user != null) {
                        await _firestore
                            .collection('users')
                            .doc(user.uid)
                            .update({
                          'enrolledClasses': FieldValue.arrayUnion([
                            {
                              'subject': subject,
                              'classCode': classCode,
                              'program': program,
                            }
                          ]),
                        });

                        setState(() {
                          _enrolledClasses.add({
                            'subject': subject,
                            'classCode': classCode,
                            'program': program,
                          });
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Successfully joined $subject',
                              style: GoogleFonts.golosText(),
                            ),
                          ),
                        );

                        Navigator.of(context).pop();
                      }
                    } else {
                      // Class does not exist
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Class does not exist. Please check the subject, class code, and program.',
                            style: GoogleFonts.golosText(),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('Error joining class: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error joining class. Please try again.',
                          style: GoogleFonts.golosText(),
                        ),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please fill in all fields',
                        style: GoogleFonts.golosText(),
                      ),
                    ),
                  );
                }
              },
              child: Text(
                'Join',
                style: GoogleFonts.golosText(
                  color: Colors.blue[800],
                ),
              ),
            ),
          ],
        );
      },
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
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const StudentMyClassesScreen(), // Navigate to the student's classes screen
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.class_),
              title: const Text('Active CLasses'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ActiveClassScreen(), // Correct instantiation
                  ),
                );
              },
            ),
            // In the Drawer section of StudentDashboard, replace the existing Messages ListTile with:
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Messages'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MessageScreen(), // Navigate to MessageScreen
                  ),
                );
              },
            ),

// Close the drawer

            ListTile(
              leading: const Icon(Icons.person_2),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProfilePage(), // Correct instantiation
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
              stream: _firestore.collection('classes').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                List<DocumentSnapshot> activeClasses =
                    snapshot.data?.docs ?? [];

                int activeEnrolledClasses = activeClasses.where((classDoc) {
                  Map<String, dynamic> classData =
                      classDoc.data() as Map<String, dynamic>;
                  return _enrolledClasses.any((enrolledClass) =>
                      enrolledClass['classCode'] == classData['classCode']);
                }).length;

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildDashboardCard(
                      icon: Icons.book,
                      title: 'Enrolled Classes',
                      value: _enrolledClasses.length.toString(),
                      color: Colors.blue,
                    ),
                    _buildDashboardCard(
                      icon: Icons.class_,
                      title: 'Active Classes',
                      value: activeEnrolledClasses.toString(),
                      color: Colors.orange,
                    ),
                    _buildDashboardCard(
                      icon: Icons.people,
                      title: 'Classmates',
                      value: '0',
                      color: Colors.green,
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
                    const Text('No classes scheduled for today'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showJoinClassDialog,
        child: const Icon(Icons.add),
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
