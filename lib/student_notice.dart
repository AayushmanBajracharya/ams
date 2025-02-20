import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StudentNoticesScreen extends StatefulWidget {
  const StudentNoticesScreen({super.key});

  @override
  State<StudentNoticesScreen> createState() => _StudentNoticesScreenState();
}

class _StudentNoticesScreenState extends State<StudentNoticesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for teacher and class data
  final Map<String, String> _teacherCache = {};
  final Map<String, String> _classCache = {};

  Stream<List<DocumentSnapshot>> _getNoticesStream() async* {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        yield [];
        return;
      }

      // Get user's enrolled classes
      final enrolledClassesSnapshot = await _firestore
          .collection('classes')
          .where('students', arrayContains: currentUser.uid)
          .get();

      if (enrolledClassesSnapshot.docs.isEmpty) {
        yield [];
        return;
      }

      // Get class IDs
      final classIds =
          enrolledClassesSnapshot.docs.map((doc) => doc.id).toList();

      // If classIds are within Firestore limit for 'whereIn'
      if (classIds.length <= 10) {
        yield* _firestore
            .collection('notice')
            .where('class_id', whereIn: classIds)
            .snapshots()
            .map((snapshot) => snapshot.docs);
      } else {
        // Handle in chunks if more than 10
        List<DocumentSnapshot> allNotices = [];
        final chunks = <List<String>>[];

        for (var i = 0; i < classIds.length; i += 10) {
          chunks.add(classIds.sublist(
              i, i + 10 > classIds.length ? classIds.length : i + 10));
        }

        for (final chunk in chunks) {
          final noticesSnapshot = await _firestore
              .collection('notice')
              .where('class_id', whereIn: chunk)
              .orderBy('date', descending: true)
              .get();

          allNotices.addAll(noticesSnapshot.docs);
        }

        allNotices.sort((a, b) {
          final aDate = (a.data() as Map<String, dynamic>)['date'] as Timestamp;
          final bDate = (b.data() as Map<String, dynamic>)['date'] as Timestamp;
          return bDate.compareTo(aDate);
        });

        yield allNotices;
      }
    } catch (e, stackTrace) {
      debugPrint('Stack Trace: $stackTrace');
      yield [];
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Today - show time
      return 'Today at ${DateFormat('h:mm a').format(dateTime)}';
    } else if (difference.inDays == 1) {
      // Yesterday - show time
      return 'Yesterday at ${DateFormat('h:mm a').format(dateTime)}';
    } else if (difference.inDays < 7) {
      // Within a week - show day and time
      return '${DateFormat('EEEE').format(dateTime)} at ${DateFormat('h:mm a').format(dateTime)}';
    } else {
      // Older - show full date and time
      return DateFormat('MMM d, y \'at\' h:mm a').format(dateTime);
    }
  }

  Future<String> _getTeacherName(String teacherId) async {
    if (_teacherCache.containsKey(teacherId)) {
      return _teacherCache[teacherId]!;
    }

    try {
      final teacherDoc =
          await _firestore.collection('users').doc(teacherId).get();

      final teacherName = teacherDoc.data()?['username'] ?? 'Unknown Teacher';
      _teacherCache[teacherId] = teacherName;
      return teacherName;
    } catch (e) {
      return 'Unknown Teacher';
    }
  }

  Future<String> _getSubject(String classId) async {
    if (_classCache.containsKey(classId)) {
      return _classCache[classId]!;
    }

    try {
      final classDoc =
          await _firestore.collection('classes').doc(classId).get();

      final subject = classDoc.data()?['subject'] ?? 'Unknown Subject';
      _classCache[classId] = subject;
      return subject;
    } catch (e) {
      return 'Unknown Subject';
    }
  }

  Widget _buildNoticeCard(
      Map<String, dynamic> notice, String teacherName, String subject) {
    final timestamp = notice['date'] as Timestamp;
    final formattedDate = _formatTimestamp(timestamp);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () =>
            _showNoticeDetails(notice, teacherName, subject, formattedDate),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                          notice['message'] ?? '',
                          style: GoogleFonts.golosText(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.grey[300]),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            teacherName,
                            style: GoogleFonts.golosText(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: GoogleFonts.golosText(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoticeDetails(Map<String, dynamic> notice, String teacherName,
      String subject, String formattedDate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject,
                style: GoogleFonts.golosText(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                notice['message'] ?? '',
                style: GoogleFonts.golosText(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Published by $teacherName',
                      style: GoogleFonts.golosText(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: GoogleFonts.golosText(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        title: Text(
          'Notices',
          style: GoogleFonts.golosText(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: _getNoticesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading notices',
                style: GoogleFonts.golosText(color: Colors.red),
              ),
            );
          }

          final notices = snapshot.data ?? [];

          if (notices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No notices yet',
                    style: GoogleFonts.golosText(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final notice = notices[index].data() as Map<String, dynamic>;

              return FutureBuilder<Map<String, String>>(
                future: Future.wait([
                  _getTeacherName(notice['publishedBy']),
                  _getSubject(notice['class_id']),
                ]).then((values) => {
                      'teacherName': values[0],
                      'subject': values[1],
                    }),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  return _buildNoticeCard(
                    notice,
                    snapshot.data!['teacherName']!,
                    snapshot.data!['subject']!,
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
