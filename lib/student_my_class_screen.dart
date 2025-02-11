import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentMyClassesScreen extends StatefulWidget {
  @override
  _StudentMyClassesScreenState createState() => _StudentMyClassesScreenState();
}

class _StudentMyClassesScreenState extends State<StudentMyClassesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchEnrolledClasses() async {
    String? userId = _auth.currentUser?.uid;

    if (userId == null) {
      print("User is not logged in");
      return [];
    }

    print("Logged-in Student ID: $userId"); // Debugging

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('classes')
          .where('students', arrayContains: userId)
          .get();

      List<Map<String, dynamic>> classes = [];

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> classData = doc.data() as Map<String, dynamic>;

        print("Class Found: ${classData['subject']}");

        // Fetch teacher's name from users collection
        if (classData.containsKey('teacherId')) {
          DocumentSnapshot teacherDoc = await _firestore
              .collection('users')
              .doc(classData['teacherId'])
              .get();

          if (teacherDoc.exists) {
            classData['username'] = teacherDoc['username'] ?? 'Unknown';
          } else {
            classData['username'] = 'Unknown';
          }
        } else {
          classData['username'] = 'Unknown';
        }

        classes.add({
          'id': doc.id,
          ...classData,
        });
      }

      print("Fetched Classes Count: ${classes.length}");
      return classes;
    } catch (e) {
      print("Error fetching classes: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Classes',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchEnrolledClasses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.blueAccent,
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading classes: ${snapshot.error}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'You are not enrolled in any classes.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            );
          }

          List<Map<String, dynamic>> classes = snapshot.data!;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              var classData = classes[index];
              try {
                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      // Navigate to class details screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ClassDetailsScreen(classData: classData),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            classData['subject'] ?? 'No subject',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Teacher: ${classData['username'] ?? 'Unknown'}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Schedule: ${classData['schedule'] ?? 'Not available'}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } catch (e) {
                print('Error displaying class: $e');
                return SizedBox(); // Return an empty widget if an error occurs
              }
            },
          );
        },
      ),
    );
  }
}

// Class Details Screen
class ClassDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> classData;

  ClassDetailsScreen({required this.classData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          classData['subject'] ?? 'Class Details',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Class: ${classData['subject'] ?? 'No subject'}",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Teacher: ${classData['username'] ?? 'Unknown'}",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Schedule: ${classData['schedule'] ?? 'Not available'}",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
