import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

class AttendanceclassDetailsScreen extends StatefulWidget {
  final String classId;
  final String className;
  const AttendanceclassDetailsScreen({
    Key? key,
    required this.classId,
    required this.className,
  }) : super(key: key);
  @override
  State<AttendanceclassDetailsScreen> createState() =>
      _ClassAttendanceScreenState();
}

class _ClassAttendanceScreenState extends State<AttendanceclassDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
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
          'Class List',
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
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final classData =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final classId = snapshot.data!.docs[index].id;
              return _buildClassCard(
                classData,
                classId,
              );
            },
          );
        },
      ),
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
            'No classes available',
            style: GoogleFonts.golosText(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create classes in My Classes section',
            style: GoogleFonts.golosText(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> classData, String classId) {
    final String subject = classData['subject'] ?? 'No Subject';
    final String program = classData['program'] ?? 'No Program';
    final String classCode = classData['classCode'] ?? 'No Code';
    final int studentCount =
        (classData['students'] as List<dynamic>?)?.length ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to attendance details screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AttendanceDetailsScreen(
                classId: classId,
                className: subject,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject,
                          style: GoogleFonts.golosText(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          program,
                          style: GoogleFonts.golosText(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$studentCount Students',
                      style: GoogleFonts.golosText(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Class Code: $classCode',
                    style: GoogleFonts.golosText(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AttendanceDetailsScreen extends StatefulWidget {
  final String classId;
  final String className;
  const AttendanceDetailsScreen({
    Key? key,
    required this.classId,
    required this.className,
  }) : super(key: key);
  @override
  State<AttendanceDetailsScreen> createState() =>
      _AttendanceDetailsScreenState();
}

class _AttendanceDetailsScreenState extends State<AttendanceDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      await Future.delayed(Duration.zero);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Stream<List<Map<String, dynamic>>> _getAttendanceStream() {
    return _firestore
        .collection('enrolledStudents')
        .where('classId', isEqualTo: widget.classId)
        .snapshots()
        .asyncMap((studentsSnapshot) async {
      var attendanceSnapshot = await _firestore
          .collection('attendance')
          .where('classId', isEqualTo: widget.classId)
          .where('date', isEqualTo: today)
          .get();

      print(
          "Debug: Number of attendance records found: ${attendanceSnapshot.docs.length}");

      // Create a map for quick lookup
      Map<String, String> attendanceMap = {};
      for (var doc in attendanceSnapshot.docs) {
        var data = doc.data();
        var studentId = data['studentId'] as String? ?? ''; // Ensure valid key
        var status = data['status'] as String? ?? 'N/A';

        // Print to verify studentId and status
        print("Debug: Found attendance for $studentId with status: $status");

        if (studentId.isNotEmpty) {
          attendanceMap[studentId] = status;
        }
      }

      return studentsSnapshot.docs.map((studentDoc) {
        var data = studentDoc.data();
        var studentId = data['studentId'] as String? ??
            ''; // Use the studentId field here, not studentDoc.id

        print(
            "Debug: Processing student: ${data['studentName']} with ID: $studentId");

        // Fetch the correct status from attendanceMap
        String status = attendanceMap[studentId] ?? 'N/A';
        print("Debug: Found status for student $studentId: $status");

        return {
          'studentId': studentId,
          'studentName': data['studentName'] ?? 'Unknown Student',
          'status': status,
          'date': today,
        };
      }).toList();
    });
  }

  Future<void> _updateStudentInfo(
      String studentId, String newName, String newStatus) async {
    try {
      // Update the student's name in the enrolledStudents collection
      var studentQuery = await _firestore
          .collection('enrolledStudents')
          .where('studentId', isEqualTo: studentId)
          .where('classId', isEqualTo: widget.classId)
          .get();

      if (studentQuery.docs.isNotEmpty) {
        await studentQuery.docs.first.reference.update({
          'studentName': newName,
        });
      } else {
        print("Error: Student $studentId does not exist in enrolledStudents.");
        return;
      }

      // Update the attendance record for today
      var attendanceQuery = await _firestore
          .collection('attendance')
          .where('studentId', isEqualTo: studentId)
          .where('classId', isEqualTo: widget.classId)
          .where('date', isEqualTo: today)
          .get();

      if (attendanceQuery.docs.isNotEmpty) {
        await attendanceQuery.docs.first.reference.update({
          'status': newStatus,
          'studentName': newName, // Keep names consistent
        });
      } else {
        // Create a new attendance record if it doesn't exist
        await _firestore.collection('attendance').add({
          'classId': widget.classId,
          'studentId': studentId,
          'studentName': newName,
          'date': today,
          'status': newStatus,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student information updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error updating student information: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update student information.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveAttendanceRecord(
      String studentId, String studentName, String status) async {
    try {
      // Check if there's an existing record for today
      var existingRecord = await _firestore
          .collection('savedAttendance')
          .where('classId', isEqualTo: widget.classId)
          .where('date', isEqualTo: today)
          .get();

      if (existingRecord.docs.isNotEmpty) {
        // Update existing record
        var doc = existingRecord.docs.first;
        List<dynamic> attendanceList = List.from(doc['attendanceList'] ?? []);

        // Find and update or add student record
        int studentIndex =
            attendanceList.indexWhere((item) => item['studentId'] == studentId);
        Map<String, dynamic> studentRecord = {
          'studentId': studentId,
          'studentName': studentName,
          'status': status,
          'date': today,
        };

        if (studentIndex >= 0) {
          attendanceList[studentIndex] = studentRecord;
        } else {
          attendanceList.add(studentRecord);
        }

        await doc.reference.update({
          'attendanceList': attendanceList,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new record
        await _firestore.collection('savedAttendance').add({
          'classId': widget.classId,
          'className': widget.className,
          'date': today,
          'attendanceList': [
            {
              'studentId': studentId,
              'studentName': studentName,
              'status': status,
              'date': today,
            }
          ],
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Error saving attendance record: $e");
      throw e;
    }
  }

  Future<void> _saveAttendanceList(
      List<Map<String, dynamic>> attendanceList) async {
    try {
      // Check if there's an existing record for today
      var existingRecord = await _firestore
          .collection('savedAttendance')
          .where('classId', isEqualTo: widget.classId)
          .where('date', isEqualTo: today)
          .get();

      if (existingRecord.docs.isNotEmpty) {
        // Update existing record
        await existingRecord.docs.first.reference.update({
          'attendanceList': attendanceList,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new record
        await _firestore.collection('savedAttendance').add({
          'classId': widget.classId,
          'className': widget.className,
          'date': today,
          'attendanceList': attendanceList,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance list saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error saving attendance list: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save attendance list.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exportAttendanceList(
      List<Map<String, dynamic>> currentAttendance) async {
    try {
      showDialog(
        context: context,
        builder: (context) => DateRangePickerDialog(
          onDateRangeSelected: (startDate, endDate) async {
            // Fetch saved attendance data from the date range
            var savedAttendanceSnapshot = await _firestore
                .collection('savedAttendance')
                .where('classId', isEqualTo: widget.classId)
                .where('date',
                    isGreaterThanOrEqualTo:
                        DateFormat('yyyy-MM-dd').format(startDate))
                .where('date',
                    isLessThanOrEqualTo:
                        DateFormat('yyyy-MM-dd').format(endDate))
                .orderBy('date')
                .get();

            List<List<dynamic>> rows = [
              ['Date', 'Class Name', 'Student Name', 'Status']
            ];

            for (var doc in savedAttendanceSnapshot.docs) {
              var data = doc.data();
              String className = data['className'] ?? widget.className;
              List<dynamic> attendanceList = data['attendanceList'] ?? [];

              for (var attendance in attendanceList) {
                rows.add([
                  attendance['date'],
                  className,
                  attendance['studentName'],
                  attendance['status'],
                ]);
              }
            }

            String csvData = const ListToCsvConverter().convert(rows);
            final directory = await getExternalStorageDirectory();
            final fileName =
                'attendance_${widget.className}_${DateFormat('yyyy-MM-dd').format(startDate)}_to_${DateFormat('yyyy-MM-dd').format(endDate)}.csv';
            final file = File('${directory?.path}/$fileName');
            await file.writeAsString(csvData);

            final xFile = XFile(file.path);

            // Share the file
            await Share.shareXFiles(
              [xFile],
              text: 'Attendance Report',
            );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Attendance list exported successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      );
    } catch (e) {
      print("Error exporting attendance list: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to export attendance list.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditDialog(String studentId, String studentName, String status) {
    TextEditingController nameController =
        TextEditingController(text: studentName);
    TextEditingController statusController =
        TextEditingController(text: status);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Edit Student Information',
            style: GoogleFonts.golosText(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Student Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: statusController,
                decoration: const InputDecoration(
                  labelText: 'Status (P/A)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _updateStudentInfo(
                  studentId,
                  nameController.text,
                  statusController.text.toUpperCase(),
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[500],
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
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.blue[600]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.className,
          style: GoogleFonts.golosText(
            fontSize: 20.0,
            fontWeight: FontWeight.w600,
            color: Colors.blue[600],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.blue[600]),
            onPressed: () => setState(() {}),
          ),
        ],
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getAttendanceStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final attendanceList = snapshot.data!;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Date: $today',
                      style: GoogleFonts.golosText(
                        fontSize: 16,
                        color: Colors.blue[600],
                      ),
                    ),
                    Text(
                      '${attendanceList.length} Students',
                      style: GoogleFonts.golosText(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: attendanceList.length,
                  itemBuilder: (context, index) {
                    final attendance = attendanceList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: attendance['status'] == 'P'
                              ? Colors.green.withOpacity(0.2)
                              : attendance['status'] == 'A'
                                  ? Colors.red.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.2),
                          child: Text(
                            attendance['status'],
                            style: TextStyle(
                              color: attendance['status'] == 'P'
                                  ? Colors.green
                                  : attendance['status'] == 'A'
                                      ? Colors.red
                                      : Colors.grey,
                            ),
                          ),
                        ),
                        title: Text(
                          attendance['studentName'],
                          style: GoogleFonts.golosText(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue[600]),
                          onPressed: () => _showEditDialog(
                            attendance['studentId'],
                            attendance['studentName'],
                            attendance['status'],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _saveAttendanceList(attendanceList),
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[500],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _exportAttendanceList(attendanceList),
                      icon: const Icon(Icons.download),
                      label: const Text('Export'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[400],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  // ... (Rest of the UI code remains the same)
}

class DateRangePickerDialog extends StatefulWidget {
  final Function(DateTime, DateTime) onDateRangeSelected;

  const DateRangePickerDialog({
    Key? key,
    required this.onDateRangeSelected,
  }) : super(key: key);

  @override
  State<DateRangePickerDialog> createState() => _DateRangePickerDialogState();
}

class _DateRangePickerDialogState extends State<DateRangePickerDialog> {
  DateTime? startDate;
  DateTime? endDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Date Range',
          style: GoogleFonts.golosText(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Start Date'),
            subtitle: Text(startDate != null
                ? DateFormat('yyyy-MM-dd').format(startDate!)
                : 'Select start date'),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => startDate = date);
              }
            },
          ),
          ListTile(
            title: const Text('End Date'),
            subtitle: Text(endDate != null
                ? DateFormat('yyyy-MM-dd').format(endDate!)
                : 'Select end date'),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => endDate = date);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: startDate != null && endDate != null
              ? () {
                  widget.onDateRangeSelected(startDate!, endDate!);
                  Navigator.pop(context);
                }
              : null,
          child: const Text('Export'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[500],
          ),
        ),
      ],
    );
  }
}
