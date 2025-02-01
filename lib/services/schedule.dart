import 'dart:developer';

import 'package:ams/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

addSchedule(
  String classId,
  String dayOfWeek, //sunday
  String startTime, //24hr format 16:00, 8:12, 15:15
  String endTime, //24hr format 16:00, 8:12, 15:15
) async {
  await firestore.collection("schedule").add({
    "class_id": classId,
    "day_of_week": dayOfWeek,
    "end_time": endTime,
    "start_time": startTime
  });
}

getScheduleForStudent() async {
  List schedules = [];
  List<String> myClasses = await getEnrolledClasses();
  for (String classId in myClasses) {
    QuerySnapshot schedules = await firestore
        .collection('schedule')
        .where("class_id", isEqualTo: classId)
        .get();
    for (var data in schedules.docs) {
      Object? scheduleJson = data.data();
      log("schedule: $scheduleJson");
    }
  }
}

Future<List<String>> getEnrolledClasses() async {
  List<String> enrolled = [];
  QuerySnapshot classes = await firestore.collection('classes').get();
  String my = auth.currentUser!.uid;
  log("classes: ${classes.docs}");
  for (QueryDocumentSnapshot classSnap in classes.docs) {
    var studentsInClass = classSnap.get("students");
    if (studentsInClass.contains(my)) {
      enrolled.add(classSnap.id);
    }
  }
  return enrolled;
}
