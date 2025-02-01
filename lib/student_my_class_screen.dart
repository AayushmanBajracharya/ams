import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentMyClassesScreen extends StatefulWidget {
  const StudentMyClassesScreen({super.key});

  @override
  State<StudentMyClassesScreen> createState() => _StudentMyClassesScreenState();
}

class _StudentMyClassesScreenState extends State<StudentMyClassesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to handle leaving a class
  Future<void> _leaveClass(String subject, String classCode) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Remove the class from the user's enrolledClasses list
        await _firestore.collection('users').doc(user.uid).update({
          'enrolledClasses': FieldValue.arrayRemove([
            {'subject': subject, 'classCode': classCode}
          ]),
        });

        // Remove the student from the class's students list
        final classQuery = await _firestore
            .collection('classes')
            .where('subject', isEqualTo: subject)
            .where('classCode', isEqualTo: classCode)
            .get();

        if (classQuery.docs.isNotEmpty) {
          final classDoc = classQuery.docs.first;
          await classDoc.reference.update({
            'students': FieldValue.arrayRemove([user.uid]),
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You have left $subject'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error leaving class: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Classes',
          style: GoogleFonts.golosText(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('users')
            .doc(_auth.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No classes found'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final enrolledClasses =
              userData['enrolledClasses'] as List<dynamic>? ?? [];

          if (enrolledClasses.isEmpty) {
            return const Center(
                child: Text('You are not enrolled in any classes'));
          }

          return ListView.builder(
            itemCount: enrolledClasses.length,
            itemBuilder: (context, index) {
              final classData = enrolledClasses[index] as Map<String, dynamic>;
              final subject = classData['subject']?.toString() ?? 'No Subject';
              final classCode = classData['classCode']?.toString() ?? 'No Code';

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore
                    .collection('classes')
                    .where('subject', isEqualTo: subject)
                    .where('classCode', isEqualTo: classCode)
                    .get()
                    .then((snapshot) => snapshot.docs.first),
                builder: (context, classSnapshot) {
                  if (classSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Card(
                      margin: EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text('Loading...'),
                      ),
                    );
                  }

                  if (classSnapshot.hasError || !classSnapshot.hasData) {
                    return Card(
                      margin: EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text('Error loading class details'),
                      ),
                    );
                  }

                  final classDetails =
                      classSnapshot.data!.data() as Map<String, dynamic>;
                  final enrolledStudents =
                      classDetails['enrolledStudents'] as List<dynamic>? ?? [];

                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                subject,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.exit_to_app,
                                    color: Colors.red),
                                onPressed: () {
                                  _leaveClass(subject, classCode);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Class Code: $classCode',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enrolled Students: ${enrolledStudents.length}',
                            style: TextStyle(
                              fontSize: 14,
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
    );
  }
}
