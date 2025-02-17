import 'package:ams/request_message.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MessageScreen extends StatefulWidget {
  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _handleRefresh() async {
    // Wait for a short duration to show the refresh indicator
    await Future.delayed(Duration(milliseconds: 1000));
    setState(() {});
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                'Please log in to view your requests',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Leave Requests',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _handleRefresh,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue[800],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Center(
              child: Text(
                'Your Leave Request History',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('leave_requests')
                    .where('studentEmail', isEqualTo: _auth.currentUser?.email)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.blue[800]!),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.2),
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[400],
                            ),
                            SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'Error loading requests. Please check your internet connection and try again.',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.red[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _handleRefresh,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[800],
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                              child: Text(
                                'Retry',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.2),
                            Icon(
                              Icons.inbox_rounded,
                              size: 70,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No leave requests yet',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  var requests = snapshot.data!.docs;
                  return ListView.builder(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(16),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      var request =
                          requests[index].data() as Map<String, dynamic>;

                      DateTime timestamp = DateTime.now();
                      try {
                        if (request['timestamp'] != null) {
                          timestamp =
                              (request['timestamp'] as Timestamp).toDate();
                        }
                      } catch (e) {
                        print('Error parsing timestamp: $e');
                      }

                      var status = request['status']?.toString() ?? 'pending';
                      var teacherEmail = request['teacherEmail']?.toString() ??
                          'No teacher email';
                      var message =
                          request['message']?.toString() ?? 'No message';
                      var numberOfDays =
                          request['numberOfDays']?.toString() ?? '0';

                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: InkWell(
                          onTap: () => _showRequestDetails(
                              context, request, requests[index].id),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'To: $teacherEmail',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    _buildStatusChip(status),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Text(
                                  message,
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 12),
                                Divider(),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: Colors.blue[800],
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          DateFormat('MMM dd')
                                              .format(timestamp),
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey[700],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '$numberOfDays days',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LeaveRequestPage()),
          );
        },
        backgroundColor: Colors.blue[800],
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'approved':
        chipColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        chipColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        statusIcon = Icons.cancel;
        break;
      default:
        chipColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        statusIcon = Icons.access_time;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 16,
            color: textColor,
          ),
          SizedBox(width: 4),
          Text(
            status[0].toUpperCase() + status.substring(1).toLowerCase(),
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showRequestDetails(
      BuildContext context, Map<String, dynamic> request, String requestId) {
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now();
    try {
      if (request['startDate'] != null) {
        startDate = (request['startDate'] as Timestamp).toDate();
      }
      if (request['endDate'] != null) {
        endDate = (request['endDate'] as Timestamp).toDate();
      }
    } catch (e) {
      print('Error parsing dates: $e');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Leave Request Details',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailRow(
                            'Teacher',
                            request['teacherEmail']?.toString() ??
                                'Not specified'),
                        _detailRow('Faculty',
                            request['faculty']?.toString() ?? 'Not specified'),
                        _detailRow('Reason',
                            request['reason']?.toString() ?? 'Not specified'),
                        _detailRow(
                          'Duration',
                          '${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}',
                        ),
                        _detailRow('Days',
                            '${request['numberOfDays']?.toString() ?? '0'} days'),
                        _detailRow(
                            'Status',
                            (request['status']?.toString() ?? 'pending')
                                .toUpperCase()),
                        SizedBox(height: 20),
                        Text(
                          'Conversation:',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 12),
                        StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('leave_requests')
                              .doc(requestId)
                              .collection('messages')
                              .orderBy('timestamp')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              // Show initial message if no conversation exists
                              return _buildMessageBubble(
                                message: request['message']?.toString() ??
                                    'No message provided',
                                isFromCurrentUser: true,
                                timestamp: request['timestamp'] != null
                                    ? (request['timestamp'] as Timestamp)
                                        .toDate()
                                    : DateTime.now(),
                              );
                            }

                            // Show all messages in the conversation
                            List<Widget> messageWidgets = [];

                            // Add initial message first
                            messageWidgets.add(
                              _buildMessageBubble(
                                message: request['message']?.toString() ??
                                    'No message provided',
                                isFromCurrentUser: true,
                                timestamp: request['timestamp'] != null
                                    ? (request['timestamp'] as Timestamp)
                                        .toDate()
                                    : DateTime.now(),
                              ),
                            );

                            // Add all subsequent messages
                            for (var doc in snapshot.data!.docs) {
                              var messageData =
                                  doc.data() as Map<String, dynamic>;
                              String sender =
                                  messageData['sender']?.toString() ?? '';
                              bool isFromCurrentUser =
                                  sender == _auth.currentUser?.email;

                              messageWidgets.add(
                                _buildMessageBubble(
                                  message:
                                      messageData['text']?.toString() ?? '',
                                  isFromCurrentUser: isFromCurrentUser,
                                  timestamp: messageData['timestamp'] != null
                                      ? (messageData['timestamp'] as Timestamp)
                                          .toDate()
                                      : DateTime.now(),
                                ),
                              );
                            }

                            return Column(
                              children: messageWidgets,
                            );
                          },
                        ),
                        SizedBox(height: 20),
                        if (request['status']?.toString()?.toLowerCase() !=
                            'closed')
                          _buildReplyWidget(requestId),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble({
    required String message,
    required bool isFromCurrentUser,
    required DateTime timestamp,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isFromCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isFromCurrentUser)
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue[700],
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          if (!isFromCurrentUser) SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isFromCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color:
                        isFromCurrentUser ? Colors.blue[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isFromCurrentUser
                          ? Colors.blue[200]!
                          : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    message,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[800],
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy • h:mm a').format(timestamp),
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (isFromCurrentUser) SizedBox(width: 8),
          if (isFromCurrentUser)
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue[700],
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReplyWidget(String requestId) {
    TextEditingController _replyController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(),
        SizedBox(height: 8),
        Text(
          'Reply:',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _replyController,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey[400],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: 3,
                minLines: 1,
              ),
            ),
            SizedBox(width: 8),
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue[700],
              child: IconButton(
                icon: Icon(
                  Icons.send,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (_replyController.text.trim().isNotEmpty) {
                    _sendReply(requestId, _replyController.text.trim());
                    _replyController.clear();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _sendReply(String requestId, String message) async {
    try {
      await _firestore
          .collection('leave_requests')
          .doc(requestId)
          .collection('messages')
          .add({
        'text': message,
        'sender': _auth.currentUser?.email,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending reply: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message. Please try again.'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.grey[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
