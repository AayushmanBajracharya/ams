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
      debugPrint('Fetching enrolled classes...');
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('No user logged in');
        yield [];
        return;
      }

      // 🔹 Get enrolled classes
      final classesQuery = await _firestore
          .collection('classes')
          .where('students', arrayContains: currentUser.uid)
          .get();

      if (classesQuery.docs.isEmpty) {
        debugPrint('No enrolled classes found');
        yield [];
        return;
      }

      final classIds = classesQuery.docs.map((doc) => doc.id).toList();

      debugPrint('Fetching notices for class IDs: $classIds');

      // 🔹 Split class IDs into chunks of 10 (Firestore's whereIn limit)
      final chunkSize = 10;
      final chunks = [];
      for (var i = 0; i < classIds.length; i += chunkSize) {
        chunks.add(classIds.sublist(i,
            i + chunkSize > classIds.length ? classIds.length : i + chunkSize));
      }

      // 🔹 Fetch notices for each chunk
      List<DocumentSnapshot> allNotices = [];
      for (final chunk in chunks) {
        var noticesQuery =
            _firestore.collection('notices').where('class_id', whereIn: chunk);

        // 🔹 Ensure date field exists before ordering
        var noticesSnapshot = await noticesQuery.limit(1).get();
        if (noticesSnapshot.docs.isNotEmpty &&
            noticesSnapshot.docs.first.data().containsKey('date')) {
          noticesQuery = noticesQuery.orderBy('date', descending: true);
        }

        final notices = await noticesQuery.limit(50).get();
        allNotices.addAll(notices.docs);
      }

      // 🔹 Sort all notices by date
      allNotices.sort((a, b) {
        final aDate = a['date'] as Timestamp;
        final bDate = b['date'] as Timestamp;
        return bDate.compareTo(aDate);
      });

      // 🔹 Yield the combined notices
      yield allNotices;
    } catch (e, stackTrace) {
      debugPrint('Error fetching notices: $e');
      debugPrint('Stack trace: $stackTrace');
      yield [];
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Date not available';

    try {
      DateTime dateTime;
      if (date is Timestamp) {
        dateTime = date.toDate();
      } else if (date is String) {
        dateTime = DateTime.parse(date);
      } else {
        return 'Invalid date format';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return 'Today ${DateFormat('h:mm a').format(dateTime)}';
      } else if (difference.inDays == 1) {
        return 'Yesterday ${DateFormat('h:mm a').format(dateTime)}';
      } else if (difference.inDays < 7) {
        return DateFormat('EEEE h:mm a').format(dateTime);
      } else {
        return DateFormat('MMMM d, y h:mm a').format(dateTime);
      }
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return 'Date error';
    }
  }

  Future<String> _getTeacherName(String teacherId) async {
    if (_teacherCache.containsKey(teacherId)) {
      return _teacherCache[teacherId]!;
    }

    try {
      final doc = await _firestore.collection('users').doc(teacherId).get();
      final name = doc.data()?['username'] ?? 'Unknown Teacher';
      _teacherCache[teacherId] = name;
      return name;
    } catch (e) {
      debugPrint('Error fetching teacher: $e');
      return 'Unknown Teacher';
    }
  }

  Future<String> _getSubject(String classId) async {
    if (_classCache.containsKey(classId)) {
      return _classCache[classId]!;
    }

    try {
      final doc = await _firestore.collection('classes').doc(classId).get();
      final subject = doc.data()?['subject'] ?? 'Unknown Subject';
      _classCache[classId] = subject;
      return subject;
    } catch (e) {
      debugPrint('Error fetching class: $e');
      return 'Unknown Subject';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notices',
          style: GoogleFonts.golosText(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _teacherCache.clear();
                _classCache.clear();
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: _getNoticesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('StreamBuilder error: ${snapshot.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading notices',
                      style: GoogleFonts.golosText(
                        fontSize: 18,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check your connection and try again',
                      style: GoogleFonts.golosText(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final notices = snapshot.data ?? [];

          if (notices.isEmpty) {
            return _buildNoNoticesWidget();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _teacherCache.clear();
                _classCache.clear();
              });
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notices.length,
              itemBuilder: (context, index) {
                final noticeData =
                    notices[index].data() as Map<String, dynamic>;

                return FutureBuilder<Map<String, String>>(
                  future: Future.wait([
                    _getTeacherName(noticeData['publishedBy']),
                    _getSubject(noticeData['class_id']),
                  ]).then((values) => {
                        'teacherName': values[0],
                        'subject': values[1],
                      }),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      );
                    }

                    return _buildNoticeCard(
                      title: snapshot.data!['subject']!,
                      description: noticeData['message'] ?? 'No Description',
                      date: _formatDate(noticeData['date']),
                      teacherName: snapshot.data!['teacherName']!,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoNoticesWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No notices found',
            style: GoogleFonts.golosText(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() {}),
            child: Text(
              'Refresh',
              style: GoogleFonts.golosText(
                fontSize: 16,
                color: Colors.blueAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard({
    required String title,
    required String description,
    required String date,
    required String teacherName,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.golosText(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      description,
                      style: GoogleFonts.golosText(
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Published by: $teacherName',
                      style: GoogleFonts.golosText(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      date,
                      style: GoogleFonts.golosText(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.golosText(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: GoogleFonts.golosText(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      teacherName,
                      style: GoogleFonts.golosText(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    date,
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
}
