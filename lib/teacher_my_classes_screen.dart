import 'dart:convert';
import 'package:ams/services/schedule.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
// For date formatting

class TeacherMyClass extends StatefulWidget {
  const TeacherMyClass({super.key});

  @override
  State<TeacherMyClass> createState() => _TeacherMyClassState();
}

class _TeacherMyClassState extends State<TeacherMyClass> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
          'My Classes',
          style: GoogleFonts.golosText(
            fontSize: 20.0,
            fontWeight: FontWeight.w600,
            color: Colors.blue[800],
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('classes')
            .where('teacherId', isEqualTo: _auth.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildNoClassesWidget();
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final classData =
                    snapshot.data!.docs[index].data() as Map<String, dynamic>;

                return _buildClassCard(
                  classData['program'] ?? 'No Program',
                  classData['subject'] ?? 'No Subject',
                  classData['classCode'] ?? 'No Code',
                  (classData['students'] as List<dynamic>?)?.length ?? 0,
                  snapshot.data!.docs[index].id,
                  () {
                    // TODO: Implement navigation to class details
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateClassDialog(),
        tooltip: 'Create New Class',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateClassDialog() {
    String program = '';
    String subject = '';
    String classCode = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Class'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (value) => program = value,
                  decoration: const InputDecoration(
                    labelText: 'Program',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (value) => subject = value,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (value) => classCode = value,
                  decoration: const InputDecoration(
                    labelText: 'Class Code',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (program.isNotEmpty &&
                    subject.isNotEmpty &&
                    classCode.isNotEmpty) {
                  _firestore.collection('classes').add({
                    'teacherId': _auth.currentUser?.uid,
                    'program': program,
                    'subject': subject,
                    'classCode': classCode,
                    'students': [],
                  }).then((_) {
                    Navigator.pop(context);
                  });
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNoClassesWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.class_outlined, size: 64, color: Colors.grey[400]),
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
            'Create a new class to get started',
            style: GoogleFonts.golosText(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(
    String program,
    String subject,
    String classCode,
    int studentCount,
    String classId,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                program,
                style: GoogleFonts.golosText(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Subject: $subject',
                style: GoogleFonts.golosText(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Class Code: $classCode',
                style: GoogleFonts.golosText(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '👥 $studentCount Students Enrolled',
                style: GoogleFonts.golosText(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 10),

              // "Schedule Class" Button
              TextButton(
                onPressed: () {
                  _showDialogBox(classCode, classId);
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Schedule Class',
                  style: GoogleFonts.golosText(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),

              // "Publish Notice" Button
              TextButton(
                onPressed: () {
                  _showPublishNoticeDialog(classId);
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.green[800],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Publish Notice',
                  style: GoogleFonts.golosText(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => Center(
                        child: Container(
                          color: Colors.white,
                          padding: EdgeInsets.all(8),
                          child: QrImageView(
                            data: jsonEncode({"join": classId}),
                            version: QrVersions.auto,
                            size: 200.0,
                          ),
                        ),
                      ),
                    );
                  },
                  child: Icon(
                    Icons.qr_code,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDialogBox(
    String classCode,
    String classId,
  ) {
    String selectedDay = '';
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    final List<String> daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Schedule Class'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Day',
                        border: OutlineInputBorder(),
                      ),
                      items: daysOfWeek.map((String day) {
                        return DropdownMenuItem<String>(
                          value: day,
                          child: Text(day),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDay = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      title: const Text('Start Time'),
                      subtitle: Text(
                        startTime != null
                            ? '${startTime!.hour}:${startTime!.minute.toString().padLeft(2, '0')}'
                            : 'Select Start Time',
                      ),
                      onTap: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            startTime = pickedTime;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      title: const Text('End Time'),
                      subtitle: Text(
                        endTime != null
                            ? '${endTime!.hour}:${endTime!.minute.toString().padLeft(2, '0')}'
                            : 'Select End Time',
                      ),
                      onTap: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            endTime = pickedTime;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedDay.isNotEmpty &&
                        startTime != null &&
                        endTime != null) {
                      // Format the time as HH:MM
                      final formattedStartTime =
                          '${startTime!.hour}:${startTime!.minute.toString().padLeft(2, '0')}';
                      final formattedEndTime =
                          '${endTime!.hour}:${endTime!.minute.toString().padLeft(2, '0')}';

                      addSchedule(classId, selectedDay, formattedStartTime,
                          formattedEndTime);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                    }
                  },
                  child: const Text('Schedule'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPublishNoticeDialog(String classId) {
    String noticeMessage = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Publish Notice'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (value) => noticeMessage = value,
                  decoration: const InputDecoration(
                    labelText: 'Notice Message',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (noticeMessage.isNotEmpty) {
                  // Updated to match your Firebase structure
                  await _firestore.collection('notice').add({
                    'class_id': classId,
                    'date': DateTime.now(),
                    'message': noticeMessage,
                    'publishedBy': _auth.currentUser?.uid,
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notice published successfully!'),
                    ),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a notice message'),
                    ),
                  );
                }
              },
              child: const Text('Publish'),
            ),
          ],
        );
      },
    );
  }
}
