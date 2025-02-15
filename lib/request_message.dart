import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class LeaveRequestPage extends StatefulWidget {
  @override
  _LeaveRequestPageState createState() => _LeaveRequestPageState();
}

class _LeaveRequestPageState extends State<LeaveRequestPage> {
  final TextEditingController _teacherEmailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedFaculty = 'School of Arts';
  String _selectedReason = 'Medical Leave';
  String _selectedDepartment = 'Department of Music';
  bool _isLoading = false;
  int _leaveDays = 0;

  final List<String> _faculties = [
    'School of Arts',
    'School of Education',
    'School of Engineering',
    'School of Law',
    'School of Management',
    'School of Science'
  ];

  final List<String> _leaveReasons = [
    'Medical Leave',
    'Family Emergency',
    'Personal Reasons',
    'Academic Event',
    'Other'
  ];

  final List<String> _department = [
    'Department of Arts and Design',
    'Department of Development Studies',
    'Department of Languages and Mass Communication',
    'Department of Music',
    'Continuing and Professional Education Centre',
    'Department of Development Education',
    'Department of Educational Leadership',
    'Department of Inclusive Education, ECD and Professional Studies',
    'Department of Language Education',
    'Department of STEAM Education',
    'Department of Architecture',
    'Department of Artificial intelligence',
    'Department of Chemical Science and Engineering',
    'Department of Civil Engineering',
    'Department of Computer Science and Engineering',
    'Department of Electrical and Electronics Engineering',
    'Department of Geomatics Engineering',
    'Department of Health informatics',
    'Department of Mechanical Engineering',
    'Department of Finance, Economics and Accounting',
    'Department of Human Resource and General Management',
    'Department of Management Informatics and Communication',
    'Department of Management Science and Information',
    'Department of Marketing and Entrepreneurship',
    'Department of Public Policy and Management',
    'Department of Agriculture',
    'Department of Biotechnology',
    'Department of Environmental Science and Engineering',
    'Department of Mathematics',
    'Department of Pharmacy',
    'Department of Physics',
    'Department of Law',
    'Department of MedicalScience',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue[800],
        title: Text(
          'Submit Leave Request',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section with Wave Design
              Container(
                height: 100,
                child: Stack(
                  children: [
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.blue[800],
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Card(
                        elevation: 8,
                        shadowColor: const Color.fromARGB(66, 0, 0, 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Text(
                            'Fill in the details below to submit your leave request',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildSectionTitle('Teacher Information'),
                    const SizedBox(height: 10),
                    _buildTextField(
                      controller: _teacherEmailController,
                      label: "Teacher's Email",
                      icon: Icons.email,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter teacher\'s email';
                        }
                        if (!value!.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 25),
                    _buildSectionTitle('Leave Details'),
                    const SizedBox(height: 10),
                    _buildDropdown(
                      'Select Faculty',
                      _selectedFaculty,
                      _faculties,
                      Icons.school,
                      (String? value) {
                        if (value != null) {
                          setState(() => _selectedFaculty = value);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildDropdown(
                      'Select Department',
                      _selectedDepartment,
                      _department,
                      Icons.school,
                      (String? value) {
                        if (value != null) {
                          setState(() => _selectedDepartment = value);
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildDropdown(
                      'Reason for Leave',
                      _selectedReason,
                      _leaveReasons,
                      Icons.category,
                      (String? value) {
                        if (value != null) {
                          setState(() => _selectedReason = value);
                        }
                      },
                    ),
                    const SizedBox(height: 25),
                    _buildSectionTitle('Duration'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDatePicker(
                            'Start Date',
                            _startDate,
                            () => _selectDate(true),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildDatePicker(
                            'End Date',
                            _endDate,
                            () => _selectDate(false),
                          ),
                        ),
                      ],
                    ),
                    if (_leaveDays > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Container(
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.date_range, color: Colors.blue[800]),
                              const SizedBox(width: 10),
                              Text(
                                'Total Leave Days: $_leaveDays',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 25),
                    _buildSectionTitle('Additional Information'),
                    const SizedBox(height: 10),
                    _buildTextField(
                      controller: _messageController,
                      label: 'Detailed Reason',
                      icon: Icons.message,
                      maxLines: 4,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please provide detailed reason';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    _buildSubmitButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.blue[800],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: Colors.blue[800]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[800]!),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[400]!),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    IconData icon,
    void Function(String?) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Expanded(
        // Wrap it inside Expanded to avoid overflow
        child: DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
            prefixIcon: Icon(icon, color: Colors.blue[800]),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 15),
          ),
          isExpanded: true, // Ensures dropdown stays within the screen
          items: items.map((String item) {
            return DropdownMenuItem(
              value: item,
              child: Tooltip(
                message: item, // Show full text on hover or long press
                child: Text(
                  item,
                  style: GoogleFonts.poppins(),
                  overflow: TextOverflow.ellipsis, // Prevents text overflow
                  maxLines: 1,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue[800], size: 20),
                const SizedBox(width: 8),
                Text(
                  date != null
                      ? DateFormat('MMM dd, yyyy').format(date)
                      : 'Select Date',
                  style: GoogleFonts.poppins(
                    color: date != null ? Colors.black87 : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[800],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: _isLoading ? null : _submitLeaveRequest,
        child: _isLoading
            ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              )
            : Text(
                'Submit Leave Request',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[800]!,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null) {
            _calculateLeaveDays();
          }
        } else {
          _endDate = picked;
          if (_startDate != null) {
            _calculateLeaveDays();
          }
        }
      });
    }
  }

  void _calculateLeaveDays() {
    if (_startDate != null && _endDate != null) {
      setState(() {
        _leaveDays = _endDate!.difference(_startDate!).inDays + 1;
      });
    }
  }

  Future<void> _submitLeaveRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Trim and lowercase email to match Firestore data
      String teacherEmail = _teacherEmailController.text.trim().toLowerCase();

      // Query Firestore to check if the email exists and belongs to a teacher
      var querySnapshot = await _firestore
          .collection(
              'users') // Adjust this collection name as per your Firestore structure
          .where('email', isEqualTo: teacherEmail)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw 'Enter a valid KU email address.';
      }

      var teacherData = querySnapshot.docs.first.data();

      // Check if the role is 'teacher'
      if (teacherData['role'] != 'teacher') {
        throw 'Enter a valid KU teacher email address.';
      }

      var currentUser = _auth.currentUser;

      // Proceed with submitting leave request
      await _firestore.collection('leave_requests').add({
        'teacherEmail': teacherEmail,
        'studentId': currentUser?.uid,
        'studentEmail': currentUser?.email,
        'faculty': _selectedFaculty,
        'department': _selectedDepartment,
        'startDate': _startDate,
        'endDate': _endDate,
        'numberOfDays': _leaveDays,
        'reason': _selectedReason,
        'message': _messageController.text.trim(),
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Leave request submitted successfully!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
