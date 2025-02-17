import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TeacherMessageScreen extends StatefulWidget {
  @override
  _TeacherMessageScreenState createState() => _TeacherMessageScreenState();
}

class _TeacherMessageScreenState extends State<TeacherMessageScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<DocumentSnapshot> _leaveRequests = [];

  @override
  void initState() {
    super.initState();
    _fetchLeaveRequests();
  }

  Future<void> _fetchLeaveRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? teacherEmail = _auth.currentUser?.email;
      if (teacherEmail != null) {
        // Modified query to use only one ordering parameter
        QuerySnapshot querySnapshot = await _firestore
            .collection('leave_requests')
            .where('teacherEmail', isEqualTo: teacherEmail.toLowerCase())
            .get();

        setState(() {
          _leaveRequests = querySnapshot.docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching leave requests: ${e.toString()}");

      // Check if the error is related to missing index
      if (e.toString().contains("FAILED_PRECONDITION") &&
          e.toString().contains("requires an index")) {
        // Show a more helpful error message with link to create index
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Firestore Index Required',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Please click the link in your console to create the required index, then try again.',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 10),
          ),
        );
      } else {
        // Show generic error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error fetching leave requests: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateLeaveRequestStatus(String docId, String status) async {
    try {
      await _firestore.collection('leave_requests').doc(docId).update({
        'status': status,
        'responseTimestamp': FieldValue.serverTimestamp(),
        'respondedBy': _auth.currentUser?.email,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Leave request $status successfully!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: status == 'approved' ? Colors.green : Colors.orange,
        ),
      );

      _fetchLeaveRequests(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error updating status: ${e.toString()}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue[800],
        title: Text(
          'Student Leave Requests',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchLeaveRequests,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
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
                    shadowColor: Color.fromARGB(66, 0, 0, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Text(
                        'Manage student leave requests by approving or rejecting them',
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

          // Message List Section
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.blue[800]!),
                    ),
                  )
                : _leaveRequests.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _leaveRequests.length,
                        itemBuilder: (context, index) {
                          var request = _leaveRequests[index];
                          Map<String, dynamic> data =
                              request.data() as Map<String, dynamic>;
                          return _buildLeaveRequestCard(request.id, data);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No leave requests yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'When students submit leave requests, they will appear here',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveRequestCard(String docId, Map<String, dynamic> data) {
    Timestamp? startTimestamp = data['startDate'] as Timestamp?;
    Timestamp? endTimestamp = data['endDate'] as Timestamp?;
    DateTime? startDate = startTimestamp?.toDate();
    DateTime? endDate = endTimestamp?.toDate();
    String formattedDateRange = '';

    if (startDate != null && endDate != null) {
      String start = DateFormat('MMM dd, yyyy').format(startDate);
      String end = DateFormat('MMM dd, yyyy').format(endDate);
      formattedDateRange = '$start to $end';
    }

    String status = data['status'] ?? 'pending';

    Color statusColor;
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'From: ${data['studentEmail'] ?? 'Unknown Student'}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildInfoRow(
                Icons.school, 'Faculty', data['faculty'] ?? 'Not specified'),
            SizedBox(height: 8),
            _buildInfoRow(Icons.business, 'Department',
                data['department'] ?? 'Not specified'),
            SizedBox(height: 8),
            _buildInfoRow(Icons.date_range, 'Duration', formattedDateRange),
            SizedBox(height: 8),
            _buildInfoRow(
                Icons.category, 'Reason', data['reason'] ?? 'Not specified'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detailed Reason:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    data['message'] ?? 'No additional details provided.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (status == 'pending') ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _updateLeaveRequestStatus(docId, 'rejected'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Reject',
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _updateLeaveRequestStatus(docId, 'approved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Approve',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.blue[800]),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
